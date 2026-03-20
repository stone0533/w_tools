import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/values/reg_exp.dart';

void main() {
  group('WRegExp', () {
    // 测试个人信息相关验证
    group('Personal Information Validation', () {
      test('validatePassword should return true for valid password', () {
        expect(WRegExp.validatePassword('Password123'), isTrue);
        expect(WRegExp.validatePassword('pass1234'), isTrue);
      });

      test('validatePassword should return false for invalid password', () {
        expect(WRegExp.validatePassword('password'), isFalse); // 无数字
        expect(WRegExp.validatePassword('1234567'), isFalse); // 无字母
        expect(WRegExp.validatePassword('Pass123'), isFalse); // 长度不足
      });

      test('validateEmail should return true for valid email', () {
        expect(WRegExp.validateEmail('test@example.com'), isTrue);
        expect(WRegExp.validateEmail('user.name+tag@domain.co.uk'), isTrue);
      });

      test('validateEmail should return false for invalid email', () {
        expect(WRegExp.validateEmail('test@'), isFalse);
        expect(WRegExp.validateEmail('test@.com'), isFalse);
        expect(WRegExp.validateEmail('test.com'), isFalse);
      });

      test('validatePhone should return true for valid phone', () {
        expect(WRegExp.validatePhone('13812345678'), isTrue);
        expect(WRegExp.validatePhone('15987654321'), isTrue);
      });

      test('validatePhone should return false for invalid phone', () {
        expect(WRegExp.validatePhone('12345678901'), isFalse); // 开头不是 13-19
        expect(WRegExp.validatePhone('1381234567'), isFalse); // 长度不足
        expect(WRegExp.validatePhone('138123456789'), isFalse); // 长度过长
      });

      test('validateIdCard should return true for valid ID card', () {
        expect(WRegExp.validateIdCard('110101199001011234'), isTrue);
        expect(WRegExp.validateIdCard('11010119900101123X'), isTrue);
      });

      test('validateIdCard should return false for invalid ID card', () {
        expect(WRegExp.validateIdCard('11010119900101123'), isFalse); // 长度不足
        expect(WRegExp.validateIdCard('1101011990010112345'), isFalse); // 长度过长
      });

      test('validateChineseName should return true for valid Chinese name', () {
        expect(WRegExp.validateChineseName('张三'), isTrue);
        expect(WRegExp.validateChineseName('张三丰'), isTrue);
      });

      test('validateChineseName should return false for invalid Chinese name', () {
        expect(WRegExp.validateChineseName('张'), isFalse); // 长度不足
        expect(WRegExp.validateChineseName('Zhang'), isFalse); // 非中文
      });
    });

    // 测试网络相关验证
    group('Network Validation', () {
      test('validateUrl should return true for valid URL', () {
        expect(WRegExp.validateUrl('https://www.example.com'), isTrue);
        expect(WRegExp.validateUrl('http://example.com/path'), isTrue);
      });

      test('validateUrl should return false for invalid URL', () {
        expect(WRegExp.validateUrl('example.com'), isFalse); // 无协议
        expect(WRegExp.validateUrl('http://'), isFalse); // 无域名
      });

      test('validateIpV4 should return true for valid IP address', () {
        expect(WRegExp.validateIpV4('192.168.1.1'), isTrue);
        expect(WRegExp.validateIpV4('255.255.255.255'), isTrue);
      });

      test('validateIpV4 should return false for invalid IP address', () {
        expect(WRegExp.validateIpV4('256.168.1.1'), isFalse); // 超出范围
        expect(WRegExp.validateIpV4('192.168.1'), isFalse); // 长度不足
      });

      test('validateMacAddress should return true for valid MAC address', () {
        expect(WRegExp.validateMacAddress('00:1B:44:11:3A:B7'), isTrue);
        expect(WRegExp.validateMacAddress('00-1B-44-11-3A-B7'), isTrue);
      });

      test('validateMacAddress should return false for invalid MAC address', () {
        expect(WRegExp.validateMacAddress('00:1B:44:11:3A'), isFalse); // 长度不足
        expect(WRegExp.validateMacAddress('GG:1B:44:11:3A:B7'), isFalse); // 无效字符
      });
    });

    // 测试数字相关验证
    group('Number Validation', () {
      test('validateNumber should return true for valid number', () {
        expect(WRegExp.validateNumber('123'), isTrue);
        expect(WRegExp.validateNumber('-123'), isTrue);
        expect(WRegExp.validateNumber('123.45'), isTrue);
        expect(WRegExp.validateNumber('-123.45'), isTrue);
      });

      test('validateNumber should return false for invalid number', () {
        expect(WRegExp.validateNumber('abc'), isFalse);
        expect(WRegExp.validateNumber('123abc'), isFalse);
      });

      test('validateInteger should return true for valid integer', () {
        expect(WRegExp.validateInteger('123'), isTrue);
        expect(WRegExp.validateInteger('-123'), isTrue);
      });

      test('validateInteger should return false for invalid integer', () {
        expect(WRegExp.validateInteger('123.45'), isFalse);
        expect(WRegExp.validateInteger('abc'), isFalse);
      });

      test('validatePositiveNumber should return true for valid positive number', () {
        expect(WRegExp.validatePositiveNumber('123'), isTrue);
        expect(WRegExp.validatePositiveNumber('123.45'), isTrue);
      });

      test('validatePositiveNumber should return false for invalid positive number', () {
        expect(WRegExp.validatePositiveNumber('-123'), isFalse);
        expect(WRegExp.validatePositiveNumber('abc'), isFalse);
      });

      test('validatePositiveInteger should return true for valid positive integer', () {
        expect(WRegExp.validatePositiveInteger('123'), isTrue);
      });

      test('validatePositiveInteger should return false for invalid positive integer', () {
        expect(WRegExp.validatePositiveInteger('-123'), isFalse);
        expect(WRegExp.validatePositiveInteger('123.45'), isFalse);
      });

      test('validateDecimal should return true for valid decimal', () {
        expect(WRegExp.validateDecimal('123.45'), isTrue);
        expect(WRegExp.validateDecimal('-123.45'), isTrue);
      });

      test('validateDecimal should return false for invalid decimal', () {
        expect(WRegExp.validateDecimal('123'), isFalse);
        expect(WRegExp.validateDecimal('abc'), isFalse);
      });

      test('validatePositiveDecimal should return true for valid positive decimal', () {
        expect(WRegExp.validatePositiveDecimal('123.45'), isTrue);
      });

      test('validatePositiveDecimal should return false for invalid positive decimal', () {
        expect(WRegExp.validatePositiveDecimal('-123.45'), isFalse);
        expect(WRegExp.validatePositiveDecimal('123'), isFalse);
      });
    });

    // 测试其他验证
    group('Other Validation', () {
      test('validateDate should return true for valid date', () {
        expect(WRegExp.validateDate('2023-01-01'), isTrue);
        expect(WRegExp.validateDate('2023-12-31'), isTrue);
      });

      test('validateDate should return false for invalid date', () {
        expect(WRegExp.validateDate('2023/01/01'), isFalse); // 格式错误
      });

      test('validateBankCard should return true for valid bank card', () {
        expect(WRegExp.validateBankCard('1234567890123456'), isTrue); // 16位
        expect(WRegExp.validateBankCard('1234567890123456789'), isTrue); // 19位
      });

      test('validateBankCard should return false for invalid bank card', () {
        expect(WRegExp.validateBankCard('123456789012345'), isFalse); // 15位
        expect(WRegExp.validateBankCard('12345678901234567890'), isFalse); // 20位
      });

      test('validatePostalCode should return true for valid postal code', () {
        expect(WRegExp.validatePostalCode('100000'), isTrue);
        expect(WRegExp.validatePostalCode('999999'), isTrue);
      });

      test('validatePostalCode should return false for invalid postal code', () {
        expect(WRegExp.validatePostalCode('10000'), isFalse); // 5位
        expect(WRegExp.validatePostalCode('1000000'), isFalse); // 7位
      });
    });

    // 测试提取方法
    group('Extraction Methods', () {
      test('extractBirthdayFromIdCard should return correct birthday', () {
        expect(WRegExp.extractBirthdayFromIdCard('110101199001011234'), '1990-01-01');
        expect(WRegExp.extractBirthdayFromIdCard('110101200012311234'), '2000-12-31');
      });

      test('extractBirthdayFromIdCard should return null for invalid ID card', () {
        expect(WRegExp.extractBirthdayFromIdCard('123456'), isNull);
        expect(WRegExp.extractBirthdayFromIdCard('invalid'), isNull);
      });

      test('extractGenderFromIdCard should return correct gender', () {
        expect(WRegExp.extractGenderFromIdCard('110101199001011234'), '男'); // 第17位是3（奇数）
        expect(WRegExp.extractGenderFromIdCard('110101199001011246'), '女'); // 第17位是4（偶数）
      });

      test('extractGenderFromIdCard should return null for invalid ID card', () {
        expect(WRegExp.extractGenderFromIdCard('123456'), isNull);
        expect(WRegExp.extractGenderFromIdCard('invalid'), isNull);
      });
    });

    // 测试掩码处理方法
    group('Masking Methods', () {
      test('maskPhone should return masked phone number', () {
        expect(WRegExp.maskPhone('13812345678'), '138****5678');
      });

      test('maskPhone should return original for invalid phone', () {
        expect(WRegExp.maskPhone('123456'), '123456');
      });

      test('maskBankCard should return masked bank card number', () {
        expect(WRegExp.maskBankCard('1234567890123456'), '1234********3456');
        expect(WRegExp.maskBankCard('1234567890123456789'), '1234***********6789');
      });

      test('maskBankCard should return original for short bank card', () {
        expect(WRegExp.maskBankCard('12345678'), '12345678');
      });

      test('maskBankCard should return original for invalid bank card', () {
        expect(WRegExp.maskBankCard('123456'), '123456');
      });
    });

    // 测试格式化方法
    group('Formatting Methods', () {
      test('formatPhone should return formatted phone number', () {
        expect(WRegExp.formatPhone('13812345678'), '138-1234-5678');
      });

      test('formatPhone should return original for invalid phone', () {
        expect(WRegExp.formatPhone('123456'), '123456');
      });

      test('formatDate should return formatted date', () {
        expect(WRegExp.formatDate('19900101'), '1990-01-01');
        expect(WRegExp.formatDate('20001231'), '2000-12-31');
      });

      test('formatDate should return null for invalid date', () {
        expect(WRegExp.formatDate('199001'), isNull);
        expect(WRegExp.formatDate('invalid'), isNull);
      });
    });
  });

  // 测试 String 扩展方法
  group('WRegExpStringExtension', () {
    test('String extensions for validation should work correctly', () {
      expect('Password123'.isPasswordValid, isTrue);
      expect('test@example.com'.isEmailValid, isTrue);
      expect('13812345678'.isPhoneValid, isTrue);
      expect('110101199001011234'.isIdCardValid, isTrue);
      expect('https://www.example.com'.isUrlValid, isTrue);
      expect('2023-01-01'.isDateValid, isTrue);
      expect('1234567890123456'.isBankCardValid, isTrue);
      expect('100000'.isPostalCodeValid, isTrue);
      expect('192.168.1.1'.isIpV4Valid, isTrue);
      expect('00:1B:44:11:3A:B7'.isMacAddressValid, isTrue);
      expect('张三'.isChineseNameValid, isTrue);
      expect('123'.isNumberValid, isTrue);
      expect('123'.isIntegerValid, isTrue);
      expect('123'.isPositiveNumberValid, isTrue);
      expect('123'.isPositiveIntegerValid, isTrue);
      expect('123.45'.isDecimalValid, isTrue);
      expect('123.45'.isPositiveDecimalValid, isTrue);
    });

    test('String extensions for extraction should work correctly', () {
      expect('110101199001011234'.birthdayFromIdCard, '1990-01-01');
      expect('110101199001011234'.genderFromIdCard, '男');
    });

    test('String extensions for masking should work correctly', () {
      expect('13812345678'.maskedPhone, '138****5678');
      expect('1234567890123456'.maskedBankCard, '1234********3456');
    });

    test('String extensions for formatting should work correctly', () {
      expect('13812345678'.formattedPhone, '138-1234-5678');
      expect('19900101'.formattedDate, '1990-01-01');
    });
  });
}
