# form 7.0 迁移

> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

## 1. `WFormController.borders` 不再公开

`WFormController` 不再暴露边框错误通道，`WFormBorderRegistry` 仍是包内实现。

```dart
// before（7.0 前，仅包内 / 测试使用）
form.borders.has('email');
form.borders.channelOf('email');

// after
form.setError('email', errorTextList: const ['必填']);
form.clearError('email');
```

业务侧不要直接操作通道；需要判断是否有错误时，读 `WFormValidator.errors`。

## 2. `WFormInputFormatters` 不再可实例化，`phone()` 删除

该类是纯静态工厂，7.0 起不能实例化；旧 `phone()` 也已到期删除。

```dart
// before
WFormInputFormatters().hkPhone();
WFormInputFormatters.phone();

// after
WFormInputFormatters.hkPhone();
```

## 3. `WFormValidatorSettings.copy()` 删除

```dart
// before
final next = settings.copy();

// after
final next = settings.copyWith();
```

## 4. 边框装饰改用 `BoxDecoration`

`WFormBorderDecoration` 与 `WFormBorderDecorationExtension` 删除；
`WFormBorderStyle` 的装饰字段 / `copyWith` 参数直接接收 Flutter `BoxDecoration`。

```dart
// before
const WFormBorderStyle(
  defaultDecoration: WFormBorderDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
);

// after
const WFormBorderStyle(
  defaultDecoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
);
```

链式方法改为 `BoxDecoration.copyWith` / 直接构造；`BoxDecoration` 本身支持
`border` / `color` / `borderRadius` / `boxShadow` / `gradient`。

## 5. `WFormScope.formBorderStyle` 删除，`WFormBorder` 要求显式 style

边框样式统一由 `WFormThemeData.borderStyle` 提供：

```dart
// before
WFormScope(
  formData: form,
  formBorderStyle: WFormBorderStyle.fromTheme(Theme.of(context)),
  child: ...,
);

// after
WFormTheme(
  borderStyle: WFormBorderStyle.fromTheme(Theme.of(context)),
  child: WFormScope(formData: form, child: ...),
);
```

`WFormScope.formBorderStyle` 在 7.0 删除。
直接使用 `WFormBorder` 时不再读取主题，需要显式传 `style`：

```dart
WFormBorder(style: WFormBorderStyle.fromTheme(Theme.of(context)), child: ...);
```

## 6. `WFormMultiDropdown` 泛型化

`WFormMultiDropdown` 改为 `WFormMultiDropdown<T>`，字段值是 `Set<T>`：

```dart
// before
WFormMultiDropdown(
  name: 'tags',
  items: const {'a': 'A'},
  initialValue: const {'a'},
);

// after（String 用法可由 items 推断）
const WFormMultiDropdown<String>(
  name: 'tags',
  items: {'a': 'A'},
  initialValue: {'a'},
);

// enum / int
WFormMultiDropdown<int>(
  name: 'levels',
  items: const {1: '一级', 2: '二级'},
  initialValue: const {1},
);
```

`WFormMultiDropdownCore` 仍是包内实现，不导出。

## 7. `WFormController` 值 API 收敛

`updateValue` / `handleChange` 删除，`setValue` 现在同时清除该字段的边框错误。

```dart
// before
form.updateValue('email', 'a@b.com');
form.handleChange('email', null);

// after
form.setValue('email', 'a@b.com'); // 写值 + 清错
form.clearError('email');          // 只清错
```

> **不要在字段自己的 `onChanged` 里 `setValue` 同字段。**  
> 字段值已由 FormBuilder 更新，`onChanged` 里再回写会形成
> `didChange → onChanged → setValue → didChange` 的闭环；7.0.1 起同值回写会 no-op，
> 但这不是推荐写法。`setValue` 只用于程序化改值。

`formEntered` 仍按字段值实时派生；自定义字段不需要再额外上报。

## 8. 本版同时包含 6.x 的新增能力

- `WFormTextField.textAlign` / `maxLength`
- `WFormDropdown.style` / `iconSize`
- `WFormDatePicker.initialDate`
- `WFormTextFieldAction.semanticLabel` / `semanticLabelBuilder`
- `WFormTextFieldPasswordToggle.showSemanticLabel` / `hideSemanticLabel`
- `WFormTextFieldClearButton.semanticLabel`

这些是 additive，不需要迁移；旧代码不受影响。
