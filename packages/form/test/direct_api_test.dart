import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WForm + 直接字段构造', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: Column(
              children: [
                WFormTextField(
                  name: 'email',
                  label: '邮箱',
                  validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
                ),
                const WFormDropdown<String>(
                  name: 'country',
                  label: '国家',
                  items: {'CN': '中国'},
                ),
                WFormButton(
                  name: 'coupon',
                  label: '选择优惠券',
                  onTap: (_, didChange) => didChange('new_user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('邮箱'), findsWidgets);
    expect(find.text('国家'), findsWidgets);
    expect(find.text('选择优惠券'), findsOneWidget);
  });

  testWidgets('WForm 直接 API 走字段 validator', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    final valid = form.validate(
      settings: WFormValidatorSettings()..showBorderError = true,
    );
    expect(valid, isFalse);
  });

  testWidgets('config 优先于 WForm.fieldStyle', (tester) async {
    final config = WFormTextFieldConfig()..height = 80;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(height: 52),
            child: WFormTextField(
              name: 'email',
              config: config,
            ),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormTextFieldCore>(
      find.byType(WFormTextFieldCore),
    );
    expect(core.config.height, 80);
  });

  testWidgets('DatePicker config 的 decoration 不被 label 覆盖', (tester) async {
    final config = WFormDatePickerConfig()..decoration = const InputDecoration(hintText: '自定义日期');

    await tester.pumpWidget(
      MaterialApp(
        home: WForm(
          controller: WFormController(),
          child: WFormDatePicker(
            name: 'birthday',
            label: '生日',
            config: config,
          ),
        ),
      ),
    );

    final core = tester.widget<WFormDatePickerCore>(
      find.byType(WFormDatePickerCore),
    );
    expect(core.config.decoration?.hintText, '自定义日期');
  });

  testWidgets('MultiDropdown config 的 hintText 不被 label 覆盖', (tester) async {
    final config = WFormMultiDropdownConfig()..hintText = '自定义提示';

    await tester.pumpWidget(
      MaterialApp(
        home: WForm(
          controller: WFormController(),
          child: WFormMultiDropdown(
            name: 'tags',
            label: '兴趣',
            items: const {'a': 'A'},
            config: config,
          ),
        ),
      ),
    );

    final core = tester.widget<WFormMultiDropdownCore>(
      find.byType(WFormMultiDropdownCore),
    );
    expect(core.config.hintText, '自定义提示');
  });

  testWidgets('提前创建的 validators 也能使用 WForm.validatorSettings', (tester) async {
    final form = WFormController();
    final validators = form.validators(
      items: [WFormValidatorItem.field('email')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            validatorSettings: WFormValidatorSettings()..showBorderError = true,
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    expect(validators.validate(), isFalse);
  });

  testWidgets('WForm 卸载后清理 controller 的默认校验设置', (tester) async {
    final form = WFormController();
    final settings = WFormValidatorSettings()..showBorderError = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            validatorSettings: settings,
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );
    expect(form.validatorSettings, same(settings));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(form.validatorSettings, isNull);
  });

  testWidgets('WForm.fieldStyle 作为字段默认高度', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(height: 60),
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormTextFieldCore>(
      find.byType(WFormTextFieldCore),
    );
    expect(core.config.height, 60);
  });
}
