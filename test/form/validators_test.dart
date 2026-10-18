import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

/// 构造一个总是校验失败的校验项
WFormValidatorItem failingItem(String name) => WFormValidatorItem(
  fieldName: name,
  validatorBuilder: () =>
      (_) => '$name error',
);

/// 构造一个总是校验通过的校验项
WFormValidatorItem passingItem(String name) => WFormValidatorItem(
  fieldName: name,
  validatorBuilder: () =>
      (_) => null,
);

void main() {
  group('WFormValidator 短路 / 全量校验', () {
    testWidgets('默认短路校验：遇到第一个失败项即返回，不再校验后续字段', (tester) async {
      final formData = WFormData();
      final validated = <String>[];
      final config = WFormValidatorConfig()
        ..itemValidationCallback = (name, isValid, errorText) {
          validated.add(name);
        };

      final validators = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), failingItem('b'), failingItem('c')],
        config: config,
      );

      final result = validators.validate();

      expect(result, isFalse);
      // 只校验到第一个失败项，后续字段被短路
      expect(validated, ['a']);
    });

    testWidgets('全量校验：continueOnError = true 时遍历全部校验项', (tester) async {
      final formData = WFormData();
      final validated = <String>[];
      final config = WFormValidatorConfig()
        ..continueOnError = true
        ..itemValidationCallback = (name, isValid, errorText) {
          validated.add(name);
        };

      final validators = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), passingItem('b'), failingItem('c')],
        config: config,
      );

      final result = validators.validate();

      expect(result, isFalse);
      // 遍历全部校验项，失败项之后的字段依然会被校验
      expect(validated, ['a', 'b', 'c']);
    });

    testWidgets('全量校验：customErrorCallback 仅对第一个失败项触发', (tester) async {
      final formData = WFormData();
      final notified = <String>[];
      final config = WFormValidatorConfig()
        ..continueOnError = true
        ..customErrorCallback = (fieldName, error) {
          notified.add(fieldName);
        };

      final validators = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), failingItem('b'), failingItem('c')],
        config: config,
      );

      final result = validators.validate();

      expect(result, isFalse);
      // 错误提示只针对第一个失败项，避免重复弹提示
      expect(notified, ['a']);
    });

    testWidgets('全量校验：notifyAllErrors = true 时每个失败项都触发 customErrorCallback', (tester) async {
      final notified = <String>[];
      final config = WFormValidatorConfig()
        ..continueOnError = true
        ..notifyAllErrors = true
        ..customErrorCallback = (fieldName, error) => notified.add(fieldName);

      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [failingItem('a'), passingItem('b'), failingItem('c')],
        config: config,
      );

      validators.validate();

      // 每个失败项都触发一次，通过项不触发
      expect(notified, ['a', 'c']);
    });

    testWidgets('全量校验：通过字段会清除上一次残留的边框错误', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a'),
            WFormTextFieldConfig().buildBordered(name: 'b'),
          ],
        ),
      );

      // 先手动给 a 设置一个残留错误
      formData.setError('a', errorTextList: ['a error']);
      await tester.pump();
      expect(find.text('a error'), findsOneWidget);

      // 全量校验：a 通过（应清除残留错误），b 失败（应显示错误）
      final config = WFormValidatorConfig()..showBorderError = true;
      final validators = WFormValidator(
        formData: formData,
        validationItems: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (_) => null,
          ),
          failingItem('b'),
        ],
        config: config,
      );
      validators.validate();
      await tester.pump();

      expect(find.text('a error'), findsNothing);
      expect(find.text('b error'), findsOneWidget);
    });

    testWidgets('errors 汇总：全量校验收集全部失败项', (tester) async {
      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [failingItem('a'), passingItem('b'), failingItem('c')],
        config: WFormValidatorConfig()..continueOnError = true,
      );

      validators.validate();

      expect(validators.errors, {'a': 'a error', 'c': 'c error'});
    });

    testWidgets('errors 汇总：短路校验只包含短路前的失败项', (tester) async {
      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [failingItem('a'), failingItem('b')],
      );

      validators.validate();

      expect(validators.errors, {'a': 'a error'});
    });

    testWidgets('errors 汇总：每次校验会先清空上一次结果', (tester) async {
      var fail = true;
      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (_) => fail ? 'a error' : null,
          ),
        ],
      );

      validators.validate();
      expect(validators.errors, {'a': 'a error'});

      fail = false;
      validators.validate();
      expect(validators.errors, isEmpty);
    });

    testWidgets('errors 为只读视图，外部不可修改', (tester) async {
      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [failingItem('a')],
      );

      validators.validate();

      expect(validators.errors, {'a': 'a error'});
      expect(() => validators.errors['a'] = 'x', throwsUnsupportedError);
      expect(validators.errors, {'a': 'a error'});
    });

    testWidgets('errors 返回快照：后续校验不修改已持有的结果', (tester) async {
      var fail = true;
      final validators = WFormValidator(
        formData: WFormData(),
        validationItems: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (_) => fail ? 'a error' : null,
          ),
        ],
      );

      validators.validate();
      final snapshot = validators.errors;
      expect(snapshot, {'a': 'a error'});

      fail = false;
      validators.validate();
      expect(validators.errors, isEmpty);
      expect(snapshot, {'a': 'a error'});
    });

    testWidgets('autofocus：仅聚焦第一个失败项，后续失败项不聚焦', (tester) async {
      final formData = WFormData();
      final focusA = FocusNode();
      final focusB = FocusNode();
      addTearDown(focusA.dispose);
      addTearDown(focusB.dispose);

      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a', focusNode: focusA),
            WFormTextFieldConfig().buildBordered(name: 'b', focusNode: focusB),
          ],
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), failingItem('b')],
        config: WFormValidatorConfig()
          ..showBorderError = true
          ..continueOnError = true,
      );

      validators.validate();
      await tester.pump();

      expect(focusA.hasFocus, isTrue);
      expect(focusB.hasFocus, isFalse);
    });

    testWidgets('autofocus：与 showBorderError 解耦（关闭边框也会聚焦首个失败项）', (tester) async {
      final formData = WFormData();
      final focusA = FocusNode();
      addTearDown(focusA.dispose);

      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a', focusNode: focusA),
          ],
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a')],
        config: WFormValidatorConfig()..showBorderError = false,
      );

      validators.validate();
      await tester.pump();

      expect(focusA.hasFocus, isTrue);
    });

    testWidgets('autofocus：第一个失败项 autofocus=false 时后续失败项也不聚焦', (tester) async {
      final formData = WFormData();
      final focusA = FocusNode();
      final focusB = FocusNode();
      addTearDown(focusA.dispose);
      addTearDown(focusB.dispose);

      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a', focusNode: focusA),
            WFormTextFieldConfig().buildBordered(name: 'b', focusNode: focusB),
          ],
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (_) => 'a error',
            autofocus: false,
          ),
          failingItem('b'),
        ],
        config: WFormValidatorConfig()
          ..showBorderError = true
          ..continueOnError = true,
      );

      validators.validate();
      await tester.pump();

      expect(focusA.hasFocus, isFalse);
      expect(focusB.hasFocus, isFalse);
    });

    testWidgets('短路校验：清除上一次全量校验遗留在后续字段的红框', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a'),
            WFormTextFieldConfig().buildBordered(name: 'b'),
          ],
        ),
      );

      final full = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), failingItem('b')],
        config: WFormValidatorConfig()
          ..showBorderError = true
          ..continueOnError = true,
      );
      full.validate();
      await tester.pump();
      expect(find.text('a error'), findsOneWidget);
      expect(find.text('b error'), findsOneWidget);

      // 换成短路校验（新实例，验证不依赖实例内部状态）
      final short = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a'), failingItem('b')],
        config: WFormValidatorConfig()..showBorderError = true,
      );
      short.validate();
      await tester.pump();

      expect(find.text('a error'), findsOneWidget);
      // b 未参与本次校验，其残留红框应被清除
      expect(find.text('b error'), findsNothing);
    });

    testWidgets('关闭 showBorderError 后清除上一次残留的边框错误', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().buildBordered(name: 'a'),
          ],
        ),
      );

      final on = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a')],
        config: WFormValidatorConfig()..showBorderError = true,
      );
      on.validate();
      await tester.pump();
      expect(find.text('a error'), findsOneWidget);

      final off = WFormValidator(
        formData: formData,
        validationItems: [failingItem('a')],
        config: WFormValidatorConfig()..showBorderError = false,
      );
      off.validate();
      await tester.pump();

      expect(find.text('a error'), findsNothing);
    });
  });

  group('WFormValidatorItem.field — 使用字段自身 validator', () {
    testWidgets('执行字段 validator 并汇总 errors', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormTextFieldConfig().build(
          name: 'name',
          validator: (value) => value == null || value.isEmpty ? '必填' : null,
        ),
      );

      final validators = formData.validators(items: [WFormValidatorItem.field('name')]);

      expect(validators.validate(), isFalse);
      expect(validators.errors, {'name': '必填'});
      // 不写入字段 errorText，错误只通过 errors / 边框汇总
      expect(formData.formKey.currentState!.fields['name']!.errorText, isNull);

      formData.didChange('name', 'abc');
      await tester.pump();

      expect(validators.validate(), isTrue);
      expect(validators.errors, isEmpty);
    });

    testWidgets('短路：首个字段失败后不再校验后续字段', (tester) async {
      final formData = WFormData();
      final visited = <String>[];
      await pumpForm(
        tester,
        formData: formData,
        child: Column(
          children: [
            WFormTextFieldConfig().build(name: 'a', validator: (_) => 'a error'),
            WFormTextFieldConfig().build(name: 'b', validator: (_) => 'b error'),
          ],
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [
          WFormValidatorItem.field('a'),
          WFormValidatorItem.field('b'),
        ],
        config: WFormValidatorConfig()
          ..itemValidationCallback = (name, isValid, errorText) {
            visited.add(name);
          },
      );

      expect(validators.validate(), isFalse);
      expect(visited, ['a']);
    });

    testWidgets('showBorderError 将字段 validator 错误同步到边框', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormButtonConfig().buildBordered(
          name: 'btn',
          validator: (_) => '字段错误',
          onTap: (_, __) {},
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [WFormValidatorItem.field('btn')],
        config: WFormValidatorConfig()..showBorderError = true,
      );

      expect(validators.validate(), isFalse);
      await tester.pump();

      // WFormButton 不渲染 InputDecoration.errorText，文案只能来自边框错误
      expect(find.text('字段错误'), findsOneWidget);
    });

    testWidgets('错误只走边框：text 字段的 errorText 不被写入', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormTextFieldConfig().buildBordered(
          name: 'name',
          validator: (_) => '必填',
        ),
      );

      final validators = WFormValidator(
        formData: formData,
        validationItems: [WFormValidatorItem.field('name')],
        config: WFormValidatorConfig()..showBorderError = true,
      );

      expect(validators.validate(), isFalse);
      await tester.pump();

      expect(formData.formKey.currentState!.fields['name']!.errorText, isNull);
      // 文案只出现一次（来自 WFormBorder，而不是 InputDecoration）
      expect(find.text('必填'), findsOneWidget);
    });

    testWidgets('字段未注册时视为通过', (tester) async {
      final formData = WFormData();
      await pumpForm(tester, formData: formData, child: const SizedBox.shrink());

      final validators = formData.validators(items: [WFormValidatorItem.field('missing')]);

      expect(validators.validate(), isTrue);
      expect(validators.errors, isEmpty);
    });
  });
}
