import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

void main() {
  testWidgets('autovalidateMode 传给底层 FormBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: const WFormTextField(name: 'a', hintText: 'A'),
          ),
        ),
      ),
    );

    final builder = tester.widget<FormBuilder>(find.byType(FormBuilder));
    expect(builder.autovalidateMode, AutovalidateMode.onUserInteraction);
  });

  testWidgets('运行期切换 readOnly：值保留，切回后可继续编辑', (tester) async {
    final form = WFormController();
    Widget build({required bool readOnly}) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          readOnly: readOnly,
          child: const WFormTextField(name: 'a', hintText: 'A'),
        ),
      ),
    );

    await tester.pumpWidget(build(readOnly: false));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(form.value['a'], 'hello');

    await tester.pumpWidget(build(readOnly: true));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(form.value['a'], 'hello');

    await tester.pumpWidget(build(readOnly: false));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    await tester.enterText(find.byType(TextField), 'hello2');
    await tester.pump();
    expect(form.value['a'], 'hello2');
  });

  testWidgets('shouldSkipValidation 跳过的字段不校验、不进 errors', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: const Column(
        children: [
          WFormTextField(name: 'a', hintText: 'A', validator: _alwaysFail),
          WFormTextField(name: 'b', hintText: 'B', validator: _alwaysFail),
        ],
      ),
    );

    final validator = form.validators(
      settings: WFormValidatorSettings(
        showBorderError: false,
        shouldSkipValidation: ((name, _) => name == 'a'),
      ),
    );

    expect(validator.validate(), isFalse);
    expect(validator.errors.keys, ['b']);
  });

  test('validators().add 的新校验项参与下一次 validate', () {
    final form = WFormController();
    final validator = form.validators();
    validator.add(
      WFormValidatorItem(
        fieldName: 'extra',
        validatorBuilder: () =>
            (_) => '自定义失败',
      ),
    );

    expect(validator.validate(), isFalse);
    expect(validator.errors['extra'], '自定义失败');
  });

  test('WFormValidatorSettings 是不可变配置（const 构造 + 命名参数）', () {
    const settings = WFormValidatorSettings(showBorderError: true, continueOnError: true);
    expect(settings.showBorderError, isTrue);
    expect(settings.continueOnError, isTrue);
    final copy = settings.copyWith(notifyAllErrors: true);
    expect(copy.continueOnError, isTrue);
    expect(copy.notifyAllErrors, isTrue);
  });

  testWidgets('bordered: false 的 message 渲染在字段下方，52px 容器内不溢出', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 52,
            child: WForm(
              controller: WFormController(),
              child: const WFormTextField(
                name: 'a',
                hintText: 'A',
                bordered: false,
                message: '提示文案',
              ),
            ),
          ),
        ),
      ),
    );

    // 先确认没有溢出：溢出异常会由 takeException 取走。
    expect(tester.takeException(), isNull);

    // 正向断言：文案真的渲染了，而且落在输入框下方。
    // 只断言「不抛异常」时，删掉文案渲染这条用例仍会绿。
    final input = find.byType(TextField);
    final message = find.text('提示文案');
    expect(message, findsOneWidget);
    expect(
      tester.getTopLeft(message).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(input).dy),
    );
  });

  testWidgets('bordered: false 的字段把多条提示用「；」拼起来渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'a',
              hintText: 'A',
              bordered: false,
              hintTextList: ['第一条', '第二条'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('第一条；第二条'), findsOneWidget);
  });

  testWidgets('date 的 displayFormat 直接生效', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormDatePicker(
              name: 'd',
              hintText: '日期',
              initialValue: '2024-03-05',
              displayFormat: 'yyyy/MM/dd',
            ),
          ),
        ),
      ),
    );

    expect(find.text('2024/03/05'), findsOneWidget);
  });

  testWidgets('text 的 maxLines / onEditingComplete 生效', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormTextField(
              name: 'bio',
              hintText: '简介',
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => completed = true,
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 3);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('multi 弹层打开后字段卸载，再点选项不崩', (tester) async {
    final form = WFormController();
    Widget build({required bool show}) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          child: show
              ? const WFormMultiDropdown(name: 'tags', items: {'a': 'A'})
              : const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(build(show: true));
    await tester.tap(find.byType(WFormMultiDropdown<String>));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsWidgets);

    await tester.pumpWidget(build(show: false));
    await tester.pumpAndSettle();

    // 弹层挂在 Navigator 上，字段卸载后仍然存在——「再点」这条路是真的能走到的。
    expect(find.text('A'), findsWidgets);
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    // 没有 mounted 守卫时会报 setState() called after dispose()。
    expect(tester.takeException(), isNull);
  });

  testWidgets('WFormThemeData.of 读取子树主题数据', (tester) async {
    late WFormThemeData? data;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            icons: const WFormIcons(dropdown: Icon(Icons.expand_more)),
            child: Builder(
              builder: (context) {
                data = WFormThemeData.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(data, isNotNull);
    expect((data!.effectiveDropdownIcon as Icon).icon, Icons.expand_more);
    expect(data!.effectiveClearButtonIcon, WFormIcons.defaults.clear);
  });

  testWidgets('checkbox 的 iconSpacing / iconYOffset 生效', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              iconSpacing: 12,
              iconYOffset: 3,
            ),
          ),
        ),
      ),
    );

    final spacing = tester.widget<SizedBox>(
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 12),
    );
    expect(spacing.width, 12);
    final transform = tester.widget<Transform>(
      find.byWidgetPredicate((w) => w is Transform && w.transform.storage[13] == 3),
    );
    expect(transform.transform.storage[13], 3);
  });

  testWidgets('radio 的 itemExtraBuilder / lineSpacing 生效', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormRadioGroup<String>(
              name: 'level',
              items: const {'a': 'A'},
              lineSpacing: 6,
              itemExtraBuilder: (_, value, label, selected) => Text('extra-$label-$selected'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('extra-A-false'), findsOneWidget);
    final column = tester.widget<Column>(
      find.byWidgetPredicate((w) => w is Column && w.spacing == 6),
    );
    expect(column.spacing, 6);
  });

  testWidgets('外部 focusNode 在字段卸载后不被 dispose', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormTextField(name: 'a', hintText: 'A', focusNode: node),
          ),
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    // 仍可正常使用，说明没被包内 dispose
    expect(() => node.requestFocus(), returnsNormally);
    node.dispose();
  });

  testWidgets('WForm 的 borderStyle 只通过一个作用域下发', (tester) async {
    final style = WFormBorderStyle.standard();
    late WFormBorderStyle? resolved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderStyle: style,
            child: Builder(
              builder: (context) {
                resolved = WFormThemeData.of(context)?.borderStyle;
                return const WFormTextField(name: 'a', hintText: 'A');
              },
            ),
          ),
        ),
      ),
    );

    expect(resolved, style);
  });

  testWidgets('两条校验路径都调用时不重复渲染错误文案', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: const WFormTextField(name: 'a', hintText: 'A', validator: _alwaysFail),
    );

    expect(form.validate(), isFalse); // 边框通道
    expect(form.formKey.currentState!.validate(), isFalse); // ffb 内联通道
    await tester.pump();

    // 同一字段的同一错误只能出现一次。
    expect(find.text('必填'), findsOneWidget);
  });

  testWidgets('字段卸载后错误通道与边框登记都被清理', (tester) async {
    final form = WFormController();
    Widget build({required bool show}) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          child: show ? const WFormTextField(name: 'a', hintText: 'A') : const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(build(show: true));
    form.setError('a', errorTextList: const ['出错了']);
    await tester.pump();
    expect(formBordersOf(form).has('a'), isTrue);

    await tester.pumpWidget(build(show: false));
    await tester.pump();
    expect(formBordersOf(form).has('a'), isFalse);

    // 同名字段重新挂载：不应继承上一次的错误
    await tester.pumpWidget(build(show: true));
    await tester.pump();
    expect(formBordersOf(form).has('a'), isTrue);
    expect(find.text('出错了'), findsNothing);
  });

  testWidgets('multi dropdown 的 disabledKeys 不可点击', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormMultiDropdown(
              name: 'tags',
              items: {'a': 'A', 'b': 'B'},
              disabledKeys: {'b'},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(WFormMultiDropdown<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();
    expect(form.value['tags'], isNull);

    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();
    expect(form.value['tags'], {'a'});
  });

  testWidgets('radio 的 titleBuilder 定制每个选项标题', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormRadioGroup<String>(
              name: 'level',
              items: const {'basic': '基础'},
              titleBuilder: (_, value, label, selected) => Text('$label${selected ? '*' : ''}'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('基础'), findsOneWidget);
  });

  testWidgets('checkbox 的 disabledIcon 在禁用时替换图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              enabled: false,
              disabledIcon: Icon(Icons.block),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.block), findsOneWidget);
  });

  testWidgets('dropdown 的 initialValue 不在 items 时不崩溃（保持现状，仅不显示）', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormDropdown<String>(
              name: 'city',
              items: {'sh': '上海'},
              initialValue: 'not-in-items',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(WFormDropdown<String>), findsOneWidget);
    expect(form.value['city'], 'not-in-items');
  });

  testWidgets('等值的 validatorSettings 不会每帧重写 controller', (tester) async {
    final form = WFormController();
    Widget build() => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          // 官方示例就是这么内联构造的：只要值相等，就不该触发重新注入
          validatorSettings: const WFormValidatorSettings(continueOnError: true),
          child: const WFormTextField(name: 'a', hintText: 'A'),
        ),
      ),
    );

    await tester.pumpWidget(build());
    final first = form.validatorSettings;

    await tester.pumpWidget(build());
    expect(identical(form.validatorSettings, first), isTrue);
  });

  testWidgets('字段级 style 覆盖 WForm.fieldStyle 的 textStyle', (tester) async {
    const fieldStyle = TextStyle(color: Color(0xFF111111));
    const override = TextStyle(color: Color(0xFF222222));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(textStyle: fieldStyle),
            child: const Column(
              children: [
                WFormTextField(name: 'a', hintText: 'A'),
                WFormTextField(name: 'b', hintText: 'B', style: override),
              ],
            ),
          ),
        ),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].style?.color, const Color(0xFF111111));
    expect(fields[1].style?.color, const Color(0xFF222222));
  });

  testWidgets('先边框错误、下一帧再内联错误时只渲染一条文案', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: const WFormTextField(name: 'a', hintText: 'A', validator: _alwaysFail),
    );

    // 第一帧：WFormValidator 写边框错误。
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('必填'), findsOneWidget);

    // 第二帧：原生 Form 校验写字段内联错误；边框不能重复展示。
    expect(form.formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('必填'), findsOneWidget);
  });

  testWidgets('shouldSkipValidation 跳过的字段会清掉上次的边框错误', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: const Column(
        children: [
          WFormTextField(name: 'a', hintText: 'A', validator: _alwaysFail),
          WFormTextField(name: 'b', hintText: 'B', validator: _alwaysFail),
        ],
      ),
    );

    expect(
      form.validators(settings: const WFormValidatorSettings(showBorderError: true)).validate(),
      isFalse,
    );
    await tester.pump();
    expect(find.text('必填'), findsOneWidget);

    // 第二次校验跳过 a：a 的旧边框错误必须清掉，只保留 b 的错误。
    expect(
      form
          .validators(
            settings: WFormValidatorSettings(
              showBorderError: true,
              shouldSkipValidation: (name, _) => name == 'a',
            ),
          )
          .validate(),
      isFalse,
    );
    await tester.pump();
    expect(find.text('必填'), findsOneWidget);
  });

  test('未挂载表单的 validators().validate() 返回 false', () {
    expect(WFormController().validators().validate(), isFalse);
  });

  testWidgets('text 的 textAlign / maxLength 生效', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'a',
              hintText: 'A',
              textAlign: TextAlign.end,
              maxLength: 5,
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textAlign, TextAlign.end);
    expect(field.maxLength, 5);
  });

  testWidgets('dropdown 的 style / iconSize 生效', (tester) async {
    const red = Color(0xFFFF0000);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormDropdown<String>(
              name: 'd',
              items: {'a': 'A'},
              initialValue: 'a',
              style: TextStyle(color: red),
              iconSize: 18,
            ),
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.iconSize, 18);
    expect(tester.widget<Text>(find.text('A')).style?.color, red);
  });

  testWidgets('date 的 initialValue 用 ISO 字符串', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormDatePicker(
              name: 'd',
              initialValue: '2024-03-05',
              displayFormat: 'yyyy-MM-dd',
            ),
          ),
        ),
      ),
    );

    expect(find.text('2024-03-05'), findsOneWidget);
    expect(form.value['d'], '2024-03-05');
  });
}

String? _alwaysFail(String? value) => '必填';
