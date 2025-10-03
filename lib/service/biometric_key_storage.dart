import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service for storing master encryption key with biometric protection
/// Uses platform-specific secure storage (iOS Keychain / Android Keystore)
class BiometricKeyStorage {
  static const _channel = MethodChannel('com.massa.station/biometric_storage');
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _biometricKeyStorageKey = 'biometric_master_key';
  static const String _biometricKeyHashKey = 'biometric_key_hash';

  BiometricKeyStorage({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is available (device has enrolled biometrics)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Store master key with biometric protection
  /// This encrypts the master key and stores it in secure storage
  /// biometricOnly: if true, no device credential fallback during enrollment
  Future<bool> storeBiometricKey(Uint8List masterKey, {bool biometricOnly = false}) async {
    try {
      // First authenticate with biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for quick login',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );

      if (!authenticated) {
        return false;
      }

      // Try platform-specific secure storage first (more secure)
      try {
        final result = await _channel.invokeMethod<bool>(
          'storeBiometricKey',
          {'key': base64.encode(masterKey)},
        );

        if (result == true) {
          // Also store a hash for verification
          final hash = sha256.convert(masterKey).bytes;
          await _secureStorage.write(
            key: _biometricKeyHashKey,
            value: base64.encode(hash),
          );
          return true;
        }
      } on MissingPluginException {
        // Platform channel not implemented, fall back to flutter_secure_storage
        print('Platform-specific biometric storage not available, using fallback');
      } on PlatformException catch (e) {
        print('Platform biometric storage error: ${e.message}');
      }

      // Fallback: Use flutter_secure_storage
      // Note: This is less secure but works cross-platform
      await _secureStorage.write(
        key: _biometricKeyStorageKey,
        value: base64.encode(masterKey),
      );

      // Store hash for verification
      final hash = sha256.convert(masterKey).bytes;
      await _secureStorage.write(
        key: _biometricKeyHashKey,
        value: base64.encode(hash),
      );

      return true;
    } catch (e) {
      print('Error storing biometric key: $e');
      return false;
    }
  }

  /// Retrieve master key with biometric authentication
  /// biometricOnly: if true, no device credential fallback (for passphrase mode)
  ///                if false, allow device PIN fallback (for biometric-only mode)
  Future<Uint8List?> retrieveBiometricKey({String? reason, bool biometricOnly = false}) async {
    try {
      // Authenticate with biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Login using your biometric credential',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );

      if (!authenticated) {
        return null;
      }

      // Try platform-specific secure storage first
      try {
        final result = await _channel.invokeMethod<String>('retrieveBiometricKey');
        if (result != null) {
          final masterKey = base64.decode(result);

          // Verify hash if available
          final storedHash = await _secureStorage.read(key: _biometricKeyHashKey);
          if (storedHash != null) {
            final computedHash = sha256.convert(masterKey).bytes;
            if (base64.encode(computedHash) != storedHash) {
              print('Biometric key hash mismatch');
              return null;
            }
          }

          return Uint8List.fromList(masterKey);
        }
      } on MissingPluginException {
        // Fall through to fallback
      } on PlatformException catch (e) {
        print('Platform biometric retrieval error: ${e.message}');
      }

      // Fallback: Use flutter_secure_storage
      final keyB64 = await _secureStorage.read(key: _biometricKeyStorageKey);
      if (keyB64 == null) {
        return null;
      }

      final masterKey = base64.decode(keyB64);

      // Verify hash
      final storedHash = await _secureStorage.read(key: _biometricKeyHashKey);
      if (storedHash != null) {
        final computedHash = sha256.convert(masterKey).bytes;
        if (base64.encode(computedHash) != storedHash) {
          print('Biometric key hash mismatch');
          return null;
        }
      }

      return Uint8List.fromList(masterKey);
    } catch (e) {
      print('Error retrieving biometric key: $e');
      return null;
    }
  }

  /// Delete stored biometric key
  Future<bool> deleteBiometricKey() async {
    try {
      // Try platform-specific deletion first
      try {
        await _channel.invokeMethod('deleteBiometricKey');
      } on MissingPluginException {
        // Fall through to fallback
      } on PlatformException catch (e) {
        print('Platform biometric deletion error: ${e.message}');
      }

      // Also delete from flutter_secure_storage (fallback)
      await _secureStorage.delete(key: _biometricKeyStorageKey);
      await _secureStorage.delete(key: _biometricKeyHashKey);

      return true;
    } catch (e) {
      print('Error deleting biometric key: $e');
      return false;
    }
  }

  /// Check if biometric key exists
  Future<bool> hasBiometricKey() async {
    try {
      // Try platform-specific check first
      try {
        final result = await _channel.invokeMethod<bool>('hasBiometricKey');
        if (result == true) {
          return true;
        }
      } on MissingPluginException {
        // Fall through to fallback
      } on PlatformException catch (e) {
        print('Platform biometric check error: ${e.message}');
      }

      // Fallback: Check flutter_secure_storage
      final keyExists = await _secureStorage.read(key: _biometricKeyStorageKey);
      final hashExists = await _secureStorage.read(key: _biometricKeyHashKey);

      return keyExists != null && hashExists != null;
    } catch (e) {
      print('Error checking biometric key: $e');
      return false;
    }
  }
}
