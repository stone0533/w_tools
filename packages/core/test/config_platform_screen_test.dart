// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  group('WToken 键名', () {
    test('默认值正确', () {
      expect(WToken.tokenKey, 'token');
      expect(WToken.refreshTokenKey, 'refresh_token');
      expect(WToken.tokenExpiryKey, 'token_expiry');
    });

    test('可赋值修改', () {
      final oldTokenKey = WToken.tokenKey;
      WToken.tokenKey = 'my_custom_token';
      expect(WToken.tokenKey, 'my_custom_token');
      WToken.tokenKey = oldTokenKey;
    });
  });

  group('WPlatform', () {
    test('isMobile / isWeb / isDesktop 返回 bool', () {
      expect(WPlatform.isMobile, isA<bool>());
      expect(WPlatform.isWeb, isA<bool>());
      expect(WPlatform.isDesktop, isA<bool>());
    });

    test('platformType 是合法枚举值', () {
      expect(WPlatform.platformType, isA<WPlatformType>());
    });

    test('平台 getter 全部存在且为 bool', () {
      expect(WPlatform.isAndroid, isA<bool>());
      expect(WPlatform.isIOS, isA<bool>());
      expect(WPlatform.isLinux, isA<bool>());
      expect(WPlatform.isMacOS, isA<bool>());
      expect(WPlatform.isWindows, isA<bool>());
    });

    test('包含 fuchsia 平台类型', () {
      expect(WPlatformType.values, contains(WPlatformType.fuchsia));
    });
  });

  group('WValidator', () {
    test('isValidEmail', () {
      expect(WValidator.isValidEmail('test@example.com'), true);
      expect(WValidator.isValidEmail('invalid'), false);
      expect(WValidator.isValidEmail(''), false);
    });

    test('isValidPhone', () {
      expect(WValidator.isValidPhone('13800138000'), true);
      expect(WValidator.isValidPhone('12345'), false);
      expect(WValidator.isValidPhone(''), false);
    });

    test('isValidUrl', () {
      expect(WValidator.isValidUrl('https://example.com'), true);
      expect(WValidator.isValidUrl('http://example.com/path?q=1'), true);
      expect(WValidator.isValidUrl('not_a_url'), false);
      expect(WValidator.isValidUrl('https://'), false);
      expect(WValidator.isValidUrl('https://?q=1'), false);
    });

    test('isValidIpv4', () {
      expect(WValidator.isValidIpv4('192.168.1.1'), true);
      expect(WValidator.isValidIpv4('256.1.1.1'), false);
    });

    test('isValidPassword', () {
      // 规则: 至少 8 位，包含大小写字母和数字
      expect(WValidator.isValidPassword('Abc12345'), true);
      expect(WValidator.isValidPassword('short'), false);
      expect(WValidator.isValidPassword('12345678'), false);
      expect(WValidator.isValidPassword('abcdefgh'), false); // 缺大写
    });

    test('isNumeric / isInteger / isPositive', () {
      expect(WValidator.isNumeric('123.45'), true);
      expect(WValidator.isNumeric('1e3'), true);
      expect(WValidator.isNumeric('abc'), false);
      expect(WValidator.isNumeric('NaN'), false);
      expect(WValidator.isNumeric('Infinity'), false);
      expect(WValidator.isInteger('42'), true);
      expect(WValidator.isInteger('3.14'), false);
      expect(WValidator.isPositive('10'), true);
      expect(WValidator.isPositive('0'), false);
      expect(WValidator.isPositive('-1'), false);
      expect(WValidator.isPositive('Infinity'), false);
    });

    test('isValidDate / isValidTime / isValidDateTime', () {
      expect(WValidator.isValidDate('2024-01-15'), true);
      expect(WValidator.isValidDate('not-a-date'), false);
      expect(WValidator.isValidTime('14:30:00'), true);
      expect(WValidator.isValidTime('25:00:00'), false);
      expect(WValidator.isValidDateTime('2024-01-15 14:30:00'), true);
    });
  });

  group('WRegExp', () {
    test('WRegExp 是 RegExp 实例', () {
      expect(WRegExp.email, isA<RegExp>());
      expect(WRegExp.phone, isA<RegExp>());
      expect(WRegExp.url, isA<RegExp>());
      expect(WRegExp.ipv4, isA<RegExp>());
    });

    test('firstEmailMatch / firstPhoneMatch', () {
      expect(WRegExp.firstEmailMatch('test@example.com'), isNotNull);
      expect(WRegExp.firstEmailMatch('invalid'), isNull);
      expect(WRegExp.firstPhoneMatch('13800138000'), isNotNull);
      expect(WRegExp.firstPhoneMatch('12345'), isNull);
    });

    test('maskPhone / formatPhone', () {
      expect(WRegExp.maskPhone('13800138000'), '138****8000');
      expect(WRegExp.formatPhone('13800138000'), '138-0013-8000');
    });
  });
}
