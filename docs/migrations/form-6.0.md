# form 6.0 迁移

> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

## 1. 单项图标参数移除

`WForm` / `WFormTheme` 不再接受 `dropdownIcon` / `radioUnselectedIcon` /
`radioSelectedIcon` / `checkboxUnselectedIcon` / `checkboxSelectedIcon` /
`obscureTextIcon` / `obscureTextVisibleIcon` / `clearButtonIcon`。

```dart
// before
WForm(
  controller: form,
  dropdownColor: null,
  dropdownIcon: const Icon(Icons.expand_more),
  child: ...,
)

// after
WForm(
  controller: form,
  icons: const WFormIcons(dropdown: Icon(Icons.expand_more)),
  child: ...,
)
```

App 级统一图标仍然放在外层 `WFormTheme.icons`，`WForm` 会继承。
字段自身的 icon 参数（如 `WFormDropdown.icon`、`WFormCheckbox.selectedIcon`）保持不变。

## 2. 内部类型不再导出

以下类型不再从 `package:w_tools_form/w_tools_form.dart` 导出：

- `WFormBorderStyleScope`：用 `WForm(borderStyle:)` / `WFormTheme(borderStyle:)`；
- `WFormBorderState`：`WFormController.formBorderKeys` / `ensureBorderKey` /
  `removeBorderKey` 标为内部；业务侧用 `form.setError` / `form.clearError`；
- `WFormPopupRoute`：用 `WFormPopup.show` / `WFormPopup.hide`。

自定义字段仍用公开的 `WFormFieldShell` + `flutter_form_builder` 组合（见
[form_module.md §4.3](../modules/form_module.md)）。

## 3. 字段按钮

`WFormButton` 现在是 `typedef WFormButton = WFormFieldButton<String>`：String 用法的参数与行为不变，
但**不再是独立类型**——`find.byType(WFormButton)` / `is WFormButton` 都会落到
`WFormFieldButton<String>`，`WFormButton.new` 等成员名在 API 快照里随之消失。
需要 enum / int 值时直接用泛型：

```dart
WFormFieldButton<int>(
  name: 'level',
  label: '选择等级',
  onTap: (value, didChange) => didChange(3),
)
```

## 4. 行为变化

- `WFormController.validators()` 不传 `items` 时校验全部已挂载字段；
- `WFormPopup.hide` 在没有弹层时是 no-op（不会 pop 普通页面）；
- `bordered: false` 字段调用 `setError` 在 debug 断言提示；
- `message` 与 `hintTextList` 同时传会在 debug 断言；
- 同一个 `WFormController` 被两个 `WForm` 同时挂载时，第二个显示可读的重复挂载提示。

## 5. 控制器与校验项的可见性收口

- `WFormController.formBorderKeys` / `WFormController.ensureBorderKey` / `WFormController.removeBorderKey`
  不再公开：边框登记与错误通道由包内 `WFormBorderRegistry`（`border/border_registry.dart`）维护。
  同版删除 `errorChannelOf` / `removeErrorChannel` / `registerBorder` / `unregisterBorder` / `hasBorder`；
  业务侧只用 `setError` / `clearError`。
- `WFormController.formEntered` 改为**按字段值实时派生的快照**：没有需要手工写入的输入状态，
  `setValue` / `updateValue` 都会立即反映。同版删除兼容 no-op `pruneFormEntered` / `removeFormEntered`。
- `WFormValidatorItem` 的 `fieldName` / `validatorBuilder` / `autofocus` 构造后不可变。

## 6. `bordered: false` 的校验

`bordered: false` 的字段没有边框位置，`validate()` 失败时不会绘制错误，
也不会再触发 debug 断言；错误从 `WFormValidator.errors` 读取。

## 7. `WFormBorderConfig` → `WFormBorderStyle`

边框配置是不可变视觉样式（装饰 / hint / error / 布局），按 `docs/naming.md` §3.3 属
`Style` 而不是 `Config`；同时删掉零调用的公开装配入口 `build()` 与重复的 `copy()`。

| 旧 | 新 |
|---|---|
| `WFormBorderConfig` | `WFormBorderStyle` |
| `WFormBorderConfig.standard()` / `.fromTheme()` | `WFormBorderStyle.standard()` / `.fromTheme()` |
| `WForm(borderConfig: ...)` | `WForm(borderStyle: ...)` |
| `WFormTheme(borderConfig: ...)` | `WFormTheme(borderStyle: ...)` |
| `WFormScope.formBorderConfig` | `WFormScope.formBorderStyle` |
| `WFormScope.borderConfigOf(context)` | `WFormScope.borderStyleOf(context)` |
| `WFormBorder(config: ...)` | `WFormBorder(style: ...)` |
| `WFormBorderState.config` | `WFormBorderState.style` |
| `WFormBorderConfig.build(child: ...)` | 删除（用 `WFormBorder(style: ...)`） |
| `WFormBorderConfig.copy()` | 删除（用 `copyWith()`） |

精确符号变更（旧 → 新）：

- `WFormBorderConfig` → `WFormBorderStyle`
- `WFormBorderConfig.standard` / `WFormBorderConfig.fromTheme` → `WFormBorderStyle.standard` / `.fromTheme`
- `WForm.borderConfig` → `WForm.borderStyle`
- `WFormTheme.borderConfig` → `WFormTheme.borderStyle`
- `WFormBorder.new`：命名参数 `config` → `style`
- `WFormBorder.config` → `WFormBorder.style`
- `WFormScope.formBorderConfig` → `WFormScope.formBorderStyle`
- `WFormScope.borderConfigOf` → `WFormScope.borderStyleOf`
- `WFormBorderConfigScope` → `WFormBorderStyleScope`（仍未导出）
- `WFormBorderConfigScope.new` / `WFormBorderConfigScope.config` / `WFormBorderConfigScope.maybeOf` / `WFormBorderConfigScope.updateShouldNotify` 随作用域类一起改名
- `WFormBorderConfig.build`、`WFormBorderConfig.copy` 删除（零调用；用 `WFormBorder(style: ...)` / `copyWith()`）
