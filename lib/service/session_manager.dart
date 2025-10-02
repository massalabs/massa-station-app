// Dart imports:
import 'dart:async';
import 'dart:typed_data';

/// SessionManager manages the master encryption key in RAM only.
/// The key is never persisted to disk and is cleared on timeout/logout.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Store PBKDF2-derived master key in RAM
  Uint8List? _masterKey;
  Timer? _lockTimer;
  Duration _timeout = const Duration(minutes: 5);

  /// Set master key after successful login
  /// The key will be automatically cleared after the specified timeout
  void setMasterKey(Uint8List key, {Duration timeout = const Duration(minutes: 5)}) {
    _masterKey = key;
    _timeout = timeout; // Store the timeout for reuse
    _resetLockTimer(timeout: timeout);
  }

  /// Get master key for encryption/decryption
  /// Resets the auto-lock timer on each access (keep-alive)
  Uint8List? get masterKey {
    if (_masterKey != null) {
      _resetLockTimer(timeout: _timeout); // Use stored timeout
    }
    return _masterKey;
  }

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
    _lockTimer?.cancel();
  }

  /// Reset auto-lock timer (called on key access to keep session alive)
  void _resetLockTimer({Duration timeout = const Duration(minutes: 5)}) {
    _lockTimer?.cancel();
    _lockTimer = Timer(timeout, endSession);
  }

  /// Manually keep session alive (call on user activity)
  void keepAlive({Duration timeout = const Duration(minutes: 5)}) {
    _resetLockTimer(timeout: timeout);
  }
}
