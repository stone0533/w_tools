// ignore_for_file: prefer_const_constructors
// 契约测试：从公共入口即可拿到 flutter_form_builder 的核心类型，
// 消费方不必再自己声明同版本依赖（P1-7）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 自定义字段：直接继承 re-export 的基类。
class _DemoField extends FormBuilderField<String> {
  _DemoField({required super.name}) : super(builder: (field) => const SizedBox.shrink());

  @override
  FormBuilderFieldState<_DemoField, String> createState() => _DemoFieldState();
}

class _DemoFieldState extends FormBuilderFieldState<_DemoField, String> {}

void main() {
  testWidgets('公共入口导出 FormBuilderState / Fields / Field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: Column(
              children: [
                WFormTextField(name: 'email', hintText: '邮箱'),
                _DemoField(name: 'demo'),
              ],
            ),
          ),
        ),
      ),
    );

    final controller = WFormController();
    final FormBuilderState? state = controller.formKey.currentState;
    // 未挂载时 currentState 为 null，这里验证的是类型可被解析
    expect(state, isNull);

    final FormBuilderFields? fields = controller.fields;
    expect(fields, isNull);
  });
}
