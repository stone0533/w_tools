import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

void main() {
  testWidgets('WForm.onChanged 收到整表值', (tester) async {
    Map<String, dynamic>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            onChanged: (values) => changed = values,
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!['email'], 'a@b.com');
  });

  testWidgets('validators() 不传 items 时校验全部字段', (tester) async {
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

    final validator = form.validators();
    expect(validator.validate(), isFalse);

    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.pump();
    expect(validator.validate(), isTrue);
  });

  testWidgets('message 与 hintTextList 同传时断言', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'email',
              label: '邮箱',
              message: '消息',
              hintTextList: ['提示'],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('两个 WForm 共用 controller 会得到可读错误', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WForm(
                controller: form,
                child: const WFormTextField(name: 'a', label: 'A'),
              ),
              WForm(
                controller: form,
                child: const WFormTextField(name: 'b', label: 'B'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('w-form-duplicate-controller')), findsOneWidget);
    // 第一个 WForm 不受影响，仍正常渲染。
    expect(find.text('A'), findsWidgets);
  });

  testWidgets('同一帧替换 WForm（key 变化）仍可复用 controller', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            key: const ValueKey('first'),
            controller: form,
            child: const WFormTextField(name: 'a', label: 'A'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            key: const ValueKey('second'),
            controller: form,
            child: const WFormTextField(name: 'b', label: 'B'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('WForm 卸载后 controller 可再次挂载', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'a', label: 'A'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'b', label: 'B'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('bordered:false 字段 setError 会断言提示', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'plain', label: '无边框', bordered: false),
          ),
        ),
      ),
    );

    expect(formBordersOf(form).has('plain'), isFalse);
    expect(
      () => form.setError('plain', errorTextList: const ['不会渲染']),
      throwsAssertionError,
    );
  });

  testWidgets('borderless 字段 validate 不抛异常，错误只进 errors', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormTextField(
              name: 'plain',
              label: '无边框',
              bordered: false,
              validator: (_) => '必填',
            ),
          ),
        ),
      ),
    );

    final validator = form.validators();
    expect(validator.validate(), isFalse);
    expect(tester.takeException(), isNull);
    expect(validator.errors['plain'], '必填');
  });

  testWidgets('移除 owner 后重复挂载的 WForm 会恢复', (tester) async {
    final form = WFormController();
    Widget build({required bool showFirst}) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            if (showFirst)
              WForm(
                key: const ValueKey('first'),
                controller: form,
                child: const WFormTextField(name: 'a', label: 'A'),
              ),
            WForm(
              key: const ValueKey('second'),
              controller: form,
              child: const WFormTextField(name: 'b', label: 'B'),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(build(showFirst: true));
    expect(find.byKey(const ValueKey<String>('w-form-duplicate-controller')), findsOneWidget);

    await tester.pumpWidget(build(showFirst: false));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('w-form-duplicate-controller')), findsNothing);
    expect(find.text('B'), findsWidgets);
  });

  testWidgets('恢复挂载后重新注入默认校验设置', (tester) async {
    final form = WFormController();
    Widget build({required bool showFirst}) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            if (showFirst)
              WForm(
                key: const ValueKey('first'),
                controller: form,
                child: const WFormTextField(name: 'a', label: 'A'),
              ),
            WForm(
              key: const ValueKey('second'),
              controller: form,
              child: const WFormTextField(name: 'b', label: 'B'),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(build(showFirst: true));
    await tester.pumpWidget(build(showFirst: false));
    await tester.pump();

    // 恢复后必须重新注入 WForm 的默认校验设置，否则 validate() 不再显示边框错误。
    expect(form.validatorSettings?.showBorderError, isTrue);
  });

  testWidgets('换绑 controller 会清掉旧 controller 的默认校验设置', (tester) async {
    final first = WFormController();
    final second = WFormController();
    Widget build(WFormController controller) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: controller,
          child: const WFormTextField(name: 'email', label: '邮箱'),
        ),
      ),
    );

    await tester.pumpWidget(build(first));
    expect(first.validatorSettings, isNotNull);

    await tester.pumpWidget(build(second));
    expect(first.validatorSettings, isNull);
    expect(second.validatorSettings, isNotNull);
  });

  testWidgets('WFormButton 支持 message 简写', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderStyle: WFormBorderStyle.standard(),
            child: WFormButton(
              name: 'coupon',
              label: '选择优惠券',
              message: '请选择优惠券',
              onTap: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('请选择优惠券'), findsWidgets);
  });

  test('formEntered 未挂载时是不可变空表', () {
    final form = WFormController();
    expect(() => form.formEntered['x'] = true, throwsUnsupportedError);
  });

  testWidgets('formEntered 返回独立副本：改它不影响表单', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'a', label: 'A'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();

    final snapshot = form.formEntered;
    snapshot['extra'] = true;

    // 改副本不能写回表单：formEntered 是按字段值派生的快照。
    expect(form.formEntered.containsKey('extra'), isFalse);
    expect(form.formEntered['a'], isTrue);
  });
}
