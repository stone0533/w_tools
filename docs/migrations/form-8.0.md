# form 8.0 迁移

> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

## 1. `WFormController.clearValue` 删除

`clearValue` 一律写 `null`，对 `bool` / `Set<T>` 这类非空类型语义不明确；8.0 起统一用
`resetValue` 回到字段自身的 `initialValue`。

```dart
// before
form.clearValue('agree');
form.clearValue('tags');

// after
form.resetValue('agree');
form.resetValue('tags');
```

可空文本字段若确实要清成 `null`，直接用 `setValue`：

```dart
form.setValue<String?>('bio', null);
```

## 2. `WFormController.formEntered` / `isAllEntered` 删除

「是否已输入」是业务规则，不再由 controller 维护。直接读 `value`，或用字段自己的
validator 表达 required。

```dart
// before
if (form.formEntered['email'] == true) { ... }
if (form.isAllEntered(['email', 'password'])) { ... }

// after
if (form.value['email'] case final String email when email.isNotEmpty) { ... }
// 多字段必填交给 validate()
if (!form.validate()) return;
```

## 3. `WFormController.closeKeyboard` 删除

键盘是 UI 关注点，直接操作焦点：

```dart
// before
form.closeKeyboard();

// after
FocusManager.instance.primaryFocus?.unfocus();
```

`WFormValidator.validate()` 仍会在校验前收起键盘。

## 4. `WFormCustomValidator` 删除

旧实现只是把一个 `String? Function(T?)` 包成 `FormFieldValidator<T>`；它内部继承
`BaseValidator` 并覆写 `validate`，唯一特殊之处是**绕开 `BaseValidator` 对空值的短路**。
字段的 `validator:` 原本就会收到 `null`，所以直接传闭包行为等价。

两个前提要记住：

1. **`value` 可能是 `null`**（空输入通常以 `null` 传入）。必填 / trim 等规则由闭包自己判断。
2. **`form_builder_validators` 不再是 `w_tools_form` 的依赖**。如果你的项目曾直接
   `import 'package:form_builder_validators/form_builder_validators.dart'`（靠传递依赖），
   升级 8.0 后需要在自己的 `pubspec.yaml` 显式添加；只使用 `w_tools_form` 的字段
   `validator:` 则不需要。

```dart
// before
WFormTextField(
  name: 'code',
  validator: WFormCustomValidator.custom<String>(
    validator: (value) => (value == null || value.isEmpty) ? '必填' : null,
  ),
);

// after：字段级直接传闭包
WFormTextField(
  name: 'code',
  validator: (value) => (value == null || value.isEmpty) ? '必填' : null,
);
```

表单级规则两种写法：

```dart
// 1) 复用字段自己声明的强类型 validator（推荐）
WFormTextField(
  name: 'code',
  validator: (value) => (value == null || value.isEmpty) ? '必填' : null,
);
form.validators(items: [WFormValidatorItem.field('code')]).validate();

// 2) 按运行期状态生成动态规则
form.validators(items: [
  WFormValidatorItem(
    fieldName: 'code',
    validatorBuilder: () => (value) =>
        (value == null || value.isEmpty) ? '必填' : null,
  ),
]).validate();
```

需要跨字段 / 多个页面复用规则时，在项目 UI 层封装普通函数（例如
`String? Function(String?)`），不要依赖已删除的包装类；示例见
[`packages/form/README.md`](../../packages/form/README.md) 的「自定义校验」。

## 5. `WFormInputFormatters` / `WCardNumberInputFormatter` / `WDividerInputFormatter` 删除

业务 / 地区格式化器不再由表单包提供；使用 Flutter 自带 formatter，或自己实现
`TextInputFormatter`。

```dart
// before
WFormTextField(
  name: 'phone',
  inputFormatters: WFormInputFormatters.hkPhone(),
);

// after
WFormTextField(
  name: 'phone',
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ],
);
```

需要分组显示时用 `TextInputFormatter.withFunction`，并处理 composing region 与非折叠选区。

## 6. `label` 弃用（9.0 删除）

`WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` 的 `label`
是历史占位符别名；8.0 起构造参数标 `@Deprecated`，请改用 `hintText`。
`WFormFieldButton.label` / `WFormButton.label` 不受影响。
注意：弃用标注在构造参数上；读取已构造对象的 `label` 字段不会触发 analyzer 提示，
请按本文迁移。
对应构造器：`WFormTextField.new` / `WFormDropdown.new` / `WFormMultiDropdown.new` /
`WFormDatePicker.new`。

```dart
// before
WFormTextField(name: 'email', label: '邮箱');

// after
WFormTextField(name: 'email', hintText: '邮箱');
```

## 7. `WFormPopup` 公开入口移除

`WFormPopup` / `WFormPopup.show` / `WFormPopup.hide` 从 8.0 起不再从
`package:w_tools_form/w_tools_form.dart` 导出；`WFormMultiDropdown` 的弹层仍由包内实现。
业务需要锚定弹层时用 Flutter 自带能力：

```dart
MenuAnchor(
  menuChildren: [
    MenuItemButton(onPressed: () {}, child: const Text('选项')),
  ],
  builder: (context, controller, child) => TextButton(
    onPressed: () => controller.open(),
    child: const Text('打开'),
  ),
);
```

需要自定义定位 / 跟随滚动时用 `OverlayPortal` + `CompositedTransformFollower`。

## 8. `WFormController.validatorSettings` 改为只读

默认校验设置只由 `WForm(validatorSettings:)` 注入；不再允许在 controller 上二次赋值。

```dart
// before
form.validatorSettings = const WFormValidatorSettings(showBorderError: true);

// after
WForm(
  controller: form,
  validatorSettings: const WFormValidatorSettings(showBorderError: true),
  child: ...,
);

// 只影响一次校验 / 临时 validator
form.validate(settings: const WFormValidatorSettings(showBorderError: true));
form.validators(settings: const WFormValidatorSettings(showBorderError: true));
```

## 9. `WFormBorder` / 自定义布局移除

`WFormBorder` / `WFormBorderLayout` / `WFormBorderLayoutData` / `columnBorderLayout`
从 8.0 起不再公开；边框由 `WFormFieldShell` 内部装配，自定义字段仍用：
`WFormFieldShell(name: ..., readOnly: ..., child: ...)`。
`WFormBorderStyle.layout` 同时删除；`WFormBorderStyle.new` / `WFormBorderStyle.copyWith` 不再接受
`layout`，布局固定为「边框在上、消息在下」。

```dart
// before
WFormBorder(
  style: WFormBorderStyle(layout: (context, data) => Row(children: [data.child, data.message])),
  child: ...,
);

// after
// 普通字段由 WForm 自动装配；自定义字段用 WFormFieldShell
WFormFieldShell(name: 'x', readOnly: false, child: ...);
```

## 10. 三个低层 scope 私有化

`WFormScope` / `WFormReadOnlyScope` / `WFormTextFieldScope` 从 8.0 起不再导出。

```dart
// before
final form = WFormScope.of(context);
final readOnly = WFormReadOnlyScope.readOnlyOf(context);
final data = WFormTextFieldScope.of(context);
final style = WFormScope.borderStyleOf(context);

// after
final form = WFormController.of(context);
final readOnly = WFormReadOnly.of(context);
final data = WFormTextFieldData.of(context);
final style = WFormThemeData.of(context)?.borderStyle;
```

## 11. `validate()` 不再隐式 `save()`

`WFormController.validate()` / `WFormValidator.validate()` 只校验当前值，不再调用
`FormBuilderState.save()`。需要 `savedValue` 或字段 `onSaved` 时显式调用 `form.save()`。

```dart
// before：validate() 会顺带 save()
if (!form.validate()) return;
final saved = form.savedValue;

// after
if (!form.validate()) return;
form.save();
final saved = form.savedValue;
```

## 12. `WFormDatePicker.initialDate` 删除

初值只接受 `initialValue`（ISO `yyyy-MM-dd` 字符串）；`DateTime` 先格式化。

```dart
// before
WFormDatePicker(name: 'birthday', initialDate: DateTime(1998, 6, 18));

// after
WFormDatePicker(name: 'birthday', initialValue: '1998-06-18');
```

## 13. `hintStyle` 改名

两个 `hintStyle` 含义不同，8.0 起改名，旧名保留到 9.0。
弃用标注在构造参数上；读取已构造对象的 `hintStyle` 字段不会触发 analyzer 提示，请按本文迁移。

- 字段占位符：`WFormFieldStyle.hintStyle` → `WFormFieldStyle.placeholderStyle`；
- 边框辅助文案：`WFormBorderStyle.hintStyle` → `WFormBorderStyle.helperStyle`。
  `WFormBorderStyle.standard` / `WFormBorderStyle.fromTheme` / `WFormBorderStyle.copyWith`
  都接受 `helperStyle`，旧 `hintStyle` 仍可用但已弃用。

```dart
// before
const WFormFieldStyle(hintStyle: TextStyle(color: Colors.grey));
WFormBorderStyle.fromTheme(theme, hintStyle: TextStyle(fontSize: 12));

// after
const WFormFieldStyle(placeholderStyle: TextStyle(color: Colors.grey));
WFormBorderStyle.fromTheme(theme, helperStyle: TextStyle(fontSize: 12));
```

## 14. 8.1 补充：`WFormFieldShell.new`

`WFormFieldShell.new` 的 `readOnly` 从必填改为可选，默认 `false`；这是源码兼容的签名放宽。
外层 `WForm(readOnly: true)` 仍然强制只读；子控件自身 `enabled: false` 时仍需显式传
`readOnly: true`，否则边框不会显示只读态。详见 `form-8.1.md`。
