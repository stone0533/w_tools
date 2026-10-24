# Form 模块文档

## 概述

Form 模块（`w_tools_form` 子包）提供了一套基于 `flutter_form_builder` 的表单构建方案，包含表单容器、字段组件（文本 / 下拉 / 多选 / 复选 / 单选 / 日期 / 按钮）、统一边框系统、只读作用域、弹出层与校验器工厂。

**强依赖**：
- [`flutter_form_builder`](https://pub.dev/packages/flutter_form_builder)（表单内核，10.3.0+2 起锁定最低 Flutter 3.38）
- [`form_builder_validators`](https://pub.dev/packages/form_builder_validators)（可选校验器集合，11.3.0 起锁定最低 Flutter 3.38）
- `intl`（日期格式化，由 `DateFormat` 使用）

**最低 Flutter 版本**：3.38（由 `flutter_form_builder` / `form_builder_validators` 传递约束）

---

## 模块结构

```
form/
├── w_tools_form.dart
└── lib/src/
    ├── components/
    │   ├── form_builder.dart
    │   ├── form_data.dart
    │   ├── form_defaults.dart
    │   ├── input_formatters.dart
    │   ├── button.dart
    │   ├── popup.dart
    │   ├── border/
    │   │   ├── border.dart          # WFormBorder + WFormBorderConfig + WFormBorderDecoration
    │   │   ├── border_layout.dart   # 边框与消息的布局策略（column / row / 内联等）
    │   │   ├── border_with_data.dart # WFormBorderWithData + Row 扩展
    │   │   └── read_only_scope.dart # WFormReadOnlyScope（InheritedWidget）
    │   ├── validation/
    │   │   ├── validator.dart       # WFormValidator + WFormValidatorItem + WFormValidatorConfig
    │   │   └── custom_validator.dart
    │   └── fields/
    │       ├── text_field.dart       # WFormTextField + WFormTextFieldConfig + Scope 管道
    │       ├── dropdown.dart         # WFormDropdown + WFormDropdownConfig
    │       ├── multi_dropdown.dart   # WFormMultiDropdown + WFormMultiDropdownConfig
    │       ├── checkbox.dart         # WFormCheckbox + WFormCheckboxConfig
    │       ├── radio_group.dart      # WFormRadioGroup + WFormRadioGroupConfig
    │       └── date_picker.dart      # WFormDatePicker + WFormDatePickerConfig
```

---

## 核心架构

```
WFormBuilder (StatelessWidget)
  └─ _WFormDataInherited (InheritedWidget)
      ├─ formData: WFormData
      └─ formBorderConfig: WFormBorderConfig?
          └─ FormBuilder (flutter_form_builder)
              └─ [各字段组件]
                  └─ WFormBorderWithData（绑定 formData.formBorderKeys[name]）
                      ├─ 自动注入 WFormReadOnlyScope
                      └─ WFormBorder（边框绘制 + 错误展示）

WFormValidator
  └─ WFormData.validators({config, items}) 工厂创建
      └─ 按序执行 WFormValidatorItem 列表
```

### 数据流

1. `WFormBuilder.of(context)` 拿到 `WFormData`
2. 字段通过 `FormBuilderFieldState.didChange` → `WFormData.onChange` 更新 `formEntered`
3. 校验失败时 `WFormData.setError(name)` 命中 `formBorderKeys[name]` → 触发 `WFormBorder.setError(true)` 渲染错误
4. 只读作用域通过 `WFormBorderWithData` → `WFormReadOnlyScope` 穿透任意包装

---

## 1. WFormBuilder — 表单容器

### 功能说明

基于 `flutter_form_builder` 的 `FormBuilder` 封装，负责建立 `WFormData` 与子树的 InheritedWidget 传递通道。`formBorderConfig` 在这里配置后，整棵子树的边框都会继承。

### 构造参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `formData` | `WFormData` | ✅ | 持有 `formKey`，整棵子树共享 |
| `child` | `Widget` | ✅ | 表单内容 |
| `autovalidateMode` | `AutovalidateMode?` | | 自动校验模式 |
| `formBorderConfig` | `WFormBorderConfig?` | | 全局边框配置，为 null 时 `WFormBorder` 不渲染装饰 |

### 静态方法

| 方法 | 说明 |
|------|------|
| `WFormBuilder.of(BuildContext)` | 获取 `WFormData?`，无祖先时返回 null |
| `WFormBuilder.requireOf(BuildContext)` | 获取 `WFormData`，无祖先时抛 `StateError('WFormBuilder 未找到')` |
| `WFormBuilder.borderConfigOf(BuildContext)` | 获取子树生效的边框配置 |

### 使用示例

```dart
final formData = WFormData();
final borderConfig = WFormBorderConfig()
  ..defaultDecoration = WFormBorderDecoration(color: Colors.white)
  ..errorDecoration = WFormBorderDecoration(border: Border.all(color: Colors.red));

WFormBuilder(
  formData: formData,
  formBorderConfig: borderConfig,
  child: Column(
    children: [
      WFormTextField(name: 'name', config: nameConfig),
      WFormDropdown(name: 'gender', config: genderConfig, items: {Gender.male: '男', Gender.female: '女'}),
    ],
  ),
)
```

---

## 2. WFormData — 表单状态管理

### 功能说明

持有 `FormBuilderState.formKey`，提供字段值读写、输入状态追踪、边框错误联动与校验器工厂。

### 核心字段 / 方法

| 成员 | 类型 | 说明 |
|------|------|------|
| `formKey` | `GlobalKey<FormBuilderState>` | **核心键**，`WFormBuilder` 内部绑定 |
| `fields` | `FormBuilderFields?` | 表单未挂载时为 null |
| `value` | `Map<String, dynamic>` | 表单未挂载时返回空表 |
| `formEntered` | `Map<String, bool>` | 各字段「是否已输入」，可手动读取做按钮启用判定 |
| `isAllEntered(int length)` | `bool` | 按已注册字段过滤陈旧记录（关闭弹窗 / 动态移除字段后不恒为 false） |
| `didChange<T>(name, value)` | `void` | 仅写字段值，**不**更新 `formEntered` |
| `onChange<T>(name, value, {callback})` | `void` | 清除错误 + 更新 `formEntered` + 回调 |
| `getFieldsValue<T>(name)` | `T?` | 无需先 `save` 即可获取即时值 |
| `setError(name, {errorTextList, callback})` | `void` | 触发边框 `errorBuilder` |
| `clearError(name)` | `void` | 清除边框错误 |
| `closeKeyboard()` | `void` | unfocus |
| `validators({config, items})` | `WFormValidator` | 校验器工厂 |
| `formBorderKeys` | `Map<String, GlobalKey<WFormBorderState>>` | 边框 key 注册表 |
| `ensureBorderKey(name)` | `GlobalKey<WFormBorderState>` | 获取 / 创建边框 key |

### formEntered 判定规则（onChange）

| 值类型 | 判定条件 |
|--------|----------|
| `String` | `isNotEmpty` |
| `Iterable` | `isNotEmpty` |
| `Map` | `isNotEmpty` |
| `bool` | 自身值（true 表示已输入） |
| 其它 | `!= null` |

---

## 3. WFormDefaults — 全局默认图标

静态可替换变量，修改后对之后构建的表单组件生效；组件显式配置优先。

```dart
class WFormDefaults {
  static Widget dropdownIcon = const Icon(Icons.keyboard_arrow_down);
  static Widget radioUnselectedIcon = const Icon(Icons.radio_button_off);
  static Widget radioSelectedIcon = const Icon(Icons.radio_button_checked);
  static Widget checkboxUnselectedIcon = const Icon(Icons.check_box_outline_blank);
  static Widget checkboxSelectedIcon = const Icon(Icons.check_box);
  static Widget obscureTextIcon = const Icon(Icons.visibility_off);
  static Widget obscureTextVisibleIcon = const Icon(Icons.visibility);
  static Widget clearButtonIcon = const Icon(Icons.clear, size: 18);
}
```

### 全局替换示例

```dart
WFormDefaults.checkboxSelectedIcon = const Icon(Icons.check_circle, color: Colors.blue);
```

---

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

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `defaultDecoration` | `WFormBorderDecoration?` | 默认状态装饰 |
| `readOnlyDecoration` | `WFormBorderDecoration?` | 只读状态装饰 |
| `errorDecoration` | `WFormBorderDecoration?` | 错误状态装饰（**错误态优先级高于透明背景**） |
| `focusedDecoration` | `WFormBorderDecoration?` | 聚焦状态装饰 |
| `hintBuilder` | `Widget Function(List<String>?)?` | 提示文本构建器 |
| `errorBuilder` | `Widget Function(List<String>?)?` | 错误文本构建器 |
| `layout` | `WFormBorderLayout` | 边框与消息的布局策略（默认 `WFormBorderLayout.column`） |

> **注意**：配置按引用被 `WFormBorder` 捕获。替换实例（`cfg = cfg.copyWith(...)`）立即生效；原地修改（`cfg.errorDecoration = ...`）仅在组件随后重建时生效。清空字段请使用 `cfg.copy()..errorDecoration = null`。

### 4.3 WFormBorderWithData

自动从祖先 `WFormBuilder` 获取 `WFormData`，通过 `formData.ensureBorderKey(name)` 注册边框 key，并注入 `WFormReadOnlyScope`。字段 Config 的 `build(bordered: true)` 即调用它。

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
Row(children: [...]).withFormBorder(name: 'username', readOnly: false)
```

### 4.4 WFormReadOnlyScope

`InheritedWidget`，`WFormBorderWithData` 始终插入，所有字段组件通过 `WFormReadOnlyScope.readOnlyOf(context)` 合并只读状态，可穿透 `Padding` / `Center` / 自定义组件等任意包装。

---

## 5. 字段组件

所有字段组件遵循统一模式：
- `XxxConfig` + `Xxx` 组件 + 单一构建入口 `build(bordered: bool)`
- `bordered: true` 时清空内层 `containerDecoration`，包装 `WFormBorderWithData`；`bordered: false` 返回裸字段
- 只读 = `build` 的 `readOnly` 参数 ∨ `WFormReadOnlyScope.readOnlyOf(context)`（部分字段还会与 `enabled` 合并）
- 变更回调 → `FormBuilderFieldState.didChange` → `WFormData.onChange`

### 5.1 WFormTextField

密码模式下自动设 `obscuringCharacter: '＊'`、`keyboardType: TextInputType.visiblePassword`。

#### WFormTextFieldConfig 常用字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `obscureText` | `bool` | 是否密码模式 |
| `style` / `readOnlyStyle` / `hintStyle` | `TextStyle?` | 文本样式 |
| `contentPadding` | `EdgeInsetsGeometry?` | 内边距 |
| `inputFormatters` | `List<TextInputFormatter>?` | 输入格式化器 |
| `keyboardType` | `TextInputType?` | 键盘类型，缺省密码模式自动补 `visiblePassword` |
| `textAlign` | `TextAlign` | 对齐方式 |
| `prefix` / `prefixIcon` / `leading` | `Widget?` | 前置插槽 |
| `yOffset` | `double?` | 垂直微调 |

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

- `WFormTextFieldPasswordToggle` — 密码可见性切换按钮（图标从 `WFormDefaults` 取）
- `WFormTextFieldClearButton` — 清空按钮（有内容才显示，只读下不触发）
- `WFormTextFieldAction` — 通用 `IconButton`

#### 使用示例

```dart
(WFormTextFieldConfig()
  ..style = const TextStyle(fontSize: 16)
  ..contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
  ..inputFormatters = [FilteringTextInputFormatter.digitsOnly])
    .build(
  name: 'username',
  hintText: '请输入用户名',
  validator: (v) => (v?.isEmpty ?? true) ? '请输入' : null,
  bordered: true,
),

// 密码字段（带可见性切换 + 清空按钮）
(WFormTextFieldConfig()..obscureText = true)
    .build(name: 'password', bordered: true),
```

### 5.2 WFormDropdown\<T\>

#### 特性

- `items: Map<T, String>`，**初始值 / 字段值必须存在于 items 中**（`FormBuilderDropdown` 内部断言）
- `hintWidget` 优先级：`hint` > `config.hint`

#### 使用示例

```dart
enum Gender { male, female }

(WFormDropdownConfig()..style = const TextStyle(fontSize: 16))
    .build(
  name: 'gender',
  items: const {Gender.male: '男', Gender.female: '女'},
  initialValue: Gender.male,
  hint: '请选择性别',
  bordered: true,
),
```

### 5.3 WFormMultiDropdown

#### 特性

- 值类型 `Set<String>`
- 点击通过 `WFormPopup.show` 在锚点下方弹出多选列表（Wrap 布局）
- `disabledKeys: Set<String>` — 已选中禁用项显示选中态但不可点击
- 显示文本：已选项按选中顺序拼接；未选时显示 `hintText` 或 `'ALL'`
- 弹出层空间不足自动向上翻转，位置打开时计算一次（滚动不跟随）

#### 使用示例

```dart
(WFormMultiDropdownConfig()..disabledKeys = const {'music'})
    .build(
  name: 'hobbies',
  items: const {'read': '阅读', 'sport': '运动', 'music': '音乐'},
  hintText: '请选择爱好',
  bordered: true,
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

- 存储格式：ISO `yyyy-MM-dd`（与 locale 无关）
- 显示格式：`DateFormat(config.displayFormat, locale)`，默认 `'yMMMMd'`
- 使用系统 `showDatePicker`，`firstDate` / `lastDate` 必填

#### 使用示例

```dart
(WFormDatePickerConfig()..displayFormat = 'yyyy-MM-dd')
    .build(
  name: 'birthday',
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
  bordered: true,
),
```

### 5.7 WFormButton

- 点击行为完全由 `onTap` 决定：`(value, didChange)` 回调，调用方通过 `didChange` 写值
- `selectedWidgetBuilder` 渲染当前选中值

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

`WFormValidator` 由 `WFormData.validators({config, items})` 创建，按序执行校验项，支持短路 / 全量校验、边框错误渲染、自动聚焦与错误提示回调。

### WFormValidatorItem

| 构造 | 说明 |
|------|------|
| `WFormValidatorItem({fieldName, validatorBuilder, autofocus})` | 自定义校验函数（每次校验时调用一次生成器，便于按运行期状态生成动态规则） |
| `WFormValidatorItem.field(fieldName, {autofocus})` | 执行字段自身声明的 `validator`，错误统一写入 `WFormValidator.errors` 与边框错误 |

### WFormValidatorConfig（默认值）

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
  config: WFormValidatorConfig()
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

## 8. input_formatters.dart

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
  final _formData = WFormData();
  bool _obscurePwd = true;

  late final WFormBorderConfig _borderConfig = WFormBorderConfig()
    ..defaultDecoration = const WFormBorderDecoration()
        .withUniformBorder(1, Colors.grey)
        .withUniformBorderRadius(8)
        .withColor(Colors.white)
    ..focusedDecoration = const WFormBorderDecoration()
        .withUniformBorder(1.5, Colors.blue)
        .withUniformBorderRadius(8)
    ..errorDecoration = const WFormBorderDecoration()
        .withUniformBorder(1.5, Colors.red)
        .withUniformBorderRadius(8)
    ..errorBuilder = (list) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(list?.first ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        );

  late final _validator = _formData.validators(
    config: WFormValidatorConfig()
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
      body: WFormBuilder(
        formData: _formData,
        formBorderConfig: _borderConfig,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              (WFormTextFieldConfig()
                ..style = const TextStyle(fontSize: 16)
                ..contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12))
                  .build(
                name: 'username',
                hintText: '用户名',
                validator: (v) => (v?.isEmpty ?? true) ? '请输入用户名' : null,
                bordered: true,
              ),

              const SizedBox(height: 12),

              (WFormTextFieldConfig()
                ..obscureText = _obscurePwd
                ..contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12))
                  .build(
                name: 'password',
                hintText: '密码',
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入密码';
                  if (v.length < 6) return '密码至少 6 位';
                  return null;
                },
                bordered: true,
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
| 2 | **Config 私有字段** | `WFormBorderConfig._*` / `WFormTextFieldConfig._*` 等私有字段通过 setter / builder 方法配置，直接赋值会触发静态错误 |
| 3 | **bordered 构建清空内层装饰** | 调用 `build(bordered: true)` 后，字段自身 `containerDecoration` 会被清空；必须依赖外层 `WFormBorderWithData` 提供边框 |
| 4 | **Dropdown items 键必须存在** | `WFormDropdown.items` 是 `Map<T, String>`，初始值 / 字段值必须存在于 map 的 keys 中（`FormBuilderDropdown` 内部断言会失败） |
| 5 | **Scope 管道** | `WFormTextFieldScope`（InheritedWidget）将输入状态下发给插槽 Widget（清空按钮 / 密码切换），无需手动同步 |
| 6 | **WFormBorderConfig 继承** | 子级显式传入 `WFormBorder.config` 优先；否则继承 `WFormBuilder.formBorderConfig`；都没配置时 `WFormBorder` 不渲染装饰 |
| 7 | **formEntered 陈旧过滤** | `isAllEntered(length)` 按已注册 `fields` 过滤，动态移除字段后不会因残留记录恒为 false，但调用方需保证传入的 `length` 与实际参与判断的字段数一致 |
| 8 | **setError / 字段 name 一致性** | `WFormBorderWithData.name` 必须与内部字段 `name` 一致，否则校验红框无法自动联动 |
| 9 | **PopRoute 不跟随滚动** | `WFormPopup` 位置打开时计算一次，锚点滚动后弹层不跟随，如需跟随请使用其他方案 |
| 10 | **校验器双通道风险** | `WFormValidatorItem.field` 模式直接执行字段 `validator`，**不**写入字段 `errorText`，只通过 `WFormBorder.setError` 渲染；若同时开 FormBuilder 原生 `validate()` 会走另一通道，建议统一使用 `WFormValidator` |
| 11 | **copyWith(null) 不代表清空** | `WFormBorderConfig.copyWith(errorDecoration: null)` 保持原值；清空请用 `cfg.copy()..errorDecoration = null` |
| 12 | **全局默认图标替换** | `WFormDefaults` 替换后影响所有未显式配置的组件，可用于主题化；组件显式配置优先于全局默认 |

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
