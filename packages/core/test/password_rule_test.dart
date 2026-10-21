import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

/// 回归：密码规则只能有一个真相。
///
/// 文档 `doc/core_module.md:423` 承诺：`password` = ≥8 位，且同时包含
/// 小写字母、大写字母与数字。`WRegExpPattern.password` 与
/// `WValidator.isValidPassword` 曾各自实现一套规则并漂移，本测试锁住「同源」。
void main() {
  /// 文档规则下的期望值（符号允许出现，但大小写与数字必须齐全）。
  const canonical = <String, bool>{
    'Aa1aaaaa': true, // 恰好 8 位
    'Passw0rd': true,
    'Passw0rd!': true, // 允许符号
    'Aa1aaaa': false, // 只有 7 位
    'password1': false, // 缺大写
    'PASSWORD1': false, // 缺小写
    '12345678': false, // 缺字母
    'abcdefgh': false,
    'Abc12345': true,
    'short': false,
  };

  group('WValidator.isValidPassword 遵循文档规则', () {
    canonical.forEach((input, expected) {
      test('$input -> $expected', () {
        expect(WValidator.isValidPassword(input), expected);
      });
    });
  });

  group('WRegExp.firstPasswordMatch 遵循文档规则', () {
    canonical.forEach((input, expected) {
      test('$input -> $expected', () {
        expect(WRegExp.firstPasswordMatch(input) != null, expected);
      });
    });
  });

  test('两个公开入口对所有样本保持一致（防漂移）', () {
    for (final input in canonical.keys) {
      expect(
        WRegExp.firstPasswordMatch(input) != null,
        WValidator.isValidPassword(input),
        reason: '密码规则漂移: "$input" 在两个入口给出不同结果',
      );
    }
  });
}
