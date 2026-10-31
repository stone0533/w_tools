import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景一：登录。
///
/// 展示：WForm 容器、直接字段构造、字段 validator、校验设置、提交。
class LoginExamplePage extends StatefulWidget {
  const LoginExamplePage({super.key});

  @override
  State<LoginExamplePage> createState() => _LoginExamplePageState();
}

class _LoginExamplePageState extends State<LoginExamplePage> {
  final _form = WFormController();

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录表单')),
      body: WForm(
        controller: _form,
        borderConfig: exampleBorderConfig,
        fieldStyle: exampleFieldStyle,
        clearButtonIcon: const Icon(Icons.close_rounded, size: 18),
        validatorSettings: WFormValidatorSettings()
          ..showBorderError = true
          ..continueOnError = true,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '欢迎回来',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '这里展示 WForm / 直接字段构造 / 字段校验。',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            WFormTextField(
              name: 'email',
              label: '邮箱',
              message: '请输入邮箱',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofocus: true,
              actions: const [WFormTextFieldClearButton()],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return '请输入邮箱';
                if (!email.contains('@')) return '邮箱格式不正确';
                return null;
              },
            ),
            const SizedBox(height: 16),
            WFormTextField(
              name: 'password',
              label: '密码',
              message: '密码至少 8 位',
              obscureText: true,
              textInputAction: TextInputAction.done,
              config: exampleTextConfig(),
              actions: const [WFormTextFieldPasswordToggle()],
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return '请输入密码';
                if (password.length < 8) return '密码至少 8 位';
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
            ),
            const SizedBox(height: 16),
            const _TipCard(
              title: '提示',
              lines: [
                'WForm 统一提供主题、Scope 和只读作用域。',
                '字段直接构造，不再写 Config.build。',
                '校验设置通过 settings 传入。',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final values = _form.value;
      final email = (values['email'] as String?)?.trim() ?? '';
      // 实际项目在这里调用登录接口。
      await Future<void>.delayed(const Duration(milliseconds: 600));
      debugPrint('login: $email');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功（示例）')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF0FDF4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line'),
              ),
          ],
        ),
      ),
    );
  }
}
