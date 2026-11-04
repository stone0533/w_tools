// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';
import '_helpers/config_exports.dart';

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

  testWidgets('hintText 优先于历史 label', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(
              name: 'email',
              label: '旧占位符',
              hintText: '新占位符',
            ),
          ),
        ),
      ),
    );
    expect(find.text('新占位符'), findsWidgets);
    expect(find.text('旧占位符'), findsNothing);
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
