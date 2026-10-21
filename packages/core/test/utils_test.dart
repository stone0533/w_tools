import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/validator.dart';
import 'package:w_tools_core/src/utils/logger.dart';

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

    test('isValidDate 校验真实日期范围', () {
      expect(WValidator.isValidDate('2024-02-29'), true); // 闰年
      expect(WValidator.isValidDate('2023-02-29'), false); // 非闰年
      expect(WValidator.isValidDate('2023-02-30'), false);
      expect(WValidator.isValidDate('2023-13-01'), false);
      expect(WValidator.isValidDate('2023-00-10'), false);
      expect(WValidator.isValidDate('2023-01-32'), false);
    });

    test('isValidDateTime 校验日期部分', () {
      expect(WValidator.isValidDateTime('2024-02-29 10:00:00'), true);
      expect(WValidator.isValidDateTime('2023-02-30 10:00:00'), false);
      expect(WValidator.isValidDateTime('2023-01-01 24:00:00'), false);
    });

    test('isValidChineseName / isValidPostalCode / isValidMacAddress', () {
      expect(WValidator.isValidChineseName('张三'), true);
      expect(WValidator.isValidChineseName('Zhang'), false);
      expect(WValidator.isValidPostalCode('100000'), true);
      expect(WValidator.isValidPostalCode('10000'), false);
      expect(WValidator.isValidMacAddress('00:1B:44:11:3A:B7'), true);
      expect(WValidator.isValidMacAddress('GG:1B:44:11:3A:B7'), false);
    });

    test('isValidPositiveInteger', () {
      expect(WValidator.isValidPositiveInteger('123'), true);
      expect(WValidator.isValidPositiveInteger('0'), false);
      expect(WValidator.isValidPositiveInteger('-1'), false);
    });

    test('isValidDecimal / isValidPositiveDecimal', () {
      expect(WValidator.isValidDecimal('123.45'), true);
      expect(WValidator.isValidDecimal('-123.45'), true);
      expect(WValidator.isValidDecimal('123'), false);
      expect(WValidator.isValidPositiveDecimal('123.45'), true);
      expect(WValidator.isValidPositiveDecimal('-123.45'), false);
      expect(WValidator.isValidPositiveDecimal('0.0'), false);
    });

    test('escapeSql should sanitize input', () {
      const input = "' OR 1=1; --";
      final sanitized = WValidator.escapeSql(input);
      expect(sanitized, "'' OR 1=1 --");
    });

    test('stripHtml should sanitize input', () {
      const input = '<script>alert("XSS")</script>';
      final sanitized = WValidator.stripHtml(input);
      expect(sanitized, '');
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
