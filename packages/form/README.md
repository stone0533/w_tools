# w_tools_form

[![pub package](https://img.shields.io/pub/v/w_tools_form.svg)](https://pub.dev/packages/w_tools_form)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_form` 是 w_tools 的表单层，提供输入框、下拉、日期、单选复选等字段组件，以及表单构建器、边框、弹窗与字段级校验能力。

## 特性

- **字段组件**：`WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`
- **表单容器**：`WFormBuilder` / `WFormData` / `WFormButton`
- **边框体系**：`WFormBorder` / `WFormBorderConfig` / `WFormBorderWithData` / `WFormReadOnlyScope`
- **校验**：`WFormValidator` / `WFormValidatorItem` / `WFormCustomValidator`
- **默认值与格式化**：`WFormDefaults` / `WInputFormatters`

## 安装

```yaml
dependencies:
  w_tools_form: ^1.0.0
```

> 本包最低要求 Flutter 3.38.0（由 `flutter_form_builder` / `form_builder_validators` 依赖约束）。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

class LoginForm extends StatelessWidget {
  LoginForm({super.key});

  final formData = WFormData();

  @override
  Widget build(BuildContext context) {
    return WFormBuilder(
      formData: formData,
      child: Column(
        children: [
          WFormTextField(
            name: 'email',
            config: WFormTextFieldConfig(),
            hintText: '邮箱',
          ),
          WFormTextField(
            name: 'password',
            config: WFormTextFieldConfig()..obscureText = true,
            hintText: '密码',
          ),
        ],
      ),
    );
  }
}
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 表单构建 | `WFormBuilder` / `WFormData` |
| 文本 / 密码 | `WFormTextField` / `WFormTextFieldConfig` |
| 下拉 | `WFormDropdown` / `WFormMultiDropdown` |
| 日期 | `WFormDatePicker` |
| 复选 / 单选 | `WFormCheckbox` / `WFormRadioGroup` |
| 边框 | `WFormBorder` / `WFormBorderConfig` |
| 校验 | `WFormValidator` / `WFormValidatorItem` |

## License

MIT
