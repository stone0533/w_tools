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

- `WFormBorderConfigScope`：用 `WForm(borderConfig:)` / `WFormTheme(borderConfig:)`；
- `WFormBorderState`：`WFormController.formBorderKeys` / `ensureBorderKey` /
  `removeBorderKey` 标为内部；业务侧用 `form.setError` / `form.clearError`；
- `WFormPopupRoute`：用 `WFormPopup.show` / `WFormPopup.hide`。

自定义字段仍用公开的 `WFormFieldShell` + `flutter_form_builder` 组合（见
[form_module.md §4.3](../modules/form_module.md)）。

## 3. 字段按钮

`WFormButton` 保持原 String API，等价于 `WFormFieldButton<String>`，String 用法不变。
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

- `WFormController.formBorderKeys` / `WFormController.ensureBorderKey` / `WFormController.removeBorderKey` 不再公开：
  边框 key 由包内 `border_registry.dart` 管理；需要判断字段是否有边框时用
  `hasBorder(name)`（`@internal`）。
- `WFormController.formEntered` 改为只读视图：写入请用 `handleChange(name, value)` /
  `updateValue(name, value)`。
- `WFormValidatorItem` 的 `fieldName` / `validatorBuilder` / `autofocus` 构造后不可变。

## 6. `bordered: false` 的校验

`bordered: false` 的字段没有边框位置，`validate()` 失败时不会绘制错误，
也不会再触发 debug 断言；错误从 `WFormValidator.errors` 读取。
