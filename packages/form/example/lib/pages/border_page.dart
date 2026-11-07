import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景五：自定义 WFormBorderStyle。
class BorderExamplePage extends StatefulWidget {
  const BorderExamplePage({super.key});

  @override
  State<BorderExamplePage> createState() => _BorderExamplePageState();
}

class _BorderExamplePageState extends State<BorderExamplePage> {
  final _form = WFormController();
  String? _lastValidation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自定义边框')),
      body: WForm(
        controller: _form,
        borderStyle: exampleCompactBorderConfig,
        fieldStyle: exampleFieldStyle,
        validatorSettings: WFormValidatorSettings(
          showBorderError: true,
          itemValidationCallback: (name, ok, error) {
            _lastValidation = ok ? '$name：通过' : '$name：$error';
          },
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '自定义边框',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'WFormBorderStyle 可以覆盖默认 / 聚焦 / 错误 / 只读装饰，以及 hint / error 布局。',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            WFormTextField(
              name: 'nickname',
              label: '昵称',
              message: '这里会显示自定义 hintBuilder',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入昵称';
                return null;
              },
            ),
            const SizedBox(height: 16),
            WFormTextField(
              name: 'code',
              label: '验证码',
              message: '输入 1234',
              validator: (value) {
                if (value != '1234') return '验证码不正确';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                _form.validate();
                setState(() {});
              },
              child: const Text('触发校验'),
            ),
            const SizedBox(height: 12),
            Text(
              _lastValidation ?? '点击校验查看 itemValidationCallback',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
