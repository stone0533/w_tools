# Button 使用规则

## 决策

```text
普通业务按钮：提交 / 保存 / 取消 / 删除
  → WButton

任意 child 点击：卡片 / 列表项 / 自定义区域
  → WPressable

表单字段值选择：优惠券 / 自定义选择 / 弹层选择
  → WFormButton

一排「选中态」按钮（分段选择；点击会改变选中）
  → WSelectableRow

一排普通动作按钮（取消 / 确定、工具栏）
  → WActionRow

完全自定义字段
  → FormBuilderField + WFormReadOnlyScope（不要用内部 *Core）
```

不要用：

```text
GestureDetector / InkWell 自己拼按钮
用 WFormButton 承担普通业务动作
用 WButton 承担表单字段值
```

## WButton

`WButton` 直接渲染 Material `FilledButton` / `OutlinedButton` / `TextButton`，
视觉由 Material `ButtonStyle` 驱动（水波纹、键盘 / 焦点、禁用态都与 Material 一致）。

```dart
WButton(
  style: AppButtons.primary(context), // 返回 ButtonStyle
  label: '保存',
  onTap: _save,
)

// 或直接用语义变体（取 WButtonTheme 的派生样式）
WButton(variant: WButtonVariant.outlined, label: '取消', onTap: _cancel);
```

支持：

```text
variant：filled / outlined / text / danger
style：单个按钮的 ButtonStyle 覆盖
size：WButtonSize.small / medium / large 或自定义令牌
label / icon / content
loading / loadingBuilder / enabled
semanticLabel / semanticHint / loadingLabel
tooltip / isSelected / onLongPress
focusNode / autofocus
```

按钮宽度：

```text
WButton / ButtonStyle 不包含 width
width 由父布局决定
撑满用 SizedBox(width: double.infinity) 或 Expanded
固定宽度用外层 SizedBox(width: ...)
WButtonSize 的 minWidth / minHeight 只是最小视觉尺寸，不是固定宽度
```

## AI 默认模板

### 主按钮

```dart
WButton(
  style: AppButtons.primary(context),
  label: '保存',
  onTap: _save,
)
```

### 次要按钮

```dart
WButton(
  variant: WButtonVariant.outlined,
  label: '取消',
  onTap: _cancel,
)
```

### 危险操作

```dart
WButton(
  variant: WButtonVariant.danger,
  label: '删除',
  onTap: _remove,
)
```

### loading 提交

```dart
WButton(
  style: AppButtons.primary(context),
  label: '提交',
  loading: submitting,
  onTap: _submit,
)
```

`loading: true` 时按钮自动不可点并显示 spinner，不需要再传 `enabled: false`。

### 全宽按钮

```dart
SizedBox(
  width: double.infinity,
  child: WButton(
    style: AppButtons.primary(context),
    label: '提交',
    onTap: _submit,
  ),
)
```

### 图标按钮

```dart
WButton(
  style: AppButtons.primary(context),
  label: '添加',
  icon: Icons.add,
  onTap: _add,
)
```

### 纯图标按钮

```dart
WButton(
  style: AppButtons.text(context),
  icon: Icons.close,
  semanticLabel: '关闭',
  onTap: _close,
)
```

## 选择规则

```text
label / label+icon → 最简单，优先
content            → 静态复杂内容（Row / Column / 自定义组合）
```

不要同时传 `label` 和 `content`；`content` 内部的 `Text` / `Icon` 会自动继承按钮的
前景色与文字样式（Material 的 `DefaultTextStyle` / `IconTheme`），不要再手写颜色。

项目页面统一用 `AppButtons`（CLI 生成，返回 Material `ButtonStyle`）；
全站换色用 `WButtonTheme`，单个按钮用 `WButton(style: ...)`。
12.0 删除了 `WButtonStyle` / `WButtonStyleSet` / `WButtonMotion` /
`WButtonSemantics` / `WButtonContentBuilder` / `WButtonResolvedStyle`（以上均已删除）。

状态色：

```text
disabled / pressed / hovered / focused 由 Material ButtonStyle 解析
AppButtons 用 FilledButton.styleFrom / OutlinedButton.styleFrom 显式给 disabled 颜色
按钮按压反馈由 Material ink 负责；WButtonMotion 已删除
```

构造约束：

```text
content 与 label + icon 只能选一种
enabled=true 时至少提供 onTap 或 onLongPress
纯图标按钮必须提供 semanticLabel
```

常用状态：

```dart
WButton(
  label: '提交',
  loading: submitting,
  onTap: _submit,
)
```

纯图标按钮提供：

```dart
semanticLabel: '关闭'
```

## WButtonTheme

全站四态样式装一次即可；未覆盖的变体按 `ColorScheme` 派生：

```dart
theme: ThemeData(
  colorScheme: scheme,
  extensions: [
    WButtonTheme(
      filled: FilledButton.styleFrom(backgroundColor: brand),
      outlined: OutlinedButton.styleFrom(foregroundColor: brand),
      text: TextButton.styleFrom(foregroundColor: brand),
      danger: FilledButton.styleFrom(backgroundColor: scheme.error),
    ),
  ],
)
```

## WPressable

```dart
WPressable(
  onTap: _openDetail,
  child: Card(child: ...),
)
```

用于整卡、列表项等任意 child 点击；没有 button 语义。
需要按压缩放 / 透明度时用 `WPressable(effect: WPressEffect.scale)`。

## WFormButton

```dart
WFormButton(
  name: 'coupon',
  label: '请选择优惠券',
  onTap: (_, didChange) {
    _pickCoupon().then((value) {
      if (value != null) didChange(value);
    });
  },
)
```

用于把选择结果写进 `WFormController`，参与只读、边框错误和校验。

## 不要做

```text
不要用 WButton 包一个需要写表单值的字段
不要用 WFormButton 做普通“保存 / 提交”
不要用 GestureDetector 模拟 button 语义
不要用同一份可变 config 驱动多个 WFormButton
```
