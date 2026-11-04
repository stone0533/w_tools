> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# form 5.0 迁移预告：移除可变字段 Config

4.2.0 起以下类型标记 deprecated，form 5.0 移除：

```text
WFormFieldBaseConfig
WFormTextFieldConfig
WFormDropdownConfig
WFormDatePickerConfig
WFormCheckboxConfig
WFormRadioGroupConfig
WFormMultiDropdownConfig
WFormFieldButtonConfig
```

迁移：

```dart
// before
WFormTextField(config: WFormTextFieldConfig()..height = 52, name: 'email')

// after
WFormTextField(name: 'email') // 用直接字段参数 / WFormFieldStyle
```

`WFormBorderConfig` 是不可变值对象，不在本迁移内。
