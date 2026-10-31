import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景一：登录。
///
/// 展示：文本 / 密码字段、字段 validator、统一边框、校验设置、提交。
class LoginExamplePage extends StatefulWidget {
  const LoginExamplePage({super.key});

  @override
  State<LoginExamplePage> createState() => _LoginExamplePageState();
}

class _LoginExamplePageState extends State<LoginExamplePage> {
  final _form = WFormController();

  late final _validators = _form.validators(
    settings: WFormValidatorSettings()
      ..showBorderError = true
      ..continueOnError = true,
    items: [
      WFormValidatorItem.field('email'),
      WFormValidatorItem.field('password'),
    ],
  );

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录表单')),
      body: SafeArea(
        child: exampleFormTheme(
          child: WFormScope(
            formData: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '欢迎回来',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '这里展示字段 Config、字段校验和 WFormValidatorSettings。',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                _emailField(),
                const SizedBox(height: 16),
                _passwordField(),
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
                    '每个字段使用一份新的 Config。',
                    '校验设置通过 settings 传入。',
                    '边框由 WFormTheme 统一提供。',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    final config = exampleTextConfig()
      ..keyboardType = TextInputType.emailAddress
      ..textInputAction = TextInputAction.next
      ..autofocus = true;

    return config.build(
      name: 'email',
      hintText: '邮箱',
      bordered: true,
      hintTextList: const ['请输入邮箱'],
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return '请输入邮箱';
        if (!email.contains('@')) return '邮箱格式不正确';
        return null;
      },
    );
  }

  Widget _passwordField() {
    final config = exampleTextConfig()
      ..obscureText = true
      ..textInputAction = TextInputAction.done
      ..actions = const [WFormTextFieldPasswordToggle()];

    return config.build(
      name: 'password',
      hintText: '密码',
      bordered: true,
      hintTextList: const ['密码至少 8 位'],
      validator: (value) {
        final password = value ?? '';
        if (password.isEmpty) return '请输入密码';
        if (password.length < 8) return '密码至少 8 位';
        return null;
      },
    );
  }

  Future<void> _submit() async {
    if (!_validators.validate()) return;

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
