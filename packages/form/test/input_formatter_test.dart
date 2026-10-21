import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 快捷创建 TextEditingValue（光标在末尾）
TextEditingValue _val(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('WCardNumberInputFormatter', () {
    test('4 位添加一个空格', () {
      final fmt = WCardNumberInputFormatter();
      final result = fmt.formatEditUpdate(_val('1234'), _val('12345678'));
      expect(result.text, '1234 5678');
    });

    test('16 位完整卡号', () {
      final fmt = WCardNumberInputFormatter();
      final result = fmt.formatEditUpdate(_val(''), _val('1234567890123456'));
      expect(result.text, '1234 5678 9012 3456');
    });

    test('末尾不足 4 位不加空格', () {
      final fmt = WCardNumberInputFormatter();
      final result = fmt.formatEditUpdate(_val('1234 5678'), _val('1234 5678901'));
      expect(result.text, '1234 5678 901');
    });

    test('删除数字时保持空格格式', () {
      final fmt = WCardNumberInputFormatter();
      final result = fmt.formatEditUpdate(_val('1234 5678'), _val('1234 567'));
      expect(result.text, '1234 567');
    });

    test('连续删除全部数字', () {
      final fmt = WCardNumberInputFormatter();
      final result = fmt.formatEditUpdate(_val('1234 5678'), _val(''));
      expect(result.text, '');
    });

    test('删除分隔符后的数字时光标不跳位', () {
      final fmt = WCardNumberInputFormatter();
      const oldValue = TextEditingValue(
        text: '1234 5678',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '1234 678',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = fmt.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1234 678');
      expect(result.selection.baseOffset, 5);
    });
  });

  group('WDividerInputFormatter', () {
    test('默认 first=3 rear=4 pattern=空格', () {
      final fmt = WDividerInputFormatter();
      final result = fmt.formatEditUpdate(_val(''), _val('12345678901'));
      expect(result.text, '123 4567 8901');
    });

    test('自定义 first=2 rear=2 pattern=-', () {
      final fmt = WDividerInputFormatter(first: 2, rear: 2, pattern: '-');
      final result = fmt.formatEditUpdate(_val(''), _val('abcdefgh'));
      expect(result.text, 'ab-cd-ef-gh');
    });

    test('光标保持在末尾', () {
      final fmt = WDividerInputFormatter();
      final result = fmt.formatEditUpdate(_val('123 456'), _val('123 456789'));
      expect(result.selection.baseOffset, result.text.length);
    });

    test('删除分隔符后的数字时光标不跳位', () {
      final fmt = WDividerInputFormatter();
      const oldValue = TextEditingValue(
        text: '123 4567',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '123 467',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = fmt.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123 467');
      expect(result.selection.baseOffset, 5);
    });
  });

  group('WInputFormatters.phone()', () {
    test('返回 3 个 formatter', () {
      final List<TextInputFormatter> list = WInputFormatters.phone();
      expect(list, hasLength(3));
      expect(list[0], FilteringTextInputFormatter.digitsOnly);
      expect(list[1], isA<WCardNumberInputFormatter>());
      expect(list[2], isA<LengthLimitingTextInputFormatter>());
    });

    test('LengthLimitingTextInputFormatter 限制 9 位', () {
      final List<TextInputFormatter> list = WInputFormatters.phone();
      final limiter = list[2] as LengthLimitingTextInputFormatter;
      expect(limiter.maxLength, 9);
    });
  });
}
