// Dart imports:
import 'dart:typed_data';

/// SessionManager manages the master encryption key in RAM only.
/// The key is never persisted to disk and is cleared on logout.
/// Timeout is handled by local_session_timeout package in mug.dart.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Store PBKDF2-derived master key in RAM
  Uint8List? _masterKey;

  /// Set master key after successful login
  void setMasterKey(Uint8List key) {
    _masterKey = key;
  }

  /// Get master key for encryption/decryption
  Uint8List? get masterKey => _masterKey;

  /// Check if session is active
  bool get isActive => _masterKey != null;

  /// Clear master key from RAM
  /// Overwrites the key with zeros before clearing for security
  void endSession() {
    if (_masterKey != null) {
      // Overwrite with zeros before clearing
      for (int i = 0; i < _masterKey!.length; i++) {
        _masterKey![i] = 0;
      }
      _masterKey = null;
    }
  }
}
