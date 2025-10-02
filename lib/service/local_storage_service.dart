import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/service/session_manager.dart';
import 'package:mug/utils/encryption/pbkdf2_encryption.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const passphraseHash = 'passphrasehash';
  static const isThemeDark = 'isthemedark';
  static const keyboardIncognito = 'keyboardIcognito';
  static const isInactivityTimeoutOn = 'isInactivityTimeoutOn';
  static const inactivityTimeout = 'inactivityTimeout';
  static const focusTimeout = 'focusTimeout';
  static const preInactivityLogoutCounter = 'preInactivityLogoutCounter';
  static const noOfLogginAttemptAllowed = 'noOfLogginAttemptAllowed';
  static const bruteforceLockOutTime = 'bruteforceLockOutTime';
  static const isNewFirst = 'isNewFirst';
  static const isFlagSecure = 'isFlagSecure';
  static const maxBackupRetryAttempts = 'maxBackupRetryAttempts';
  static const isBiometricAuthEnabled = 'isBiometricAuthEnabled';
  static const biometricAttemptAllTimeCount = 'biometricAttemptAllTimeCount';
  static const isAutoRotate = 'isAutoRotate';
  //massa network based
  static const minimumGassFee = 'minimum-gass-fee';
  static const minimumFee = 'minimum-fee';
  static const slippageAmount = 'slippage-amount'; //slippage in percentage
  static const minimumTransferAmount = 'minimum-transfer-amount';
  static const isMainnet = 'is-mainnet';
  static const wallets = 'secure-wallets';
  static const defaultWalletAddress = 'default-wallet-address';
}

class LocalStorageService {
  bool _isUserActive = false;
  final SharedPreferences sharedPreferences;
  late FlutterSecureStorage _secureStorage;
  LocalStorageService({required this.sharedPreferences}) {
    const androidOptions = AndroidOptions(encryptedSharedPreferences: true);
    const iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
    _secureStorage = const FlutterSecureStorage(aOptions: androidOptions, iOptions: iosOptions);
  }

  bool get isFlagSecure => sharedPreferences.getBool(StorageKeys.isFlagSecure) ?? true;

  /// Set passphrase verification (one-time setup)
  /// Stores master key salt and verification hash, then caches master key in RAM
  Future<void> setPassphraseVerification(String passphrase) async {
    // Generate master key salt (stored, used to derive master key from passphrase)
    final masterSalt = generateRandomNonZero(32);
    await setSecureString('master_key_salt', base64.encode(masterSalt));

    // Derive master key (runs in isolate - won't block UI)
    final masterKey = await deriveMasterKeyFromPassphrase(passphrase, masterSalt);

    // Hash the master key for verification (fast - just SHA-256)
    final verifyHash = sha256.convert(masterKey).bytes;
    await setSecureString('passphrase_verify_hash', base64.encode(verifyHash));

    // Cache master key in RAM for immediate use
    SessionManager().setMasterKey(masterKey, timeout: Duration(seconds: inactivityTimeout));
  }

  /// Verify passphrase and cache master key in RAM
  /// Returns true if passphrase is correct and master key is cached
  Future<bool> verifyAndCacheMasterKey(String passphrase) async {
    // Get stored verification hash
    final hashB64 = await getSecureString('passphrase_verify_hash');
    final masterSaltB64 = await getSecureString('master_key_salt');

    if (hashB64 == null || masterSaltB64 == null) return false;

    final storedHash = base64.decode(hashB64);
    final masterSalt = base64.decode(masterSaltB64);

    // Derive master key from passphrase (runs in isolate - won't block UI)
    final masterKey = await deriveMasterKeyFromPassphrase(passphrase, masterSalt);

    // Verify by comparing hash of derived master key
    final computedHash = sha256.convert(masterKey).bytes;
    if (!_constantTimeEquals(storedHash, Uint8List.fromList(computedHash))) {
      return false;
    }

    // Passphrase correct - cache master key in RAM
    SessionManager().setMasterKey(masterKey, timeout: Duration(seconds: inactivityTimeout));

    return true;
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  void setLoginStatus(bool status) => _isUserActive = status;
  bool get isUserActive => _isUserActive;

  bool get isThemeDark => sharedPreferences.getBool(StorageKeys.isThemeDark) ?? true;

  Future<void> setIsThemeDark(bool flag) async => await sharedPreferences.setBool(StorageKeys.isThemeDark, flag);

  Future<void> setIsFlagSecure(bool flag) async => await sharedPreferences.setBool(StorageKeys.isFlagSecure, flag);

  bool get isNewFirst => sharedPreferences.getBool(StorageKeys.isNewFirst) ?? true;

  Future<void> setIsNewFirst(bool flag) async => await sharedPreferences.setBool(StorageKeys.isNewFirst, flag);

  Future<void> setKeyboardIncognito(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.keyboardIncognito, flag);

  bool get keyboardIncognito => sharedPreferences.getBool(StorageKeys.keyboardIncognito) ?? true;

  int get noOfLogginAttemptAllowed {
    //default: 3 unsuccessful
    return sharedPreferences.getInt(StorageKeys.noOfLogginAttemptAllowed) ?? 4;
  }

  int get bruteforceLockOutTime {
    //default: 30 seconds
    return sharedPreferences.getInt(StorageKeys.bruteforceLockOutTime) ?? 30;
  }

  bool get isInactivityTimeoutOn => sharedPreferences.getBool(StorageKeys.isInactivityTimeoutOn) ?? true;

  Future<void> setIsInactivityTimeoutOn(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.isInactivityTimeoutOn, flag);

  int get inactivityTimeout {
    //default: 5 minutes
    List<int> choices = [30, 60, 120, 180, 300, 600, 900];
    var index = sharedPreferences.getInt(StorageKeys.inactivityTimeout);
    if (!(index != null && index >= 0 && index < choices.length)) {
      index = 4; // default (300 seconds = 5 minutes)
    }
    return choices[index];
  }

  int get inactivityTimeoutIndex => sharedPreferences.getInt(StorageKeys.inactivityTimeout) ?? 3;

  Future<void> setInactivityTimeoutIndex({required int index}) async =>
      await sharedPreferences.setInt(StorageKeys.inactivityTimeout, index);

  int get focusTimeout => inactivityTimeout;

  //for logout popup alert. default: 15 seconds
  int get preInactivityLogoutCounter => sharedPreferences.getInt(StorageKeys.preInactivityLogoutCounter) ?? 15;

  bool get isBiometricAuthEnabled => sharedPreferences.getBool(StorageKeys.isBiometricAuthEnabled) ?? false;
  Future<void> setIsBiometricAuthEnabled(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.isBiometricAuthEnabled, flag);

  int get biometricAttemptAllTimeCount => sharedPreferences.getInt(StorageKeys.biometricAttemptAllTimeCount) ?? 0;

  Future<void> incrementBiometricAttemptAllTimeCount() async =>
      await sharedPreferences.setInt(StorageKeys.biometricAttemptAllTimeCount, biometricAttemptAllTimeCount + 1);

  bool get isAutoRotate => sharedPreferences.getBool(StorageKeys.isAutoRotate) ?? false;

  Future<void> setIsAutoRotate(bool flag) async => await sharedPreferences.setBool(StorageKeys.isAutoRotate, flag);

  /// Clears all app data - use when user forgets passphrase
  Future<void> clearAllData() async {
    // Clear session first
    SessionManager().endSession();
    await sharedPreferences.clear();
    await _secureStorage.deleteAll();
    _isUserActive = false;
  }

  Future<double> setMinimumGassFee(double minimumGassFee) async {
    if (minimumGassFee < 1.0) {
      minimumGassFee = 1.0;
    }
    sharedPreferences.setDouble(StorageKeys.minimumGassFee, minimumGassFee);
    return minimumGassFee;
  }

  double get minimumGassFee =>
      sharedPreferences.getDouble(StorageKeys.minimumGassFee) ?? 0.01 * 100; //default: 0.01 * 100 = 1.0

  Future<double> setMinimumFee(double minimumFee) async {
    if (minimumFee < 0.01 || minimumFee > 1.0) {
      minimumFee = 0.01;
    }
    sharedPreferences.setDouble(StorageKeys.minimumFee, minimumFee);
    return minimumFee;
  }

  double get minimumFee => sharedPreferences.getDouble(StorageKeys.minimumFee) ?? 0.01; //default: 0.01

  Future<void> setSlipage(double slippage) async => sharedPreferences.setDouble(StorageKeys.slippageAmount, slippage);
  double get slippage => sharedPreferences.getDouble(StorageKeys.slippageAmount) ?? 0.5;

  Future<void> setMinimumTransferAmount(double minimumTransferAmount) async =>
      sharedPreferences.setDouble(StorageKeys.minimumTransferAmount, minimumTransferAmount);
  double get minimumTransferAmount => sharedPreferences.getDouble(StorageKeys.minimumTransferAmount) ?? 0.0;

  Future<void> setNetworkType(bool isMainnet) async => sharedPreferences.setBool(StorageKeys.isMainnet, isMainnet);
  bool get isMainnet => sharedPreferences.getBool(StorageKeys.isMainnet) ?? true;

  Future<void> storeWallets(String encodedWallets) async {
    await setSecureString(StorageKeys.wallets, encodedWallets);
  }

  Future<String> getStoredWallets() async {
    return await getSecureString(StorageKeys.wallets) ?? "";
  }

  /// Get wallet private key (decrypt on-demand using cached master key)
  Future<String?> getWalletKey(String address) async {
    final masterKey = SessionManager().masterKey;
    if (masterKey == null) {
      throw Exception('Session expired - please login again');
    }

    final walletString = await getStoredWallets();
    if (walletString.isEmpty) return null;

    final wallets = WalletModel.decode(walletString);
    for (var wallet in wallets) {
      if (wallet.address == address) {
        // Decrypt using cached master key (fast!)
        return decryptWithMasterKey(wallet.encryptedKey, masterKey);
      }
    }
    return null;
  }

  Future<void> setDefaultWallet(String address) async {
    return await _secureStorage.write(key: StorageKeys.defaultWalletAddress, value: address);
  }

  Future<String?> getDefaultWallet() async {
    return await _secureStorage.read(key: StorageKeys.defaultWalletAddress);
  }

  Future<String?> getDefaultWalletKey() async {
    final address = await _secureStorage.read(key: StorageKeys.defaultWalletAddress);
    if (address == null) {
      return null;
    }
    return await getWalletKey(address);
  }

  //supporting functions
  //write methods
  Future<void> setSecureBool(String key, bool value) async =>
      await _secureStorage.write(key: key, value: value.toString());
  Future<void> setSecureNum(String key, num value) async =>
      await _secureStorage.write(key: key, value: value.toString());
  Future<void> setSecureString(String key, String value) async => await _secureStorage.write(key: key, value: value);
  Future<void> setSecureBoolList(String key, List<bool> value) async => await _setSecureList<bool>(key, value);
  Future<void> setSecureNumList(String key, List<num> value) async => await _setSecureList<num>(key, value);
  Future<void> setSecureStringList(String key, List<String> value) async => await _setSecureList<String>(key, value);
  Future<void> _setSecureList<T>(String key, List<T> value) async {
    String buffer = json.encode(value);
    return await _secureStorage.write(key: key, value: buffer);
  }

  //read methods
  Future<Set<String>?> getKeys() async => (await _secureStorage.readAll()).keys.toSet();

  Future<bool?> getBool(String key) async {
    String? value = await _secureStorage.read(key: key);
    final result = switch (value) { 'true' => true, 'false' => false, _ => null };
    return result;
  }

  Future<num?> getNum(String key) async {
    String? value = await _secureStorage.read(key: key);
    final result = num.tryParse(value ?? '');
    return result;
  }

  Future<String?> getSecureString(String key) async => await _secureStorage.read(key: key);

  Future<List<bool>?> getBoolList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);

    List<bool> result = decodedValue.map((i) {
      return switch (i) { 'true' => true, _ => false };
    }).toList();
    return result;
  }

  Future<List<num>?> getNumList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);

    List<num> result = decodedValue.map((i) {
      return num.tryParse(i ?? '');
    }).toList();
    return result;
  }

  Future<List<String>?> getStringList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);
    List<String> result = decodedValue.map((i) {
      return i;
    }).toList();
    return result;
  }

  Future<void> delete(String key) async {
    return _secureStorage.delete(key: key);
  }
}

class AsyncInit {
  final Ref ref;
  late final SharedPreferences sharedPreferences;

  AsyncInit({required this.ref});

//put here all functions to be initialised before we start using the provider
  Future<void> init() async {
    await Future.wait([
      SharedPreferences.getInstance().then((value) {
        sharedPreferences = value;
      }),
    ]);
  }
}
