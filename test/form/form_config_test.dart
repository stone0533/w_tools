import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

void main() {
  group('WFormDefaults', () {
    testWidgets('所有静态图标字段都是 Widget 类型', (tester) async {
      // 这些字段是在 WConfig 拆分时迁移过来的
      expect(WFormDefaults.dropdownIcon, isA<Widget>());
      expect(WFormDefaults.radioUnselectedIcon, isA<Widget>());
      expect(WFormDefaults.radioSelectedIcon, isA<Widget>());
      expect(WFormDefaults.checkboxUnselectedIcon, isA<Widget>());
      expect(WFormDefaults.checkboxSelectedIcon, isA<Widget>());
      expect(WFormDefaults.obscureTextIcon, isA<Widget>());
      expect(WFormDefaults.obscureTextVisibleIcon, isA<Widget>());
    });

    testWidgets('可以替换图标为自定义 Widget', (tester) async {
      const custom = Text('▼');
      final original = WFormDefaults.dropdownIcon;
      WFormDefaults.dropdownIcon = custom;
      expect(WFormDefaults.dropdownIcon, same(custom));
      // restore
      WFormDefaults.dropdownIcon = original;
    });
  });

  group('WFormValidatorItem', () {
    test('构造函数初始化字段', () {
      final item = WFormValidatorItem(
        fieldName: 'email',
        validatorBuilder: () =>
            (v) => v == null || v.isEmpty ? 'required' : null,
      );
      expect(item.fieldName, 'email');
      expect(item.autofocus, true); // 默认 true
    });

    test('autofocus 可以设为 false', () {
      final item = WFormValidatorItem(
        fieldName: 'name',
        validatorBuilder: () =>
            (v) => null,
        autofocus: false,
      );
      expect(item.autofocus, false);
    });
  });

  group('WFormValidatorConfig', () {
    test('默认值', () {
      final config = WFormValidatorConfig();
      // 私有字段但有公开行为 — 通过 setter 设置后验证
      config.showBorderError = true;
      expect(config, isNotNull); // 只是验证类可实例化
    });

    test('setter 可以设置回调', () {
      final config = WFormValidatorConfig();
      bool callbackCalled = false;
      config.customErrorCallback = (field, error) => callbackCalled = true;
      // 无法验证私有字段，但 setter 不应抛异常
      expect(callbackCalled, false);
    });
  });

  group('WFormCustomValidator', () {
    test('空值同样交给自定义函数（可自行实现必填规则）', () {
      final validator = WFormCustomValidator.custom<String>(
        validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
      );

      // 修复前：checkNullOrEmpty=false 时会跳过自定义函数、直接放行
      expect(validator(null), '必填');
      expect(validator(''), '必填');
      expect(validator('abc'), isNull);
    });

    test('返回 null 表示校验通过', () {
      final validator = WFormCustomValidator.custom<int>(
        validator: (v) => (v != null && v > 0) ? null : '必须为正数',
      );

      expect(validator(1), isNull);
      expect(validator(-1), '必须为正数');
      expect(validator(null), '必须为正数');
    });

    testWidgets('作为表单字段校验器挂载（FormBuilder）：空值失败、填写后通过', (tester) async {
      final formData = WFormData();

      await pumpForm(
        tester,
        formData: formData,
        child: FormBuilderTextField(
          name: 'name',
          decoration: const InputDecoration(),
          validator: WFormCustomValidator.custom<String>(
            validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
          ),
        ),
      );

      // 空值：校验失败并渲染错误文案
      expect(formData.formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('必填'), findsOneWidget);

      // 填写后：校验通过、错误清除
      await tester.enterText(find.byType(TextField), 'abc');
      expect(formData.formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('必填'), findsNothing);
    });
  });

  group('WFormValidator.validate（回归）', () {
    testWidgets('开启全量校验后不再短路：全部校验项都会被检查', (tester) async {
      final data = WFormData();
      final visited = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: data,
              child: Column(
                children: [
                  WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
                  WFormTextField(config: WFormTextFieldConfig(), name: 'b'),
                ],
              ),
            ),
          ),
        ),
      );

      final validators = WFormValidator(
        formData: data,
        validationItems: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (v) => (v == null || v.toString().isEmpty) ? 'a 必填' : null,
          ),
          WFormValidatorItem(
            fieldName: 'b',
            validatorBuilder: () =>
                (v) => (v == null || v.toString().isEmpty) ? 'b 必填' : null,
          ),
        ],
        config: WFormValidatorConfig()
          ..continueOnError = true
          ..itemValidationCallback = ((name, ok, err) => visited.add(name)),
      );

      expect(validators.validate(), isFalse);
      // 全量校验模式下首个失败项不再 return false，`b` 也会被校验
      expect(visited, ['a', 'b']);
    });
  });
}
