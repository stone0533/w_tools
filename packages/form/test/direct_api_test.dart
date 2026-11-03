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

  testWidgets('DatePicker 传 config 时 label 仍作为 hint 兜底', (tester) async {
    final config = WFormDatePickerConfig()..displayFormat = 'yyyy-MM-dd';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormDatePicker(
              name: 'birthday',
              label: '生日',
              config: config,
            ),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormDatePickerCore>(
      find.byType(WFormDatePickerCore),
    );
    expect(core.config.decoration?.hintText, '生日');
  });

  testWidgets('Button 传 config 时保留 config 的 hintWidget', (tester) async {
    final config = WFormFieldButtonConfig()..hintWidget = const Text('config hint');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormButton(
              name: 'coupon',
              config: config,
              onTap: (_, didChange) {},
            ),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormFieldButtonCore>(
      find.byType(WFormFieldButtonCore),
    );
    expect(core.config.hintWidget, isNotNull);
    expect(find.text('config hint'), findsOneWidget);
  });

  testWidgets('边框 key 按字段 name 自动注册', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    expect(form.ensureBorderKey('email').currentState, isNotNull);
    form.setError('email', errorTextList: const ['邮箱错误']);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('直接字段不覆盖 config 的 enabled / obscureText / autofocus', (tester) async {
    final config = WFormTextFieldConfig()
      ..enabled = false
      ..obscureText = true
      ..autofocus = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormTextField(name: 'password', config: config),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormTextFieldCore>(
      find.byType(WFormTextFieldCore),
    );
    expect(core.config.enabled, isFalse);
    expect(core.config.obscureText, isTrue);
    expect(core.config.autofocus, isTrue);
  });

  testWidgets('label 不进入 hintTextList', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    final shell = tester.widget<WFormFieldShell>(
      find.byType(WFormFieldShell),
    );
    expect(shell.hintTextList, isNull);
  });

  testWidgets('TextFieldConfig 的 hintText / decoration 生效', (tester) async {
    final config = WFormTextFieldConfig()
      ..hintText = '配置提示'
      ..decoration = const InputDecoration(suffixIcon: Icon(Icons.clear));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormTextField(name: 'email', config: config),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, '配置提示');
    expect(field.decoration?.suffixIcon, isNotNull);
  });

  testWidgets('config 只覆盖自己设置的字段，fieldStyle 填充其余项', (tester) async {
    final config = WFormTextFieldConfig()..obscureText = true;
    const fieldStyle = WFormFieldStyle(
      height: 52,
      textStyle: TextStyle(fontSize: 18),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: fieldStyle,
            child: WFormTextField(name: 'password', config: config),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormTextFieldCore>(
      find.byType(WFormTextFieldCore),
    );
    expect(core.config.obscureText, isTrue);
    expect(core.config.height, 52);
    expect(core.config.style?.fontSize, 18);
  });

  testWidgets('只传 borderConfig 时，validate 失败默认可见错误文案', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('请输入邮箱'), findsWidgets);
  });

  testWidgets('显式 validatorSettings 优先：showBorderError=false 时不渲染错误', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            validatorSettings: WFormValidatorSettings(),
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('请输入邮箱'), findsNothing);
  });
}
