# w_tools_form

[![pub package](https://img.shields.io/pub/v/w_tools_form.svg)](https://pub.dev/packages/w_tools_form)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

`w_tools_form` 是 w_tools 的表单层，提供输入、下拉、日期、单选复选等字段，以及表单容器、边框、只读和字段级校验能力。

## 特性

- **WForm 容器**：一次组合主题、表单作用域和只读作用域
- **直接字段构造**：`WFormTextField` / `WFormDropdown` / `WFormDatePicker` 等直接使用
- **直接字段参数**：常用样式/插槽直接传参；可变字段 Config 已在 5.0 移除
- **边框体系**：`WFormBorderConfig`（不可变）+ `WFormBorder`
- **只读与校验**：`WFormReadOnlyScope` / `WFormValidatorSettings`
- **字段按钮**：`WFormButton` 自定义选择、弹层等交互

完整可运行示例见 [`example/`](example/)。

## 安装

```yaml
dependencies:
  w_tools_form: ^5.1.0
```

> 最低要求 Flutter 3.38.0（由 `flutter_form_builder` / `form_builder_validators` 依赖约束）。
>
> **公开依赖**：`WFormController.formKey` / `fields` 的类型来自 `flutter_form_builder`，
> 自定义字段也要继承它的 `FormBuilderField` / `FormBuilderFieldState`。这些类型已由
> `package:w_tools_form/w_tools_form.dart` 一并导出，消费方不需要再自己声明该依赖；
> 如确需直接 import，请使用与 `w_tools_form` 相同的版本约束。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = WFormController();

  @override
  Widget build(BuildContext context) {
    return WForm(
      controller: _form,
      borderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
      fieldStyle: const WFormFieldStyle(
        height: 52,
        containerPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      validatorSettings: WFormValidatorSettings()
        ..showBorderError = true,
      child: Column(
        children: [
          WFormTextField(
            name: 'email',
            hintText: '邮箱',
            message: '请输入邮箱',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return '请输入邮箱';
              if (!email.contains('@')) return '邮箱格式不正确';
              return null;
            },
          ),
          WFormTextField(
            name: 'password',
            hintText: '密码',
            message: '密码至少 8 位',
            obscureText: true,
            actions: const [WFormTextFieldPasswordToggle()],
            validator: (value) {
              final password = value ?? '';
              if (password.length < 8) return '密码至少 8 位';
              return null;
            },
          ),
          FilledButton(
            onPressed: () {
              if (_form.validate()) {
                debugPrint('submit: ${_form.value}');
              }
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }
}
```

## 高级样式

普通页面优先用直接字段参数；跨字段默认值放 `WForm.fieldStyle`。
可变 `WForm*Config` / `Config.build` 已在 form 5.0 移除。

```dart
WFormTextField(
  name: 'email',
  hintText: '邮箱',
  leading: const Icon(Icons.mail_outline),
)
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 表单容器 | `WForm` / `WFormController` |
| 文本 / 密码 | `WFormTextField` / `WFormTextFieldPasswordToggle` |
| 下拉 / 多选 | `WFormDropdown` / `WFormMultiDropdown` |
| 日期 | `WFormDatePicker` |
| 复选 / 单选 | `WFormCheckbox` / `WFormRadioGroup` |
| 自定义字段按钮 | `WFormButton` |
| 边框 | `WFormBorder` / `WFormBorderConfig` |
| 校验 | `WFormValidator` / `WFormValidatorItem` / `WFormValidatorSettings` |

## License

MIT
