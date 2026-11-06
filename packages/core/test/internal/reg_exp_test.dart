import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/reg_exp.dart';

void main() {
  group('WRegExp 模式', () {
    test('编译后的 RegExp 字段可用', () {
      expect(WRegExp.email.hasMatch('test@example.com'), isTrue);
      expect(WRegExp.phone.hasMatch('13812345678'), isTrue);
      expect(WRegExp.idCard.hasMatch('110101199001011234'), isTrue);
      expect(WRegExp.url.hasMatch('https://www.example.com'), isTrue);
      expect(WRegExp.ipv4.hasMatch('192.168.1.1'), isTrue);
      expect(WRegExp.macAddress.hasMatch('00:1B:44:11:3A:B7'), isTrue);
      expect(WRegExp.date.hasMatch('2023-01-01'), isTrue);
      expect(WRegExp.bankCard.hasMatch('1234567890123456'), isTrue);
      expect(WRegExp.postalCode.hasMatch('100000'), isTrue);
    });

    test('firstXxxMatch 返回首个匹配，无匹配时为 null', () {
      expect(WRegExp.firstEmailMatch('a@example.com')?.group(0), 'a@example.com');
      expect(WRegExp.firstEmailMatch('invalid'), isNull);
      expect(WRegExp.firstPhoneMatch('13812345678')?.group(0), '13812345678');
      expect(WRegExp.firstPhoneMatch('12345'), isNull);
      expect(WRegExp.firstDateMatch('2023-01-01')?.group(0), '2023-01-01');
    });

    test('正数 / 正整数 / 正小数 排除 0', () {
      expect(WRegExp.positiveNumber.hasMatch('0'), isFalse);
      expect(WRegExp.positiveNumber.hasMatch('0.0'), isFalse);
      expect(WRegExp.positiveNumber.hasMatch('0.5'), isTrue);
      expect(WRegExp.positiveNumber.hasMatch('12'), isTrue);

      expect(WRegExp.positiveInteger.hasMatch('0'), isFalse);
      expect(WRegExp.positiveInteger.hasMatch('00'), isFalse);
      expect(WRegExp.positiveInteger.hasMatch('12'), isTrue);

      expect(WRegExp.positiveDecimal.hasMatch('0.0'), isFalse);
      expect(WRegExp.positiveDecimal.hasMatch('0.5'), isTrue);
      expect(WRegExp.positiveDecimal.hasMatch('12.0'), isTrue);
    });
  });

  group('信息提取', () {
    test('extractBirthdayFromIdCard 返回出生日期', () {
      expect(WRegExp.extractBirthdayFromIdCard('110101199001011234'), '1990-01-01');
      expect(WRegExp.extractBirthdayFromIdCard('110101200012311234'), '2000-12-31');
    });

    test('extractBirthdayFromIdCard 输入非法时返回 null', () {
      expect(WRegExp.extractBirthdayFromIdCard('123456'), isNull);
      expect(WRegExp.extractBirthdayFromIdCard('invalid'), isNull);
      // 1990-02-30：身份证正则能匹配，但真实日期非法
      expect(WRegExp.extractBirthdayFromIdCard('110101199002301234'), isNull);
    });

    test('extractGenderFromIdCard 返回性别', () {
      expect(WRegExp.extractGenderFromIdCard('110101199001011234'), '男'); // 第 17 位是 3（奇数）
      expect(WRegExp.extractGenderFromIdCard('110101199001011246'), '女'); // 第 17 位是 4（偶数）
    });

    test('extractGenderFromIdCard 输入非法时返回 null', () {
      expect(WRegExp.extractGenderFromIdCard('123456'), isNull);
      expect(WRegExp.extractGenderFromIdCard('invalid'), isNull);
    });
  });

  group('掩码处理', () {
    test('maskPhone 保留前 3 位与后 4 位', () {
      expect(WRegExp.maskPhone('13812345678'), '138****5678');
    });

    test('maskPhone 对非法手机号原样返回', () {
      expect(WRegExp.maskPhone('123456'), '123456');
    });

    test('maskBankCard 保留前 4 位与后 4 位', () {
      expect(WRegExp.maskBankCard('1234567890123456'), '1234********3456');
      expect(WRegExp.maskBankCard('1234567890123456789'), '1234***********6789');
    });

    test('maskBankCard 对短号或非法卡号原样返回', () {
      expect(WRegExp.maskBankCard('12345678'), '12345678');
      expect(WRegExp.maskBankCard('123456'), '123456');
    });
  });

  group('格式化', () {
    test('formatPhone 输出 XXX-XXXX-XXXX', () {
      expect(WRegExp.formatPhone('13812345678'), '138-1234-5678');
    });

    test('formatPhone 对非法手机号原样返回', () {
      expect(WRegExp.formatPhone('123456'), '123456');
    });

    test('formatDate 将 YYYYMMDD 转为 YYYY-MM-DD', () {
      expect(WRegExp.formatDate('19900101'), '1990-01-01');
      expect(WRegExp.formatDate('20001231'), '2000-12-31');
    });

    test('formatDate 输入非法或日期不存在时返回 null', () {
      expect(WRegExp.formatDate('199001'), isNull);
      expect(WRegExp.formatDate('invalid'), isNull);
      expect(WRegExp.formatDate('19900230'), isNull); // 2 月无 30 日
    });
  });
}
