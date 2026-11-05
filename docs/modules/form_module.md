# Form 模块文档

## 概述

Form 模块（`w_tools_form` 子包）提供了一套基于 `flutter_form_builder` 的表单构建方案，包含表单容器、字段组件（文本 / 下拉 / 多选 / 复选 / 单选 / 日期 / 按钮）、统一边框系统、只读作用域、弹出层与校验器工厂。

**强依赖**：
- [`flutter_form_builder`](https://pub.dev/packages/flutter_form_builder)（表单内核，10.3.0+2 起锁定最低 Flutter 3.38）
- [`form_builder_validators`](https://pub.dev/packages/form_builder_validators)（可选校验器集合，11.3.0 起锁定最低 Flutter 3.38）
- `intl`（日期格式化，由 `DateFormat` 使用）

**最低 Flutter 版本**：3.38（由 `flutter_form_builder` / `form_builder_validators` 传递约束）


> **默认边框（3.0.0+）**：`WForm` 不传 `borderConfig` 时使用
> `WFormBorderConfig.fromTheme(Theme.of(context))`；字段有主题边框，`message` 与校验错误默认可见。
> 显式传 `const WFormBorderConfig()` 可关闭外观与文案。
>
> **Config / Core 是包内实现**：本文后面出现的 `WForm*Config`、`WForm*Core` 仅用于说明内部结构，
> 不从 `w_tools_form.dart` 导出，业务代码不要 import `src/`。

## 快速判断
- 页面表单 → `WForm` + 直接字段
- 校验 → 字段 `validator` + `WFormValidatorSettings`
- 特殊样式 → 直接字段参数或 `WForm.fieldStyle`
- 不要从 `WFormTextFieldConfig().build(...)` 开始（5.0 起 Config 只作为内部实现）
- 可运行示例：[packages/form/example](../../packages/form/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

---

## 模块结构

> `flutter_form_builder` 是**公开依赖**：`WFormController.formKey` / `fields` 的静态类型，
> 以及自定义字段的基类都来自它；核心类型已由 `package:w_tools_form/w_tools_form.dart` 导出。


```
form/
├── w_tools_form.dart
└── lib/src/
    ├── components/
    │   ├── form_scope.dart
    │   ├── form_controller.dart
    │   ├── form_defaults.dart
    │   ├── form_input_formatters.dart
    │   ├── field_button.dart
    │   ├── field_lifecycle.dart     # 无状态字段的 formEntered 清理包装
    │   ├── popup.dart
    │   ├── border/
    │   │   ├── border.dart          # WFormBorder + WFormBorderConfig + WFormBorderDecoration
    │   │   ├── border_layout.dart   # 边框与消息的布局策略（column / row / 内联等）
    │   │   ├── field_shell.dart # WFormFieldShell + Row 扩展
    │   │   └── read_only_scope.dart # WFormReadOnlyScope（InheritedWidget）
    │   ├── validation/
    │   │   ├── validator.dart       # WFormValidator + WFormValidatorItem + WFormValidatorSettings
    │   │   └── custom_validator.dart
    │   └── fields/
    │       ├── text_field.dart       # WFormTextField + WFormTextFieldConfig + Scope 管道
    │       ├── text_field_actions.dart # WFormTextFieldAction / PasswordToggle / ClearButton
    │       ├── dropdown.dart         # WFormDropdown + WFormDropdownConfig
    │       ├── multi_dropdown.dart   # WFormMultiDropdown
    │       ├── multi_dropdown_field.dart  # 内部字段实现
    │       ├── multi_dropdown_item.dart   # 选项项
    │       ├── multi_dropdown_config.dart # WFormMultiDropdownConfig
    │       ├── checkbox.dart         # WFormCheckbox + WFormCheckboxConfig
    │       ├── radio_group.dart      # WFormRadioGroup + WFormRadioGroupConfig
    │       └── date_picker.dart      # WFormDatePicker + WFormDatePickerConfig
```

---

## 核心架构

```
WFormScope (StatelessWidget)
  └─ _WFormControllerInherited (InheritedWidget)
      ├─ formData: WFormController
      └─ formBorderConfig: WFormBorderConfig?
          └─ FormBuilder (flutter_form_builder)
              └─ [各字段组件]
                  └─ WFormFieldShell（绑定 formData.formBorderKeys[name]）
                      ├─ 自动注入 WFormReadOnlyScope
                      └─ WFormBorder（边框绘制 + 错误展示）

WFormValidator
  └─ WFormController.validators({config, items}) 工厂创建
      └─ 按序执行 WFormValidatorItem 列表
```

### 数据流

1. `WFormScope.of(context)` 拿到 `WFormController`
2. 字段通过 `FormBuilderFieldState.didChange` → `WFormController.handleChange` 更新 `formEntered`
3. 校验失败时 `WFormController.setError(name)` 命中 `formBorderKeys[name]` → 触发 `WFormBorder.setError(true)` 渲染错误
4. 只读作用域通过 `WFormFieldShell` → `WFormReadOnlyScope` 穿透任意包装

---

## 1. WFormScope — 表单容器

### 功能说明

基于 `flutter_form_builder` 的 `FormBuilder` 封装，负责建立 `WFormController` 与子树的 InheritedWidget 传递通道。`formBorderConfig` 在这里配置后，整棵子树的边框都会继承。

### 构造参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `formData` | `WFormController` | ✅ | 持有 `formKey`，整棵子树共享 |
| `child` | `Widget` | ✅ | 表单内容 |
| `autovalidateMode` | `AutovalidateMode?` | | 自动校验模式 |
| `formBorderConfig` | `WFormBorderConfig?` | | 全局边框配置，为 null 时 `WFormBorder` 不渲染装饰 |

### 静态方法

| 方法 | 说明 |
|------|------|
| `WFormScope.of(BuildContext)` | 获取 `WFormController?`，无祖先时返回 null |
| `WFormScope.requireOf(BuildContext)` | 获取 `WFormController`，无祖先时抛 `StateError('WFormScope 未找到')` |
| `WFormScope.borderConfigOf(BuildContext)` | 获取子树生效的边框配置 |

### 使用示例

```dart
final formData = WFormController();
final borderConfig = WFormBorderConfig(
  defaultDecoration: const WFormBorderDecoration(color: Colors.white),
  errorDecoration: WFormBorderDecoration(border: Border.all(color: Colors.red)),
);

WFormScope(
  formData: formData,
  formBorderConfig: borderConfig,
  child: Column(
    children: [
      WFormTextField(name: 'name', label: '姓名'),
      WFormDropdown<String>(
        name: 'gender',
        label: '性别',
        items: const {'male': '男', 'female': '女'},
      ),
    ],
  ),
)
```

---

## 2. WFormController — 表单状态管理

### 功能说明

持有 `FormBuilderState.formKey`，提供字段值读写、输入状态追踪、边框错误联动与校验器工厂。

### 核心字段 / 方法

| 成员 | 类型 | 说明 |
|------|------|------|
| `formKey` | `GlobalKey<FormBuilderState>` | **核心键**，`WFormScope` 内部绑定 |
| `fields` | `FormBuilderFields?` | 表单未挂载时为 null |
| `value` | `Map<String, dynamic>` | 表单未挂载时返回空表 |
| `formEntered` | `Map<String, bool>` | 各字段「是否已输入」，可手动读取做按钮启用判定 |
| `isAllEntered(Iterable<String> fieldNames)` | `bool` | 指定字段是否都已输入；空集合返回 false |
| `setValue<T>(name, value)` | `void` | 仅写字段值，**不**更新 `formEntered` |
| `handleChange<T>(name, value, {callback})` | `void` | 清除错误 + 更新 `formEntered` + 回调；不写字段值 |
| `updateValue<T>(name, value)` | `void` | `setValue` + `handleChange`，业务代码优先用这个 |
| `clearValue(name)` | `void` | 清空值并复位输入状态 |
| `getFieldsValue<T>(name)` | `T?` | 无需先 `save` 即可获取即时值 |
| `setError(name, {errorTextList, callback})` | `void` | 触发边框 `errorBuilder` |
| `clearError(name)` | `void` | 清除边框错误 |
| `closeKeyboard()` | `void` | unfocus |
| `validators({config, items})` | `WFormValidator` | 校验器工厂 |
| `validate({config, items})` | `bool` | 一步校验；未挂载返回 false；items 为 null 时使用已挂载字段的自身 validator |
| `formBorderKeys` | `Map<String, GlobalKey<WFormBorderState>>` | 边框 key 注册表 |
| `ensureBorderKey(name)` | `GlobalKey<WFormBorderState>` | 获取 / 创建边框 key |
| `removeBorderKey(name)` | `void` | 注销边框 key（字段卸载） |
| `removeFormEntered(name)` | `void` | 注销输入状态（字段卸载） |
| `pruneFormEntered()` | `void` | 清理已卸载字段的残留输入状态 |

### formEntered 判定规则（handleChange）

| 值类型 | 判定条件 |
|--------|----------|
| `String` | `isNotEmpty` |
| `Iterable` | `isNotEmpty` |
| `Map` | `isNotEmpty` |
| `bool` | 自身值（true 表示已输入） |
| 其它 | `!= null` |

---

## 3. WFormTheme / WFormIcons — 表单主题

> 普通页面优先使用 §3.6 的 `WForm`，它内部会创建 `WFormTheme` 与 `WFormScope`。
> 本节说明底层主题能力，供自定义布局使用。

推荐用 `WFormTheme` 做作用域隔离：

```dart
WFormTheme(
  borderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
  icons: WFormIcons.defaults.copyWith(
    dropdown: const Icon(Icons.expand_more),
    checkboxSelected: const Icon(Icons.check_circle),
  ),
  child: WFormScope(...),
)
```

`WFormTheme.borderConfig` 会被 `WFormScope` 继承；`WFormScope.formBorderConfig` 显式传入时优先。

优先级：单个字段的 `xxxIcon` 参数 > `WFormTheme.icons`（或 `WForm.icons`）> 包内默认。

### WFormIcons — 图标集合

不可变；8 个图标一名一个字段，用 `copyWith` 替换需要的项：

```dart
const icons = WFormIcons(
  dropdown: Icon(Icons.expand_more),
  checkboxSelected: Icon(Icons.check_circle),
);
```

`WForm(icons: icons)` 只影响该表单；需要整个 App 统一时放到 `WFormTheme` 外层。
`WFormIcons.defaults` 是包内默认值。

> `WFormDefaults` 已在 4.0 删除；未配置 `WFormTheme.icons` / `WForm.icons` 时用 `WFormIcons.defaults`。

---

## 3.5 内部 Config

`WForm*Config` / `WForm*Core` 是包内实现，不从 `w_tools_form.dart` 导出。
业务代码不要实例化、不要 `Config.build(...)`、不要 import `src/`。

需要字段样式时：

```text
页面级样式 → WForm.fieldStyle / WFormFieldStyle
字段级差异 → 直接字段参数（label / message / validator / ...）
边框 / 校验 / 只读 → WForm
```

---

## 3.6 直接字段与 WForm

普通业务页面优先使用 `WForm` + 直接字段构造。`WForm` 统一组合主题、表单作用域与只读作用域：

```dart
WForm(
  controller: form,
  borderConfig: WFormBorderConfig.standard(radius: 12),
  readOnly: false,
  child: ListView(
    children: [
      WFormTextField(
        name: 'email',
        label: '邮箱',
        message: '请输入邮箱',
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入邮箱';
          return null;
        },
      ),
      WFormDropdown<String>(
        name: 'country',
        label: '国家 / 地区',
        items: const {
          'CN': '中国大陆',
          'HK': '中国香港',
        },
      ),
      WFormButton(
        name: 'coupon',
        label: '选择优惠券',
        onTap: (_, didChange) {
          // 打开选择器后调用 didChange(value)
        },
      ),
    ],
  ),
)
```

直接字段包括：

| 字段 | 入口 |
|---|---|
| 文本 / 密码 | `WFormTextField` |
| 下拉 | `WFormDropdown<T>` |
| 多选 | `WFormMultiDropdown` |
| 日期 | `WFormDatePicker` |
| 复选 | `WFormCheckbox` |
| 单选 | `WFormRadioGroup<T>` |
| 自定义按钮 | `WFormButton` |

字段不接受 `config`。样式差异优先用直接参数；页面级默认样式通过
`WForm.fieldStyle` 统一：

```dart
WForm(
  controller: form,
  fieldStyle: const WFormFieldStyle(
    height: 52,
    containerPadding: EdgeInsets.symmetric(horizontal: 16),
    textStyle: TextStyle(fontSize: 16),
    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
  ),
  validatorSettings: WFormValidatorSettings()
    ..showBorderError = true,
  child: ...,
)
```

样式来源：

```text
WForm.fieldStyle > 框架默认
```

直接字段只把自己支持的参数写进内部 Config；未设置的属性继续由
`WForm.fieldStyle` 填充。`WFormFieldStyle` 目前覆盖：

| 属性 | 生效范围 |
|---|---|
| `height` | 所有直接字段 |
| `containerPadding` | 所有直接字段 |
| `textStyle` | 文本 / 下拉 / 多选 / 日期 / 单选 |
| `hintStyle` | 文本 / 下拉 |

复选和单选默认 `bordered: false`，文本 / 下拉 / 多选 / 日期 / 按钮默认 `bordered: true`。
需要边框时显式传 `bordered: true`。

`WForm.validatorSettings` 会作为 `form.validate()` / `form.validators()` 的默认设置；
即使 validator 在 `WForm` 之前创建，也会在 `validate()` 时读取该默认值。

`WFormController` 与 `WForm` 建议一对一使用：`WForm` 会写入 controller 的默认校验设置，
多个 `WForm` 共用同一个 controller 时，后挂载的会覆盖前一个的默认设置。

`WFormTextFieldCore` / `WFormDropdownCore` 等是低层核心 Widget（`@internal`，不从公共面导出），普通业务页面不需要直接使用。完整示例见
[`packages/form/example`](../../packages/form/example/README.md)。

## 4. 边框系统

### 4.1 WFormBorderDecoration

定义边框 / 背景 / 圆角 / 阴影 / 渐变等样式：

```dart
const WFormBorderDecoration({
  BoxBorder? border,
  Color? color,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  Gradient? gradient,
});
```

提供链式扩展：

```dart
WFormBorderDecoration decoration = const WFormBorderDecoration()
  .withUniformBorder(1, Colors.grey)
  .withUniformBorderRadius(8)
  .withColor(Colors.white);
```

### 4.2 WFormBorderConfig

边框配置类，**不内置任何默认装饰**（全部为 null），外观完全由调用方决定。
本类不可变；需要链式修改时用 `copyWith`（`builder()` 已弃用，4.0 移除）。

常用场景可直接用工厂：

```dart
final config = WFormBorderConfig.standard(radius: 12);
```

再按需覆盖 `hintStyle` / `errorStyle` 或任意 setter。

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `defaultDecoration` | `WFormBorderDecoration?` | 默认状态装饰 |
| `readOnlyDecoration` | `WFormBorderDecoration?` | 只读状态装饰 |
| `errorDecoration` | `WFormBorderDecoration?` | 错误状态装饰（**错误态优先级高于透明背景**） |
| `focusedDecoration` | `WFormBorderDecoration?` | 聚焦状态装饰 |
| `hintBuilder` | `Widget Function(List<String>?)?` | 提示文本构建器 |
| `errorBuilder` | `Widget Function(List<String>?)?` | 错误文本构建器 |
| `layout` | `WFormBorderLayout` | 边框与消息的布局策略（默认 `WFormBorderLayout.column`） |

> **注意**：配置不可变。替换实例（`cfg = cfg.copyWith(...)`）后生效；需要清空字段时用 `copyWith` 的显式构造或新建实例，不再支持原地 setter。

### 4.3 WFormFieldShell

自动从祖先 `WFormScope` 获取 `WFormController`，通过 `formData.ensureBorderKey(name)` 注册边框 key，并注入 `WFormReadOnlyScope`。字段 Config 的 `build(bordered: true)` 即调用它。

边框配置通过 `WFormBorderConfigScope` 传递：`WFormTheme` / `WFormScope` 写入，`WFormBorder` 读取最近的 Scope；因此 `border.dart` 不再反向依赖表单 Scope / 主题。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | `String` | ✅必填 | 单字段场景应与组件 name 一致，复合容器可取组名 |
| `readOnly` | `bool` | false | 合并到 `WFormReadOnlyScope` |
| `enableFocusBorder` | `bool` | true | 聚焦时切换到 `focusedDecoration` |
| `useIntrinsicHeight` | `bool` | false | 外层套 `IntrinsicHeight` |
| `hintTextList` | `List<String>?` | | 提示文本 |
| `isTransparentBackground` | `bool?` | | 透明背景时装饰为 null（错误态除外） |

同时提供 `Row` 扩展：

```dart
WFormFieldShell(name: 'username', readOnly: false, child: Row(children: [...]))
// 旧写法 Row(...).withFormBorder(...) 已在 4.0 删除
```

### 4.4 WFormReadOnlyScope

`InheritedWidget`，`WFormFieldShell` 始终插入，所有字段组件通过 `WFormReadOnlyScope.readOnlyOf(context)` 合并只读状态，可穿透 `Padding` / `Center` / 自定义组件等任意包装。

---

## 5. 字段组件（直接用法 / 低层细节）

> 日常业务页面优先使用 §3.6 的 `WForm` + 直接字段（`WFormTextField` 等）。
> 本节示例默认使用直接字段；`WForm*Config` 仅为源码内部说明。
> `Config.build(...)` / `*Core` 属于低层实现，不作为页面主入口。
> 3.2 起它们标了 `@internal` 并从公共导出中 `hide`：消费方在 `analyze` 会得到
> `invalid_use_of_internal_member` / 找不到符号的提示；4.0 物理移出 public 面。

所有字段组件遵循统一模式：
- `XxxConfig` + `Xxx` 组件 + 单一构建入口 `build(bordered: bool)`
- `bordered: true` 时清空内层 `containerDecoration`，包装 `WFormFieldShell`；`bordered: false` 返回裸字段
- 只读 = `build` 的 `readOnly` 参数 ∨ `WFormReadOnlyScope.readOnlyOf(context)`（部分字段还会与 `enabled` 合并）
- 变更回调 → `FormBuilderFieldState.didChange` → `WFormController.handleChange`

### 5.0 Config.build 的 readOnly

`Config.build(readOnly: true)` 在 `bordered: false` 时也会插入
`WFormReadOnlyScope`，因此裸字段同样只读；不会再被忽略。

### 5.1 WFormTextField

> 低层说明：普通页面使用本节的 `WFormXxx` 直接入口；下方 Config 字段 / 构建细节仅供高级定制。

密码模式下自动设 `obscuringCharacter: '＊'`、`keyboardType: TextInputType.visiblePassword`。

#### WFormTextFieldConfig 常用字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `obscureText` | `bool` | 是否密码模式 |
| `style` / `readOnlyStyle` / `hintStyle` | `TextStyle?` | 文本样式 |
| `hintText` | `String?` | 输入框提示；直接字段的 `label` 优先 |
| `decoration` | `InputDecoration?` | 高级输入装饰覆盖，保留统一边框默认值 |
| `contentPadding` | `EdgeInsetsGeometry?` | 内边距 |
| `inputFormatters` | `List<TextInputFormatter>?` | 输入格式化器 |
| `keyboardType` | `TextInputType?` | 键盘类型，缺省密码模式自动补 `visiblePassword` |
| `textAlign` | `TextAlign` | 对齐方式 |
| `prefix` / `prefixIcon` / `leading` | `Widget?` | 前置插槽 |
| `yOffset` | `double?` | 垂直微调 |
| `enabled` | `bool` | false 时禁用文本字段（同时只读） |

#### WFormTextFieldScope（InheritedWidget 管道）

插槽 Widget（actions / suffix）可通过 `WFormTextFieldScope.of(context)` 读取：

| 成员 | 类型 | 说明 |
|------|------|------|
| `value` | `String?` | 当前输入值 |
| `hasText` | `bool` | 是否有内容 |
| `valueListenable` | `ValueListenable<String?>` | 订阅器，用于清空按钮状态联动 |
| `togglePasswordVisibility()` | `void Function()` | 密码可见性切换 |
| `clear()` | `void Function()` | 清空（只读下无效果） |

#### 预置 Action

- `WFormTextFieldPasswordToggle` — 密码可见性切换按钮（图标从 `WFormTheme.icons` 取）
- `WFormTextFieldClearButton` — 清空按钮（有内容才显示，只读下不触发）
- `WFormTextFieldAction` — 通用 `IconButton`

#### 使用示例

```dart
WFormTextField(
  name: 'username',
  label: '用户名',
  message: '请输入用户名',
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: (v) => (v?.isEmpty ?? true) ? '请输入' : null,
),

// 密码字段（带可见性切换）
WFormTextField(
  name: 'password',
  label: '密码',
  obscureText: true,
  actions: const [WFormTextFieldPasswordToggle()],
),
```

### 5.2 WFormDropdown\<T\>

> 低层说明：普通页面使用本节的 `WFormXxx` 直接入口；下方 Config 字段 / 构建细节仅供高级定制。

#### 特性

- `items: Map<T, String>`，**初始值 / 字段值必须存在于 items 中**（`FormBuilderDropdown` 内部断言）
- 占位提示：`hintText` 优先于 `label`

#### 使用示例

```dart
enum Gender { male, female }

WFormDropdown<Gender>(
  name: 'gender',
  label: '性别',
  items: const {Gender.male: '男', Gender.female: '女'},
  initialValue: Gender.male,
),
```

### 5.3 WFormMultiDropdown

> 低层说明：普通页面使用本节的 `WFormXxx` 直接入口；下方 Config 字段 / 构建细节仅供高级定制。

#### 特性

- 值类型 `Set<String>`
- 点击通过 `WFormPopup.show` 在锚点下方弹出多选列表（Wrap 布局）
- `disabledKeys: Set<String>` — 已选中禁用项显示选中态但不可点击
- 显示文本：已选项按选中顺序拼接；未选时显示 `hintText` 或 `'ALL'`
- 弹出层空间不足自动向上翻转，位置打开时计算一次（滚动不跟随）

#### 使用示例

```dart
WFormMultiDropdown(
  name: 'hobbies',
  label: '爱好',
  items: const {'read': '阅读', 'sport': '运动', 'music': '音乐'},
  disabledKeys: const {'music'},
),
```

### 5.4 WFormCheckbox

- 单选布尔值，`initialValue` 默认 `false`
- `isEnabled = state.enabled && !WFormReadOnlyScope`

### 5.5 WFormRadioGroup\<T\>

- `Map<T, String> items`，单列 `Column` 布局
- 可选 `titleBuilder`（组标题）/ `itemExtraBuilder`（每项下方附加）
- `lineSpacing` 控制行间距

### 5.6 WFormDatePicker

> 低层说明：普通页面使用本节的 `WFormXxx` 直接入口；下方 Config 字段 / 构建细节仅供高级定制。

- 存储格式：ISO `yyyy-MM-dd`（与 locale 无关）
- 显示格式：`DateFormat(displayFormat, locale)`，默认 `'yMMMMd'`
- 使用系统 `showDatePicker`；直接字段的 `firstDate` / `lastDate` 可选，默认 `DateTime(1900)` / `DateTime.now()`（建议显式传值，尤其是允许未来日期时）

#### 使用示例

```dart
WFormDatePicker(
  name: 'birthday',
  label: '生日',
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
),
```

需要自定义显示格式时直接传 `displayFormat`：

```dart
WFormDatePicker(
  name: 'birthday',
  label: '生日',
  displayFormat: 'yyyy-MM-dd',
),
```

### 5.7 WFormButton

- 日常入口是 `WFormButton`；点击行为由 `onTap(value, didChange)` 决定，调用方通过 `didChange` 写值
- `selectedWidgetBuilder` 渲染当前选中值
- `WFormFieldButtonCore` 是底层 Widget；`WFormFieldButtonConfig` 是可变的低层配置
- 普通页面直接使用 `WFormButton`；字段差异用 `label` / `hintWidget` / `leading`

```dart
WFormButton(
  name: 'coupon',
  label: '请选择优惠券',
  onTap: (_, didChange) {
    // 选择后调用 didChange(value)
  },
)

// 直接传 hintWidget，不写 label 也可以
WFormButton(
  name: 'coupon',
  hintWidget: const Text('请选择优惠券'),
  onTap: (_, didChange) {},
)
```

---

## 6. WFormPopup — 弹出层

### 静态方法

#### WFormPopup.show\<T\>

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `context` | `BuildContext` | ✅ | |
| `builder` | `WidgetBuilder` | ✅ | 弹出内容 |
| `anchorContext` | `BuildContext?` | | 锚点（默认 `context`） |
| `rootNavigator` | `bool` | false | 是否推入根 Navigator |
| `width` | `double?` | null 时与锚点同宽 | 弹层宽度 |
| `backgroundColor` | `Color?` | 主题 canvas 色 | |
| `borderRadius` | `BorderRadius?` | | |
| `elevation` | `double?` | | |
| `shadowColor` | `Color?` | | |
| `animationDuration` | `Duration` | 200ms | |
| `settings` | `RouteSettings?` | | |

- 同一 Navigator 已有弹层时忽略重复调用
- 锚点下方弹出，空间不足自动向上翻转
- 位置在打开时计算一次，锚点滚动不跟随

#### WFormPopup.hide

```dart
WFormPopup.hide<T>(context, [result, rootNavigator]);
```

---

## 7. 校验系统

### 概述

`WFormValidator` 由 `WFormController.validators({config, items})` 创建，按序执行校验项，支持短路 / 全量校验、边框错误渲染、自动聚焦与错误提示回调。

### WFormValidatorItem

| 构造 | 说明 |
|------|------|
| `WFormValidatorItem({fieldName, validatorBuilder, autofocus})` | 自定义校验函数（每次校验时调用一次生成器，便于按运行期状态生成动态规则） |
| `WFormValidatorItem.field(fieldName, {autofocus})` | 执行字段自身声明的 `validator`，错误统一写入 `WFormValidator.errors` 与边框错误 |

### WFormValidatorSettings（默认值）

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `showBorderError` | false | 是否渲染边框错误（校验开始时清空不受此开关影响） |
| `continueOnError` | false | true = 全量校验；false = 短路（遇第一个失败项即返回） |
| `notifyAllErrors` | false | `customErrorCallback` 是否对所有失败项触发 |
| `customErrorCallback` | null | `(fieldName, errorText)`，默认只对第一个失败项触发 |
| `itemValidationCallback` | null | 每项结果回调 `(fieldName, isValid, errorText)` |
| `shouldSkipValidation` | null | `(fieldName, formValues) => bool`，返回 true 跳过 |

### WFormValidator.errors

只读快照 `Map<String, String>`，每次 `validate()` 重新填充，可用于汇总展示全部错误。

### 使用示例

```dart
final validator = formData.validators(
  settings: WFormValidatorSettings()
    ..showBorderError = true
    ..continueOnError = true
    ..customErrorCallback = (name, err) => showToast(err),
  items: [
    WFormValidatorItem.field('username'),            // 使用字段自身 validator
    WFormValidatorItem(
      fieldName: 'password',
      validatorBuilder: () => (v) =>
          (v == null || v.length < 6) ? '密码至少 6 位' : null,
    ),
  ],
);

if (validator.validate()) {
  // all valid
}
```

---

## 8. form_input_formatters.dart

输入格式化器集合，常见内置项（按项目实际导出）：
- `FilteringTextInputFormatter.digitsOnly`
- 自定义货币 / 手机号 / 邮箱 formatter

---

## 完整表单配置示例

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formData = WFormController();

  late final WFormBorderConfig _borderConfig = WFormBorderConfig(
    defaultDecoration: const WFormBorderDecoration()
        .withUniformBorder(1, Colors.grey)
        .withUniformBorderRadius(8)
        .withColor(Colors.white),
    focusedDecoration: const WFormBorderDecoration()
        .withUniformBorder(1.5, Colors.blue)
        .withUniformBorderRadius(8),
    errorDecoration: const WFormBorderDecoration()
        .withUniformBorder(1.5, Colors.red)
        .withUniformBorderRadius(8),
    errorBuilder: (list) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(list?.first ?? '',
          style: const TextStyle(color: Colors.red, fontSize: 12)),
    ),
  );

  late final _validator = _formData.validators(
    settings: WFormValidatorSettings()
      ..showBorderError = true
      ..customErrorCallback = (name, err) {
        debugPrint('[$name] $err');
      },
    items: [
      WFormValidatorItem.field('username'),
      WFormValidatorItem.field('password'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WForm(
        controller: _formData,
        borderConfig: _borderConfig,
        fieldStyle: const WFormFieldStyle(
          containerPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              WFormTextField(
                name: 'username',
                label: '用户名',
                message: '请输入用户名',
                validator: (v) =>
                    (v?.isEmpty ?? true) ? '请输入用户名' : null,
              ),
              const SizedBox(height: 12),
              WFormTextField(
                name: 'password',
                label: '密码',
                message: '密码至少 6 位',
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入密码';
                  if (v.length < 6) return '密码至少 6 位';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_validator.validate()) {
                    final values = _formData.value;
                    debugPrint('submit: $values');
                  }
                },
                child: const Text('登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 注意事项

| # | 事项 | 说明 |
|---|------|------|
| 1 | **Flutter 版本锁定** | 依赖链 `flutter_form_builder:10.3.0+2` / `form_builder_validators:11.3.0` 传递最低 Flutter 3.38，请确保项目约束 ≥ 3.38 |
| 2 | **Config 两种形态** | `WFormBorderConfig` 全字段 final：用构造 / `copyWith`；字段 Config（如 `WFormTextFieldConfig`）可变：用 cascade / `copyWith` |
| 3 | **bordered 构建清空内层装饰** | 调用 `build(bordered: true)` 后，字段自身 `containerDecoration` 会被清空；必须依赖外层 `WFormFieldShell` 提供边框 |
| 4 | **Dropdown items 键必须存在** | `WFormDropdown.items` 是 `Map<T, String>`，初始值 / 字段值必须存在于 map 的 keys 中（`FormBuilderDropdown` 内部断言会失败） |
| 5 | **Scope 管道** | `WFormTextFieldScope`（InheritedWidget）将输入状态下发给插槽 Widget（清空按钮 / 密码切换），无需手动同步 |
| 6 | **WFormBorderConfig 继承** | 子级显式传入 `WFormBorder.config` 优先；否则继承 `WFormScope.formBorderConfig`；都没配置时 `WFormBorder` 不渲染装饰 |
| 7 | **formEntered 陈旧过滤** | `isAllEntered(fieldNames)` 用显式字段名判断；字段卸载时由 `WFormFieldShell` / 字段生命周期包装清理，`pruneFormEntered()` 可兜底 |
| 8 | **setError / 字段 name 一致性** | `WFormFieldShell.name` 必须与内部字段 `name` 一致，否则校验红框无法自动联动 |
| 9 | **PopRoute 不跟随滚动** | `WFormPopup` 位置打开时计算一次，锚点滚动后弹层不跟随，如需跟随请使用其他方案 |
| 10 | **校验器双通道风险** | `WFormValidatorItem.field` 模式直接执行字段 `validator`，**不**写入字段 `errorText`，只通过 `WFormBorder.setError` 渲染；若同时开 FormBuilder 原生 `validate()` 会走另一通道，建议统一使用 `WFormValidator` |
| 11 | **copyWith(null) 不代表清空** | `WFormBorderConfig.copyWith(errorDecoration: null)` 保持原值；清空请用 `cfg.copy()..errorDecoration = null` |
| 12 | **默认图标替换** | `WFormTheme.icons` / `WForm.icons` 优先，未配置项回退到 `WFormIcons.defaults`；`WFormDefaults` 已在 4.0 删除 |

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
