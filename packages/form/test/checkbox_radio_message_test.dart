import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

String? _requireAgree(bool? value) => value == true ? null : '请先同意';

String? _requireGender(String? value) => value == null ? '请选择性别' : null;

String? _requireDate(String? value) => value == null ? '请选择生日' : null;

void main() {
  testWidgets('WFormCheckbox 默认带边框：validator 错误可见', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              validator: _requireAgree,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WFormFieldShell), findsOneWidget);
    expect(form.validate(), isFalse);
    await tester.pump();

    // 默认 bordered 必须是 true，否则校验失败只有 WFormValidator.errors，界面看不到错误。
    expect(find.text('请先同意'), findsOneWidget);
  });

  testWidgets('WFormRadioGroup 默认带边框：validator 错误可见', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormRadioGroup<String>(
              name: 'gender',
              items: {'female': '女', 'male': '男'},
              validator: _requireGender,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WFormFieldShell), findsOneWidget);
    expect(form.validate(), isFalse);
    await tester.pump();

    expect(find.text('请选择性别'), findsOneWidget);
  });

  testWidgets('bordered checkbox 的原生 errorText 仍由边框展示', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              bordered: true,
              validator: _requireAgree,
            ),
          ),
        ),
      ),
    );

    // 走原生 Form 通道：errorText 由 FormBuilder 写入，但 checkbox builder 不渲染它，
    // 边框不能因此吞掉文案。
    expect(form.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('请先同意'), findsOneWidget);
  });

  testWidgets('bordered date 的原生 errorText 仍由边框展示', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormDatePicker(
              name: 'birthday',
              bordered: true,
              validator: _requireDate,
            ),
          ),
        ),
      ),
    );

    expect(form.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('请选择生日'), findsOneWidget);
  });

  testWidgets('WFormCheckbox.message 在有边框时作为提示显示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              message: '请先同意协议',
              bordered: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('请先同意协议'), findsOneWidget);
  });

  testWidgets('WFormRadioGroup.message 在有边框时作为提示显示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormRadioGroup<String>(
              name: 'gender',
              items: {'female': '女', 'male': '男'},
              message: '请选择性别',
              bordered: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('请选择性别'), findsOneWidget);
  });
}
