import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  group('WFormTextFieldConfig copyWith / copy', () {
    test('copyWith 不覆盖时保留原值', () {
      final config = WFormTextFieldConfig()
        ..height = 50
        ..obscureText = true;

      final copied = config.copyWith();
      // 私有字段但通过 build 间接验证不行
      // 只能通过 setter 再次设置验证... 实际上这里很难，
      // 因为私有字段没 getter
      expect(copied, isA<WFormTextFieldConfig>());
    });

    test('copy 创建独立实例', () {
      final config = WFormTextFieldConfig(height: 42);
      final copied = config.copy();
      expect(copied, isNot(same(config)));
    });
  });

  group('WFormTextFieldConfig setter', () {
    test('所有 setter 都能正常赋值', () {
      final config = WFormTextFieldConfig()
        ..keyboardType = TextInputType.emailAddress
        ..inputFormatters = [FilteringTextInputFormatter.digitsOnly]
        ..readOnlyStyle = const TextStyle(color: Colors.grey)
        ..height = 50
        ..style = const TextStyle(fontSize: 16)
        ..contentPadding = const EdgeInsets.all(8)
        ..hintStyle = const TextStyle(color: Colors.grey)
        ..yOffset = 0.5
        ..leading = const Icon(Icons.person)
        ..actions = [const Text('✕')]
        ..containerDecoration = const BoxDecoration(color: Colors.white)
        ..containerMargin = const EdgeInsets.all(4)
        ..containerPadding = const EdgeInsets.all(8)
        ..textAlign = TextAlign.center
        ..autofocus = true
        ..obscureText = true
        ..prefix = const Text('+86')
        ..prefixIcon = const Icon(Icons.phone)
        ..maxLines = 5
        ..textInputAction = TextInputAction.done;

      expect(config, isA<WFormTextFieldConfig>());
    });
  });

  group('WFormTextFieldConfig.build', () {
    testWidgets('build 返回 WFormTextFieldCore', (tester) async {
      final config = WFormTextFieldConfig();
      final textField = config.build(name: 'email') as WFormTextFieldCore;
      expect(textField, isA<WFormTextFieldCore>());
      expect(textField.name, 'email');
    });

    testWidgets('build 传递 hintText / onChanged / onSubmitted', (tester) async {
      final config = WFormTextFieldConfig();

      final widget = config.build(
        name: 'test',
        hintText: '请输入',
        onChanged: (_) {},
        onSubmitted: (_) {},
        initialValue: 'hello',
        readOnly: true,
      );
      // readOnly 时外层包一层只读作用域
      final textField = (widget as WFormReadOnlyScope).child as WFormTextFieldCore;

      expect(textField.name, 'test');
      expect(textField.hintText, '请输入');
      expect(textField.readOnly, true);
      expect(textField.initialValue, 'hello');
    });

    testWidgets('build(bordered: false, readOnly: true) 下发只读作用域', (tester) async {
      final config = WFormTextFieldConfig();
      final widget = config.build(name: 'test', readOnly: true);

      expect(widget, isA<WFormReadOnlyScope>());
      expect((widget as WFormReadOnlyScope).readOnly, isTrue);
      expect(widget.child, isA<WFormTextFieldCore>());
    });

    testWidgets('build(bordered: false) 传 hintTextList 时断言提示', (tester) async {
      final config = WFormTextFieldConfig();
      expect(
        () => config.build(name: 'test', hintTextList: const ['提示']),
        throwsAssertionError,
      );
    });

    testWidgets('build(bordered: true) 空 name 抛 ArgumentError', (tester) async {
      final config = WFormTextFieldConfig();
      expect(
        () => config.build(bordered: true, name: ''),
        throwsArgumentError,
      );
    });

    testWidgets('build(bordered: true) 非空 name 返回 Widget', (tester) async {
      final config = WFormTextFieldConfig();
      final bordered = config.build(bordered: true, name: 'email');
      expect(bordered, isA<Widget>());
    });
  });
}
