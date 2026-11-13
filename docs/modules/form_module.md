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
| 表单字段值选择 | `WFormButton` / `WFormFieldButton<T>` |
| 锚定弹层 | `WFormPopup` |
| 边框 | `WFormBorderStyle` / Flutter `BoxDecoration` |
| 校验 | `WFormValidator` / `WFormValidatorSettings` |

字段选择与反例以 [`docs/agents/form.md`](../agents/form.md) 为准。

## 模块结构

```text
packages/form/
├── lib/w_tools_form.dart                 # 公共 barrel
└── lib/src/components/
    ├── form_container.dart               # WForm
    ├── form_scope.dart / form_theme.dart # WFormScope / WFormTheme
    ├── form_controller.dart              # WFormController
    ├── direct_fields.dart                # 直接字段 + WFormFieldButton
    ├── field_assembly.dart               # 直接字段的公共装配（bordered / 只读 / name 校验）
    ├── field_frame.dart                  # 外框布局（内部）
    ├── border/                           # WFormBorder / Style / FieldShell / border_registry（内部）
    ├── fields/                           # WFormTextField / Dropdown / …（每个字段一个文件）
    ├── validation/                       # WFormValidator / CustomValidator
    ├── popup.dart                        # WFormPopup
    └── form_input_formatters.dart        # 输入格式化器
```

## 核心架构

```text
WForm
  └─ WFormTheme（边框样式 / 图标）
      └─ WFormFieldStyleScope（页面级字段默认样式）
          └─ WFormScope（formData）
              └─ FormBuilder（flutter_form_builder）
                  └─ WFormReadOnlyScope（整表只读）
                      └─ 直接字段
                          └─ WFormFieldShell（错误通道 + 字段级只读作用域）
                              └─ WFormBorder（装饰 / 错误与提示文案）
```

数据流：

1. 字段通过 `FormBuilderFieldState.didChange` 更新值；
2. 字段变化时清该字段的边框错误（`formEntered` 由字段值实时派生，不靠额外上报）；
3. `form.validate()` / `form.validators().validate()` 执行字段 validator 或 `WFormValidatorItem`；
4. 校验失败写边框错误，由 `WFormBorder` 渲染。

## 1. WFormScope — 表单容器

`WForm` 内部创建 `WFormScope`；只有自定义布局时才直接使用它。

- `WFormScope.of(context)` 取 `WFormController?`；
- `WFormScope.requireOf(context)` 取 controller，无祖先抛 `StateError`；
- `WFormScope.borderStyleOf(context)` 读取最近 `WFormThemeData.borderStyle`；
- `formData` 必须与字段子树共享同一个 controller；
- `WFormScope.formBorderStyle` 已删除，边框配置放 `WFormTheme(borderStyle:)` / `WForm(borderStyle:)`。

```dart
WFormTheme(
  borderStyle: WFormBorderStyle.fromTheme(Theme.of(context)),
  child: WFormScope(
    formData: form,
    child: Column(children: [WFormTextField(name: 'name', label: '姓名')]),
  ),
)
```

## 2. WFormController — 表单状态管理

`WFormController` 持有 `formKey`，提供值与输入状态、校验、边框错误联动。

| 成员 | 说明 |
|---|---|
| `value` / `savedValue` | 当前值 / 上次 `validate()` 或 `save()` 的快照 |
| `fields` | 字段集合；未挂载时为 null |
| `formEntered` | 各字段是否已输入的派生快照（每次调用返回独立副本，改它不影响表单） |
| `isAllEntered(names)` | 指定字段是否都已输入 |
| `setValue` | 程序化写值 + 清该字段边框错误；立刻反映到 `formEntered`；不要在字段自己的 `onChanged` 里回写同字段 |
| `clearError` | 只清该字段边框错误 |
| `getFieldsValue<T>` | 不 `save` 也能取即时值 |
| `validate({items})` | 一步校验；未挂载返回 false |
| `validators({settings, items})` | 创建 `WFormValidator` |
| `setError` / `clearError` | 驱动边框错误 |
| `reset()` / `clearValue` | 重置 / 清空 |
| `closeKeyboard()` | unfocus |

`formEntered` 判定：`String` / `Iterable` / `Map` 非空，`bool` 取自身，其它 `!= null`。
`WForm` 与 `WFormController` 必须一对一：同一个 controller 同时挂载两个 `WForm` 时，第二个不会构建 `FormBuilder`，而是显示可读的「重复挂载」提示（因此不会触发 `GlobalKey` 冲突）。

## 3. WFormTheme / WFormIcons — 表单主题

普通页面优先用 `WForm`，它内部创建主题与作用域；`WFormTheme` 用于自定义布局。

- 图标优先级：字段自身 icon 参数 > `WForm.icons`（或继承的 `WFormTheme.icons`）> `WFormIcons.defaults`。
- `WForm.icons` 只影响当前表单；App 统一放 `WFormTheme` 外层（6.0 起 `WForm` 会继承外层 `WFormTheme` 的图标）。
- `WFormTheme` / `WFormScope` 是低层可组合 API：普通页面用 `WForm`，需要 App 级统一或自定义布局时才在外层组合。
- 6.0 起 `WForm` / `WFormTheme` 不再接受单项 `xxxIcon` 参数：统一用 `WFormIcons` + `icons:`。
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
整表变化用 `WForm(onChanged:)`：任一字段 `didChange` 后回调拿到当前 `controller.value`，不必逐字段挂 `onChanged`。
页面级高度 / 内边距 / 文本样式用 `WForm.fieldStyle`，字段级差异用直接参数。
单字段样式覆盖用 `WFormFieldStyleScope`；宽度 / 偏移 / 自定义外框用外层布局包裹。

## 4. 边框系统

### 4.1 WFormBorderStyle

不可变边框配置，装饰值直接用 Flutter `BoxDecoration`（默认全部为 null，外观由调用方决定）。常用：

```dart
WFormBorderStyle.fromTheme(Theme.of(context));
WFormBorderStyle.standard(radius: 12);

const WFormBorderStyle(
  defaultDecoration: BoxDecoration(
    color: Colors.white,
    border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  ),
);
```

字段顺序：`errorDecoration` > `readOnlyDecoration` / `focusedDecoration` > `defaultDecoration`。
替换配置用 `copyWith`，不要原地 setter。

### 4.2 WFormFieldShell

注册 `WFormController` 的边框错误通道、注入 `WFormReadOnlyScope`。
需要输入框内部细节（`contentPadding` / `prefix` / `decoration`）时，用它包住
`flutter_form_builder` 字段；边框 / 错误 / 只读仍走同一套。

### 4.3 WFormReadOnlyScope

`InheritedWidget`，`WFormFieldShell` 始终插入；字段通过
`WFormReadOnlyScope.readOnlyOf(context)` 合并只读状态，可穿透任意包装。

## 5. 字段组件（直接用法 / 低层细节）

以下字段默认使用直接入口；`WForm*Config` / `*Core` 是包内实现，不作为页面 API。

### 5.1 WFormTextField

- 文本 / 密码；密码模式自动 `obscuringCharacter: '＊'` 与 `visiblePassword`。
- `actions` 支持 `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton` /
  `WFormTextFieldAction`；从 `WFormTheme.icons` 取图标。
- action 默认可聚焦，Enter / Space 触发；读屏标签用 `WFormTextFieldAction.semanticLabel`
  （密码切换用 `showSemanticLabel` / `hideSemanticLabel`，清空用 `semanticLabel`）。
- `inputFormatters` / `keyboardType` / `textAlign` / `maxLength` / `leading` 等用直接参数；`prefix` / `contentPadding` 这类输入框内部细节没有直接参数，按 §4.2 自定义字段组合。

```dart
WFormTextField(
  name: 'password',
  label: '密码',
  obscureText: true,
  actions: const [
    WFormTextFieldPasswordToggle(
      showSemanticLabel: '显示密码',
      hideSemanticLabel: '隐藏密码',
    ),
    WFormTextFieldClearButton(semanticLabel: '清空'),
  ],
)
```

### 5.2 WFormDropdown<T>

- `items: Map<T, String>`；初始值 / 字段值应存在于 items 中；不在 items 时界面不显示该值，但表单里仍保留原值。
- 字段级文字样式用 `style`，右侧图标尺寸用 `iconSize`；未传时分别取 `WForm.fieldStyle.textStyle` 与底层默认 24。
- `hintText` 优先于 `label` 作为占位。

### 5.3 WFormMultiDropdown<T>

- 值类型 `Set<T>`（enum / int 等非 String 值也可用）；通过 `WFormPopup` 在锚点下方弹出。
- `disabledKeys` 显示选中态但不可点击；已选项按选择先后拼接（`Set` 插入序，等价于点击顺序）。

### 5.4 WFormCheckbox

单选布尔值，`initialValue` 默认 `false`；`bordered` 默认 `false`（其余字段默认 `true`）；只读同时受 `enabled` 与 `WFormReadOnlyScope` 影响。
提示文案用 `message`（有边框时交给 hint / error builder；无边框时渲染在字段下方；与 `hintTextList` 二选一）。

### 5.5 WFormRadioGroup<T>

`items: Map<T, String>`，单列布局；`titleBuilder` / `itemExtraBuilder` 可定制每项，`lineSpacing` 控制行距；`bordered` 默认 `false`。
提示文案用 `message`（有边框时交给 hint / error builder；无边框时渲染在字段下方；与 `hintTextList` 二选一）。

### 5.6 WFormDatePicker

- 存储格式固定 ISO `yyyy-MM-dd`；显示格式用 `displayFormat`（默认 `yMMMMd`）。
- 初值可传 `initialValue`（ISO 字符串）或 `initialDate`（`DateTime`，自动转 ISO）；同时传时 `initialValue` 优先。
- 使用系统 `showDatePicker`；`firstDate` / `lastDate` 默认 `1900` / `2100`，需要收窄范围时显式传。
- 显示文案走 `intl`：需要中文月份 / 本地化文案时，宿主 `MaterialApp` 要挂
  `flutter_localizations`；未挂时回退 `en_US`（不崩，但显示英文月份）。

### 5.7 WFormButton

- 字段值选择器；点击行为由 `onTap(value, didChange)` 决定，选择后调用 `didChange`。
- `selectedWidgetBuilder` 渲染当前值；`hintWidget` 可替代 `label`。
- 普通按钮用 `WButton`，不要用 `WFormButton` 承担普通点击；`WFormButton` / `WFormFieldButton` 都支持 `message`（与 `hintTextList` 二选一）。
- 值类型：`WFormButton` 就是 `typedef WFormButton = WFormFieldButton<String>`（同一类型，String 用法不变）；enum / int 等用 `WFormFieldButton<T>`。

## 6. WFormPopup — 弹出层

锚定式弹层，不是居中确认框：

```dart
final value = await WFormPopup.show<String>(
  context: context,
  anchorContext: fieldKey.currentContext,
  builder: (context) => ...,
);
```

- 同一 Navigator 已有弹层时，release 忽略重复调用并返回已完成的 null Future；
  debug 下会断言报出，避免静默丢失；
- 空间不足自动向上翻转，位置只在打开时计算，滚动不跟随；
- `WFormPopup.hide<T>` 关闭并返回值；当前 Navigator 没有弹层时是 no-op（不会 pop 普通页面），`rootNavigator` 需与 `show` 一致。

## 7. 校验系统

`WFormValidator` 由 `WFormController.validators({settings, items})` 创建，按序执行。
每次 `validate()` 会先调用 `FormBuilderState.save()`：`savedValue` 与当前值同步，
字段声明的 `onSaved` 也会执行（即使校验失败）。
`items` 为 null 时与 `validate()` 一致：校验当前已挂载字段的自身 validator。
表单未挂载时：字段校验项 / 空校验项返回 false；纯自定义 `validatorBuilder` 仍可运行。

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
`WFormValidatorSettings` 不可变（`const` 构造 + `copyWith`），字段全部 `final`。

```dart
final validator = form.validators(
  settings: const WFormValidatorSettings(showBorderError: true),
  items: [
    WFormValidatorItem.field('email'),
    WFormValidatorItem(fieldName: 'password', validatorBuilder: () => (v) => ...),
  ],
);
if (!validator.validate()) return;
```

## 8. form_input_formatters.dart

- `WFormInputFormatters.hkPhone()`：香港号码，最多 8 位；
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
      borderStyle: WFormBorderStyle.fromTheme(Theme.of(context)),
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
- **边框**：默认 `WFormBorderStyle.fromTheme(Theme.of(context))`；不要手写 `WFormBorder`。
- **Controller 生命周期**：`WFormController` 由页面 State 持有即可；它没有 `dispose`，表单状态随 `WForm` 卸载。
- **校验设置**：`WForm.validatorSettings` 会成为 `validate()` / `validators()` 的默认值。
- **无边框字段**：`bordered: false` 时没有边框错误通道，`setError` 在 debug 会断言提示（release 为 no-op）；这类字段的错误从 `WFormValidator.errors` 读。
- **弹层**：`WFormPopup` 是锚定弹层，不用于居中确认框。

## 完整 API

- 用法与最小示例：[`packages/form/README.md`](../../packages/form/README.md)
- 字段规则与反例：[`docs/agents/form.md`](../agents/form.md)
- 组件目录：[`components.md`](components.md)
- 逐参数 API：[pub.dev API 文档](https://pub.dev/documentation/w_tools_form/latest/)
- 源码：[`packages/form/lib`](../../packages/form/lib)
