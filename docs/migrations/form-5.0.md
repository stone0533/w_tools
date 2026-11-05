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

## 能力对照

| 4.x Config 能力 | 5.0 做法 |
|---|---|
| `height` / `containerPadding` | `WForm.fieldStyle`，单字段用 `WFormFieldStyleScope` |
| `textStyle` / `hintStyle` | 同上（`WFormFieldStyle` 只有这两项文字样式） |
| `leading` / `actions` | 7 个直接字段都有同名参数 |
| `enabled` / `readOnly` / `bordered` | 直接字段同名参数 |
| `hintText` / `decoration.hintText` | 直接字段 `hintText`（优先）/ `label` |
| 各字段专有项（`items` / `displayFormat` / `disabledKeys` / `icon` …） | 直接字段同名参数 |
| `containerDecoration` / `containerMargin` / `width` / `yOffset` | 外框级需求：用外层 `Container` / `SizedBox` / `Transform` 包裹 |
| `contentPadding` / `prefix` / `prefixIcon` / `textAlign` / `readOnlyStyle` | 输入框内部细节：用自定义字段组合（见下节） |

## 需要输入框内部细节时：自定义字段

直接字段之外，`WFormFieldShell` 与 `flutter_form_builder` 都是公开导出的，
可以在 `WForm` 里组合出与内置字段一致的边框 / 错误 / 只读行为：

```dart
WFormFieldShell(
  name: 'amount',
  readOnly: false,
  child: FormBuilderField<String>(
    name: 'amount',
    validator: (value) => (value ?? '').isEmpty ? '请输入金额' : null,
    builder: (field) => TextField(
      textAlign: TextAlign.right,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        prefixIcon: Icon(Icons.attach_money),
      ),
      onChanged: field.didChange,
    ),
  ),
)
```

`FormBuilderField` 已由 `package:w_tools_form/w_tools_form.dart` 导出，不需要额外声明依赖；
如果你本来就依赖 `flutter_form_builder`，也可以直接用 `FormBuilderTextField`。

适用：`contentPadding` / `prefix` / `prefixIcon` / `textAlign` / 自定义 `decoration`。
注意：`WFormFieldShell.name` 必须与内层字段 `name` 一致，校验红框才会联动。

`WFormBorderConfig` 是不可变值对象，不在本迁移内。
