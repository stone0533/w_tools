import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 防止 README / docs/agents/form.md 中的公开 API 示例随重构失效。
///
/// 测试不解析 Markdown，而是用同一组入口做编译和渲染校验；
/// 文档中的 API 改名时，这里会先红。
void main() {
  testWidgets('README / form agents 示例使用的直接 API 可编译', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(radius: 12),
            fieldStyle: const WFormFieldStyle(
              height: 52,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            validatorSettings: WFormValidatorSettings()..showBorderError = true,
            child: ListView(
              children: [
                WFormTextField(
                  name: 'email',
                  label: '邮箱',
                  message: '请输入邮箱',
                  validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
                ),
                const WFormDropdown<String>(
                  name: 'country',
                  label: '国家 / 地区',
                  items: {
                    'CN': '中国大陆',
                    'HK': '中国香港',
                  },
                ),
                const WFormMultiDropdown(
                  name: 'interests',
                  label: '兴趣',
                  items: {
                    'music': '音乐',
                    'travel': '旅行',
                  },
                ),
                const WFormDatePicker(
                  name: 'birthday',
                  label: '生日',
                ),
                const WFormCheckbox(
                  name: 'marketing',
                  title: Text('接收优惠信息'),
                ),
                const WFormRadioGroup<String>(
                  name: 'gender',
                  items: {
                    'female': '女',
                    'male': '男',
                  },
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
    expect(form.validate(), isFalse);
  });

  testWidgets('form_module.md 示例使用的公开 API 可编译并渲染', (tester) async {
    final form = WFormController();

    // §7 校验：文档签名是 validators({settings, items})
    final settings = WFormValidatorSettings()
      ..showBorderError = true
      ..continueOnError = true
      ..customErrorCallback = (name, err) {}
      ..itemValidationCallback = (name, ok, err) {}
      ..shouldSkipValidation = (name, values) => false;
    final validator = form.validators(
      settings: settings,
      items: [
        WFormValidatorItem.field('email'),
        WFormValidatorItem(
          fieldName: 'password',
          validatorBuilder: () =>
              (value) => value == null ? '必填' : null,
        ),
      ],
    );
    expect(validator.errors, isEmpty);

    // §4 边框：不可变配置 + 链式装饰 + 自定义布局
    final decoration = const WFormBorderDecoration()
        .withUniformBorder(1, Colors.grey)
        .withUniformBorderRadius(8)
        .withColor(Colors.white);
    final borderConfig =
        WFormBorderConfig(
          defaultDecoration: decoration,
          focusedDecoration: decoration,
          errorDecoration: decoration,
          hintStyle: const TextStyle(fontSize: 12),
          errorStyle: const TextStyle(fontSize: 12),
          layout: WFormBorderLayout.builder(
            (context, data) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [data.child, data.message],
            ),
          ),
        ).copyWith(
          layout: WFormBorderLayout.column,
          errorBuilder: (list) => Text(list?.join('；') ?? ''),
        );
    expect(borderConfig.copy(), equals(borderConfig));
    expect(WFormBorderConfig.fromTheme(ThemeData.light()).errorStyle, isNotNull);

    // §3 图标 / 主题
    final icons = WFormIcons.defaults.copyWith(
      dropdown: const Icon(Icons.expand_more),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: borderConfig,
            icons: icons,
            fieldStyle: const WFormFieldStyle(height: 52),
            validatorSettings: settings,
            child: Column(
              children: [
                WFormTextField(
                  name: 'email',
                  label: '邮箱',
                  // §8 格式化器
                  inputFormatters: WFormInputFormatters.phone(),
                  actions: [
                    WFormTextFieldAction(
                      visibleWhen: (data) => data.hasText,
                      iconBuilder: (data) => const Icon(Icons.send),
                      onPressed: (data) {},
                    ),
                    const WFormTextFieldClearButton(),
                    const WFormTextFieldPasswordToggle(),
                  ],
                ),
                WFormDatePicker(
                  name: 'birthday',
                  label: '生日',
                  displayFormat: 'yyyy-MM-dd',
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                ),
                const WFormMultiDropdown(
                  name: 'tags',
                  hintText: '请选择',
                  items: {'a': 'A'},
                  disabledKeys: {},
                ),
                WFormButton(
                  name: 'coupon',
                  label: '请选择优惠券',
                  onTap: (_, didChange) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('邮箱'), findsWidgets);
  });

  testWidgets('自定义字段：WFormFieldShell + FormBuilderField 可渲染并参与校验', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: WFormFieldShell(
              name: 'amount',
              readOnly: false,
              child: FormBuilderField<String>(
                name: 'amount',
                validator: (value) => (value ?? '').isEmpty ? '请输入金额' : null,
                builder: (field) => TextField(
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: field.didChange,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.attach_money), findsOneWidget);
    expect(form.validate(), isFalse);
    expect(form.formBorderKeys.containsKey('amount'), isTrue);
  });
}
