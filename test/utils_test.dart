import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/validator.dart';
import 'package:w_tools/src/utils/secret.dart';
import 'package:w_tools/src/utils/logger.dart';

void main() {
  group('WValidator Tests', () {
    test('isValidEmail should return true for valid email', () {
      expect(WValidator.isValidEmail('test@example.com'), true);
    });

    test('isValidEmail should return false for invalid email', () {
      expect(WValidator.isValidEmail('test@'), false);
      expect(WValidator.isValidEmail('test'), false);
      expect(WValidator.isValidEmail(''), false);
    });

    test('isValidPhone should return true for valid phone number', () {
      expect(WValidator.isValidPhone('13800138000'), true);
    });

    test('isValidPhone should return false for invalid phone number', () {
      expect(WValidator.isValidPhone('12345678901'), false);
      expect(WValidator.isValidPhone('1380013800'), false);
      expect(WValidator.isValidPhone(''), false);
    });

    test('isValidPassword should return true for strong password', () {
      expect(WValidator.isValidPassword('Password123'), true);
    });

    test('isValidPassword should return false for weak password', () {
      expect(WValidator.isValidPassword('password'), false);
      expect(WValidator.isValidPassword('PASSWORD'), false);
      expect(WValidator.isValidPassword('12345678'), false);
      expect(WValidator.isValidPassword('Pass123'), false);
    });

    test('preventSqlInjection should sanitize input', () {
      const input = "' OR 1=1; --";
      final sanitized = WValidator.preventSqlInjection(input);
      expect(sanitized, "'' OR 1=1 --");
    });

    test('preventXss should sanitize input', () {
      const input = '<script>alert("XSS")</script>';
      final sanitized = WValidator.preventXss(input);
      expect(sanitized, '');
    });
  });

  group('WSecret Tests', () {
    test('encryptAES and decryptAES should work correctly', () {
      final key = WSecret.generateSecureKey();
      const plainText = 'Hello, World!';
      final encrypted = WSecret.encryptAES(plainText, keyStr: key);
      final decrypted = WSecret.decryptAES(encrypted, keyStr: key);
      expect(decrypted, plainText);
    });

    test('generateSecureKey should return a valid key', () {
      final key = WSecret.generateSecureKey();
      expect(key, isNotEmpty);
    });

    test('hashPassword should return a hash', () {
      const password = 'Password123';
      final hash = WSecret.hashPassword(password);
      expect(hash, isNotEmpty);
    });
  });

  group('WLogger Tests', () {
    test('WLogger should log messages', () {
      // This is a simple test to ensure the logger methods don't throw exceptions
      expect(() => WLogger.d('Debug message'), returnsNormally);
      expect(() => WLogger.i('Info message'), returnsNormally);
      expect(() => WLogger.w('Warning message'), returnsNormally);
      expect(() => WLogger.e('Error message'), returnsNormally);
    });
  });
}
