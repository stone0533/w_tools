import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';
import 'package:w_tools_form/src/components/fields/text_field.dart';

void main() {
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

  group('WFormValidatorSettings', () {
    test('默认值', () {
      const config = WFormValidatorSettings();
      expect(config.showBorderError, isFalse);
      expect(config.continueOnError, isFalse);
      expect(config.notifyAllErrors, isFalse);
      expect(config.customErrorCallback, isNull);
      expect(config.itemValidationCallback, isNull);
      expect(config.shouldSkipValidation, isNull);
    });

    test('构造参数可设置回调与开关', () {
      bool called = false;
      final config = WFormValidatorSettings(
        showBorderError: true,
        customErrorCallback: (field, error) => called = true,
      );

      expect(config.showBorderError, isTrue);
      config.customErrorCallback!('a', 'err');
      expect(called, isTrue);
    });

    test('copyWith 生成新实例且不修改原实例', () {
      const base = WFormValidatorSettings(showBorderError: true);
      final copy = base.copyWith(continueOnError: true);

      expect(base.continueOnError, isFalse);
      expect(copy.showBorderError, isTrue);
      expect(copy.continueOnError, isTrue);
    });
  });

  group('WFormValidator.validate（回归）', () {
    testWidgets('开启全量校验后不再短路：全部校验项都会被检查', (tester) async {
      final data = WFormController();
      final visited = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: data,
              child: const Column(
                children: [
                  WFormTextFieldCore(name: 'a'),
                  WFormTextFieldCore(name: 'b'),
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
        settings: WFormValidatorSettings(
          continueOnError: true,
          itemValidationCallback: ((name, ok, err) => visited.add(name)),
        ),
      );

      expect(validators.validate(), isFalse);
      // 全量校验模式下首个失败项不再 return false，`b` 也会被校验
      expect(visited, ['a', 'b']);
    });
  });
}
