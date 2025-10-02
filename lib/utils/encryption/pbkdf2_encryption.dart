// Dart imports:
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';

// Parameters for PBKDF2 isolate
class _Pbkdf2Params {
  final String passphrase;
  final Uint8List salt;
  final SendPort sendPort;

  _Pbkdf2Params(this.passphrase, this.salt, this.sendPort);
}

// Isolate entry point for PBKDF2
void _pbkdf2Isolate(_Pbkdf2Params params) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  derivator.init(Pbkdf2Parameters(params.salt, 100000, 32));
  final result = derivator.process(utf8.encode(params.passphrase));
  params.sendPort.send(result);
}

// Derive master key from passphrase using PBKDF2 in background isolate (expensive - do once at login)
Future<Uint8List> deriveMasterKeyFromPassphrase(String passphrase, Uint8List salt) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_pbkdf2Isolate, _Pbkdf2Params(passphrase, salt, receivePort.sendPort));
  final result = await receivePort.first as Uint8List;
  return result;
}

// Derive AES key + IV from master key + per-wallet salt using PBKDF2 (fast - 1 iteration)
(Uint8List, Uint8List) deriveKeyAndIVFromMaster(Uint8List masterKey, Uint8List salt) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  derivator.init(Pbkdf2Parameters(salt, 1, 48)); // 1 iteration, 48 bytes (32 key + 16 IV)

  final derived = derivator.process(masterKey);

  return (
    derived.sublist(0, 32),  // AES-256 key
    derived.sublist(32, 48)  // IV
  );
}

// Encrypt using master key (no passphrase needed)
String encryptWithMasterKey(String plainText, Uint8List masterKey) {
  final salt = generateRandomNonZero(16);
  final (key, iv) = deriveKeyAndIVFromMaster(masterKey, salt);

  final encrypter = encrypt.Encrypter(
    encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc, padding: "PKCS7")
  );
  final encrypted = encrypter.encrypt(plainText, iv: encrypt.IV(iv));

  // Format: [salt(16)] + [ciphertext]
  final output = Uint8List.fromList(salt + encrypted.bytes);
  return base64.encode(output);
}

// Decrypt using master key (no passphrase needed)
String decryptWithMasterKey(String encryptedB64, Uint8List masterKey) {
  final data = base64.decode(encryptedB64);

  final salt = data.sublist(0, 16);
  final ciphertext = data.sublist(16);
  final (key, iv) = deriveKeyAndIVFromMaster(masterKey, salt);

  final encrypter = encrypt.Encrypter(
    encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc, padding: "PKCS7")
  );
  return encrypter.decrypt64(base64.encode(ciphertext), iv: encrypt.IV(iv));
}

// Generate cryptographically secure random bytes (non-zero)
Uint8List generateRandomNonZero(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = random.nextInt(255) + 1; // 1-255 (avoid 0)
  }
  return bytes;
}
