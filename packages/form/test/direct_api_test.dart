import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'internal/_helpers/config_exports.dart';

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

    expect(form.hasBorder('email'), isTrue);
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

  testWidgets('WFormDatePicker 仅传 hintText 也显示占位符（回归：曾只认 label）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormDatePicker(name: 'birthday', hintText: '请选择生日'),
          ),
        ),
      ),
    );

    expect(find.text('请选择生日'), findsOneWidget);
    final decoration = tester.widget<InputDecorator>(find.byType(InputDecorator).first).decoration;
    expect(decoration.hintText, '请选择生日');
  });

  testWidgets('WFormDatePicker 传 label 时显示占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormDatePicker(name: 'birthday', label: '生日'),
          ),
        ),
      ),
    );

    expect(find.text('生日'), findsOneWidget);
  });

  testWidgets('WFormDropdown hintText 优先于历史 label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormDropdown<String>(
              name: 'city',
              label: '旧占位符',
              hintText: '新占位符',
              items: {'sh': '上海'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('新占位符'), findsWidgets);
    expect(find.text('旧占位符'), findsNothing);
  });

  testWidgets('WFormMultiDropdown hintText 为空字符串时不显示占位', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormMultiDropdown(
              name: 'tags',
              hintText: '',
              items: {'a': 'A'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('ALL'), findsNothing);
  });

  testWidgets('WFormMultiDropdown 未配置 hintText 时不显示占位（与 Dropdown 一致）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormMultiDropdown(
              name: 'tags',
              items: {'a': 'A'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('ALL'), findsNothing);
  });

  testWidgets('7 个直接字段都支持 leading / actions 插槽', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const Column(
              children: [
                WFormTextField(
                  name: 'a',
                  leading: Icon(Icons.abc, key: ValueKey('lead-a')),
                ),
                WFormDropdown<String>(
                  name: 'b',
                  items: {'x': 'X'},
                  leading: Icon(Icons.abc, key: ValueKey('lead-b')),
                  actions: [Icon(Icons.star, key: ValueKey('act-b'))],
                ),
                WFormMultiDropdown(
                  name: 'c',
                  items: {'x': 'X'},
                  leading: Icon(Icons.abc, key: ValueKey('lead-c')),
                  actions: [Icon(Icons.star, key: ValueKey('act-c'))],
                ),
                WFormDatePicker(
                  name: 'd',
                  leading: Icon(Icons.abc, key: ValueKey('lead-d')),
                  actions: [Icon(Icons.star, key: ValueKey('act-d'))],
                ),
                WFormCheckbox(
                  name: 'e',
                  title: Text('E'),
                  leading: Icon(Icons.abc, key: ValueKey('lead-e')),
                  actions: [Icon(Icons.star, key: ValueKey('act-e'))],
                ),
                WFormRadioGroup<String>(
                  name: 'f',
                  items: {'x': 'X'},
                  leading: Icon(Icons.abc, key: ValueKey('lead-f')),
                  actions: [Icon(Icons.star, key: ValueKey('act-f'))],
                ),
                WFormButton(
                  name: 'g',
                  onTap: _noopTap,
                  leading: Icon(Icons.abc, key: ValueKey('lead-g')),
                  actions: [Icon(Icons.star, key: ValueKey('act-g'))],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final key in ['lead-a', 'lead-b', 'lead-c', 'lead-d', 'lead-e', 'lead-f', 'lead-g']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: '缺少 $key');
    }
    for (final key in ['act-b', 'act-c', 'act-d', 'act-e', 'act-f', 'act-g']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: '缺少 $key');
    }
  });

  testWidgets('bordered:false + message 不再静默丢弃（与文本字段一致）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormDropdown<String>(
              name: 'city',
              items: {'sh': '上海'},
              bordered: false,
              message: '请选择城市',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('WFormController.reset 重置字段值与输入状态', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: const Column(
              children: [
                WFormTextField(name: 'email', initialValue: 'seed'),
                WFormCheckbox(name: 'agree', title: Text('同意')),
              ],
            ),
          ),
        ),
      ),
    );

    form.setValue<String>('email', 'changed');
    form.updateValue<bool>('agree', true);
    await tester.pump();
    expect(form.getFieldsValue<String>('email'), 'changed');
    expect(form.formEntered['agree'], isTrue);

    form.reset();
    await tester.pump();
    expect(form.getFieldsValue<String>('email'), 'seed');
    expect(form.formEntered['email'], isTrue);
    expect(form.getFieldsValue<bool>('agree'), isFalse);
    expect(form.formEntered['agree'], isFalse);
  });

  testWidgets('直接字段可交互写值：checkbox / radio / button', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: Column(
              children: [
                const WFormCheckbox(name: 'agree', title: Text('同意')),
                const WFormRadioGroup<String>(
                  name: 'gender',
                  items: {'female': '女', 'male': '男'},
                ),
                WFormButton(
                  name: 'coupon',
                  label: '选择优惠券',
                  selectedWidgetBuilder: (value) => Text('已选 $value'),
                  onTap: (_, didChange) => didChange('new_user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('同意'));
    await tester.tap(find.text('男'));
    await tester.tap(find.text('选择优惠券'));
    await tester.pump();

    expect(form.getFieldsValue<bool>('agree'), isTrue);
    expect(form.getFieldsValue<String>('gender'), 'male');
    expect(form.getFieldsValue<String>('coupon'), 'new_user');
    expect(find.text('已选 new_user'), findsOneWidget);
  });

  testWidgets('WFormFieldStyleScope 可覆盖单个字段的样式', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(height: 52),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormFieldStyleScope(
              style: WFormFieldStyle(height: 70),
              child: WFormDropdown<String>(
                name: 'city',
                items: {'sh': '上海'},
              ),
            ),
          ),
        ),
      ),
    );

    final core = tester.widget<WFormDropdownCore<String>>(
      find.byType(WFormDropdownCore<String>),
    );
    expect(core.config.height, 70);
  });
}

void _noopTap(String? value, ValueChanged<String> didChange) {}
