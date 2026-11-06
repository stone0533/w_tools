# Form 模块文档

## 概述

Form 模块（`w_tools_form` 子包）基于 `flutter_form_builder`，提供 `WForm` 容器、直接字段、边框 / 校验 / 只读作用域与表单弹层。

> 本文只写**模块边界、架构与设计取舍**。
> 安装、最小用法与常用配方见 [`packages/form/README.md`](../../packages/form/README.md)；
> 字段选择与硬规则见 [`docs/agents/form.md`](../agents/form.md)；
> 逐参数 API 以 [pub.dev API 文档](https://pub.dev/documentation/w_tools_form/latest/) /
> `packages/form/lib` 源码为准。

**模块特点：**

- **直接字段优先**：新页面用 `WForm` + `WFormTextField` 等直接字段，不从 `Config.build` 开始。
- **页面级统一**：高度 / 内边距 / 文本样式用 `WForm.fieldStyle`，边框 / 校验 / 只读由 `WForm` 统一提供。
- **底层 Config 不导出**：字段 Config 与 `*Core` 是包内实现，业务代码不要 import `src/` 或实例化 Config。

## 快速判断

| 需求 | 入口 |
|---|---|
| 页面表单容器 | `WForm` |
| 表单状态 / 校验 | `WFormController` |
| 文本 / 密码 | `WFormTextField` |
| 下拉 | `WFormDropdown<T>` |
| 多选 | `WFormMultiDropdown` |
| 日期 | `WFormDatePicker` |
| 复选 / 单选 | `WFormCheckbox` / `WFormRadioGroup<T>` |
| 表单字段值选择 | `WFormButton` |
| 锚定弹层 | `WFormPopup` |
| 边框 | `WFormBorderConfig` / `WFormBorderDecoration` |
| 校验 | `WFormValidator` / `WFormValidatorSettings` |

字段选择与反例以 [`docs/agents/form.md`](../agents/form.md) 为准。

## 模块结构

```text
packages/form/
├── w_tools_form.dart                # 公共 barrel
└── lib/src/
    ├── form/                        # WForm / WFormScope / WFormTheme
    ├── controller/                  # WFormController / WFormValidator
    ├── border/                      # WFormBorder / Decoration / Config / FieldShell
    ├── components/fields/           # 直接字段
    ├── popup/                       # WFormPopup
    └── formatters/                  # WFormInputFormatters
```

## 核心架构

```text
WForm
  └─ WFormTheme（边框 / 图标）
      └─ WFormScope（formData + formBorderConfig）
          └─ FormBuilder（flutter_form_builder）
              └─ 直接字段
                  └─ WFormFieldShell（边框 key + 只读作用域）
```

数据流：

1. 字段通过 `FormBuilderFieldState.didChange` 更新值；
2. `WFormController.handleChange` 更新 `formEntered` / 清错误；
3. `form.validate()` / `form.validators().validate()` 执行字段 validator 或 `WFormValidatorItem`；
4. 校验失败写边框错误，由 `WFormBorder` 渲染。

## 1. WFormScope — 表单容器

`WForm` 内部创建 `WFormScope`；只有自定义布局时才直接使用它。

- `WFormScope.of(context)` 取 `WFormController?`；
- `WFormScope.requireOf(context)` 取 controller，无祖先抛 `StateError`；
- `WFormScope.borderConfigOf(context)` 取当前边框配置；
- `formData` 必须与字段子树共享同一个 controller。

```dart
WFormScope(
  formData: form,
  formBorderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
  child: Column(children: [WFormTextField(name: 'name', label: '姓名')]),
)
```

## 2. WFormController — 表单状态管理

`WFormController` 持有 `formKey`，提供值与输入状态、校验、边框错误联动。

| 成员 | 说明 |
|---|---|
| `value` / `fields` | 当前值 / 字段集合；未挂载时为空 |
| `formEntered` | 各字段是否已输入 |
| `updateValue<T>` | 写值 + 更新 `formEntered`；业务优先用这个 |
| `setValue` / `handleChange` | 只写值 / 只更新输入状态与错误 |
| `getFieldsValue<T>` | 不 `save` 也能取即时值 |
| `validate({items})` | 一步校验；未挂载返回 false |
| `validators({settings, items})` | 创建 `WFormValidator` |
| `setError` / `clearError` | 驱动边框错误 |
| `reset()` / `clearValue` | 重置 / 清空 |
| `closeKeyboard()` | unfocus |

`formEntered` 判定：`String` / `Iterable` / `Map` 非空，`bool` 取自身，其它 `!= null`。
`WForm` 与 `WFormController` 建议一对一；多个 `WForm` 共用 controller 时后挂载的会覆盖默认校验设置。

## 3. WFormTheme / WFormIcons — 表单主题

普通页面优先用 `WForm`，它内部创建主题与作用域；`WFormTheme` 用于自定义布局。

- 图标优先级：字段 `xxxIcon` > `WFormTheme.icons` / `WForm.icons` > `WFormIcons.defaults`。
- `WForm.icons` 只影响当前表单；App 统一放 `WFormTheme` 外层。
- `WFormDefaults` 已在 4.0 删除。

### WFormIcons — 图标集合

不可变图标集合，用 `copyWith` 替换需要的项：

```dart
WForm(
  icons: WFormIcons.defaults.copyWith(
    dropdown: const Icon(Icons.expand_more),
    checkboxSelected: const Icon(Icons.check_circle),
  ),
  controller: form,
  child: ...,
)
```

## 3.6 直接字段与 WForm

**主入口**。`WForm` 统一组合主题、表单作用域与只读作用域：

```dart
WForm(
  controller: form,
  borderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
  fieldStyle: const WFormFieldStyle(height: 52),
  child: Column(
    children: [
      WFormTextField(
        name: 'email',
        label: '邮箱',
        validator: (v) => (v?.isEmpty ?? true) ? '请输入邮箱' : null,
      ),
      WFormDropdown<String>(
        name: 'country',
        label: '国家 / 地区',
        items: const {'CN': '中国大陆', 'HK': '中国香港'},
      ),
      WFormButton(
        name: 'coupon',
        label: '选择优惠券',
        onTap: (_, didChange) {},
      ),
    ],
  ),
)
```

字段不接受 `config`；不要写 `WFormTextField(config: ...)`，也不要 `Config.build(...)`。
页面级高度 / 内边距 / 文本样式用 `WForm.fieldStyle`，字段级差异用直接参数。
单字段样式覆盖用 `WFormFieldStyleScope`；宽度 / 偏移 / 自定义外框用外层布局包裹。

## 4. 边框系统

### 4.1 WFormBorderDecoration

不可变边框 / 背景 / 圆角 / 阴影 / 渐变样式，支持链式扩展：

```dart
const WFormBorderDecoration()
    .withUniformBorder(1, Colors.grey)
    .withUniformBorderRadius(8)
    .withColor(Colors.white);
```

### 4.2 WFormBorderConfig

不可变边框配置，默认全部为 null（外观由调用方决定）。常用：

```dart
WFormBorderConfig.fromTheme(Theme.of(context));
WFormBorderConfig.standard(radius: 12);
```

字段顺序：`errorDecoration` > `readOnlyDecoration` / `focusedDecoration` > `defaultDecoration`。
替换配置用 `copyWith`，不要原地 setter。

### 4.3 WFormFieldShell

自动绑定 `WFormController` 的边框 key、注入 `WFormReadOnlyScope`。
需要输入框内部细节（`contentPadding` / `prefix` / `decoration`）时，用它包住
`flutter_form_builder` 字段；边框 / 错误 / 只读仍走同一套。

### 4.4 WFormReadOnlyScope

`InheritedWidget`，`WFormFieldShell` 始终插入；字段通过
`WFormReadOnlyScope.readOnlyOf(context)` 合并只读状态，可穿透任意包装。

## 5. 字段组件（直接用法 / 低层细节）

以下字段默认使用直接入口；`WForm*Config` / `*Core` 是包内实现，不作为页面 API。

### 5.1 WFormTextField

- 文本 / 密码；密码模式自动 `obscuringCharacter: '＊'` 与 `visiblePassword`。
- `actions` 支持 `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton` /
  `WFormTextFieldAction`；从 `WFormTheme.icons` 取图标。
- `inputFormatters` / `keyboardType` / `textAlign` / `leading` 等用直接参数。

```dart
WFormTextField(
  name: 'password',
  label: '密码',
  obscureText: true,
  actions: const [WFormTextFieldPasswordToggle()],
)
```

### 5.2 WFormDropdown<T>

- `items: Map<T, String>`；初始值 / 字段值必须存在于 items 中。
- `hintText` 优先于 `label` 作为占位。

### 5.3 WFormMultiDropdown

- 值类型 `Set<String>`；通过 `WFormPopup` 在锚点下方弹出。
- `disabledKeys` 显示选中态但不可点击；已选项按选中顺序拼接。

### 5.4 WFormCheckbox

单选布尔值，`initialValue` 默认 `false`；只读同时受 `enabled` 与 `WFormReadOnlyScope` 影响。

### 5.5 WFormRadioGroup<T>

`items: Map<T, String>`，单列布局；`titleBuilder` / `itemExtraBuilder` 可定制每项，`lineSpacing` 控制行距。

### 5.6 WFormDatePicker

- 存储格式固定 ISO `yyyy-MM-dd`；显示格式用 `displayFormat`（默认 `yMMMMd`）。
- 使用系统 `showDatePicker`；`firstDate` / `lastDate` 默认 `1900` / `now`，建议显式传。

### 5.7 WFormButton

- 字段值选择器；点击行为由 `onTap(value, didChange)` 决定，选择后调用 `didChange`。
- `selectedWidgetBuilder` 渲染当前值；`hintWidget` 可替代 `label`。
- 普通按钮用 `WButton`，不要用 `WFormButton` 承担普通点击。

## 6. WFormPopup — 弹出层

锚定式弹层，不是居中确认框：

```dart
final value = await WFormPopup.show<String>(
  context: context,
  anchorContext: fieldKey.currentContext,
  builder: (context) => ...,
);
```

- 同一 Navigator 已有弹层时忽略重复调用；
- 空间不足自动向上翻转，位置只在打开时计算，滚动不跟随；
- `WFormPopup.hide<T>` 关闭并返回值。

## 7. 校验系统

`WFormValidator` 由 `WFormController.validators({settings, items})` 创建，按序执行。

### WFormValidatorItem

| 构造 | 说明 |
|---|---|
| `WFormValidatorItem.field(name)` | 使用字段自身 validator |
| `WFormValidatorItem(fieldName:, validatorBuilder:)` | 自定义校验；每次校验生成规则 |

### WFormValidatorSettings（默认值）

| 字段 | 默认 | 说明 |
|---|---|---|
| `showBorderError` | false | 是否渲染边框错误 |
| `continueOnError` | false | true 全量校验，false 短路 |
| `notifyAllErrors` | false | 是否对所有失败项触发回调 |
| `customErrorCallback` | null | `(fieldName, errorText)` |
| `itemValidationCallback` | null | 每项结果回调 |
| `shouldSkipValidation` | null | 返回 true 跳过该项 |

`WFormValidator.errors` 是只读错误快照，每次 `validate()` 重新填充。

```dart
final validator = form.validators(
  settings: WFormValidatorSettings()..showBorderError = true,
  items: [
    WFormValidatorItem.field('email'),
    WFormValidatorItem(fieldName: 'password', validatorBuilder: () => (v) => ...),
  ],
);
if (!validator.validate()) return;
```

## 8. form_input_formatters.dart

- `WFormInputFormatters.phone()`：香港号码，最多 8 位；
- `WCardNumberInputFormatter`：每 4 位加空格；
- `WDividerInputFormatter({first, rear, pattern})`：自定义分段。

`FilteringTextInputFormatter` / `LengthLimitingTextInputFormatter` 来自 `flutter/services`，不是本包提供。

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = WFormController();

  @override
  Widget build(BuildContext context) {
    return WForm(
      controller: form,
      borderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
      child: Column(
        children: [
          WFormTextField(name: 'email', label: '邮箱'),
          WFormTextField(
            name: 'password',
            label: '密码',
            obscureText: true,
            actions: const [WFormTextFieldPasswordToggle()],
          ),
          WFormButton(
            name: 'coupon',
            label: '选择优惠券',
            onTap: (_, didChange) {},
          ),
        ],
      ),
    );
  }
}
```

## 注意事项

- **不要从 Config 开始**：字段 Config / `*Core` 是包内实现；页面统一 `WForm` + 直接字段。
- **只读**：整页 `WForm(readOnly: true)`；单字段用字段的 `readOnly`，不要手写只读作用域。
- **边框**：默认 `WFormBorderConfig.fromTheme(Theme.of(context))`；不要手写 `WFormBorder`。
- **Controller 生命周期**：`WFormController` 由页面 State 持有即可；它没有 `dispose`，表单状态随 `WForm` 卸载。
- **校验设置**：`WForm.validatorSettings` 会成为 `validate()` / `validators()` 的默认值。
- **弹层**：`WFormPopup` 是锚定弹层，不用于居中确认框。

## 完整 API

- 用法与最小示例：[`packages/form/README.md`](../../packages/form/README.md)
- 字段规则与反例：[`docs/agents/form.md`](../agents/form.md)
- 组件目录：[`components.md`](components.md)
- 逐参数 API：[pub.dev API 文档](https://pub.dev/documentation/w_tools_form/latest/)
- 源码：[`packages/form/lib`](../../packages/form/lib)
