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

```dart
WButton(
  style: AppButtons.primary(context),
  label: '保存',
  onTap: _save,
)
```

支持：

```text
label / icon
content / contentBuilder
size
loading / enabled
semanticLabel
onLongPress
```

按钮宽度：

```text
WButtonSize / WButtonStyle 不包含 width
width 由父布局决定
撑满用 SizedBox(width: double.infinity) 或 Expanded
固定宽度用外层 SizedBox(width: ...)
minWidth 只是最小视觉 / 点击尺寸，不是固定宽度
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
  style: AppButtons.secondary(context),
  label: '取消',
  onTap: _cancel,
)
```

### loading 提交

```dart
WButton(
  style: AppButtons.primary(context),
  label: '提交',
  loading: submitting,
  enabled: !submitting,
  onTap: _submit,
)
```

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

`WButtonStyle.alignment` 默认居中；需要左对齐时显式设置：

```dart
WButtonStyle(alignment: Alignment.centerLeft)
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
content            → 静态复杂内容
contentBuilder     → 需要读取最终 style / state
```

不要同时传 `label` 和 `content`。

`WButton` 没有 `variant` 参数，也没有 `WButtonVariant`；样式用 `style`。

项目页面统一用 `AppButtons`；组件示例/独立 Demo 才用 `WButtonStyles` 或 `WButtonStyle`。

> `WButton` 不传 `style` 时默认用 `WButtonStyles.of(context).primary`，颜色来自
> `ColorScheme`（`primary` / `onPrimary`、`error` / `onError`、`outline`）；旧静态预设已在 5.0 删除。
状态色：

```text
disabled / pressed / hovered / focused 由 AppButtons 的 WidgetStateProperty 解析
如果已有显式禁用色，设置 disabledOpacity: 1，避免二次变淡
hover 由 _bg 处理时，把 hoverColor 设为 transparent，避免主题 overlay 叠加
foregroundColor 会覆盖 textStyle.color
```



构造约束：

```text
content / contentBuilder / label+icon 只能选一种
enabled=true 时至少提供 onTap 或 onLongPress
```

常用状态：

```dart
WButton(
  label: '提交',
  loading: submitting,
  enabled: !submitting,
  onTap: _submit,
)
```

纯图标按钮提供：

```dart
semanticLabel: '关闭'
```

## WPressable

```dart
WPressable(
  onTap: _openDetail,
  child: Card(child: ...),
)
```

用于整卡、列表项等任意 child 点击；没有 button 语义。

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
