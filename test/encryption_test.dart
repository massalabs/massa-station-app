import 'package:flutter_test/flutter_test.dart';
import 'package:mug/utils/encryption/aes_encryption.dart';

void main() {
  group('AES Encryption Tests', () {
    test('encryptAES should return a non-empty string', () {
      final String plainText = 'Hello, World!';
      final String key = 'my32lengthsupersecretnooneknows1';

      final String encryptedText = encryptAES(plainText, key);

      expect(encryptedText, isNotEmpty);
    });

    test('decryptAES should return the original plain text', () {
      final String plainText = 'Hello, World!';
      final String key = 'my32lengthsupersecretnooneknows1';

      final String encryptedText = encryptAES(plainText, key);
      final String decryptedText = decryptAES(encryptedText, key);

      expect(decryptedText, equals(plainText));
    });

    test('decryptAES should return an empty string for incorrect key', () {
      final String plainText = 'Hello, World!';
      final String correctKey = 'my32lengthsupersecretnooneknows1';
      final String incorrectKey = 'wrong32lengthsupersecretnooneknows1';

      final String encryptedText = encryptAES(plainText, correctKey);
      final String decryptedText = decryptAES(encryptedText, incorrectKey);

      expect(decryptedText, isNot(plainText));
    });
  });
}
