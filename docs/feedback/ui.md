# w_tools_ui 反馈

## 待处理

### [待处理] ui: WNavBar 默认项高 42（<48），底部导航点击区域偏小

- 包/版本：w_tools_ui 14.0.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：3 个 WNavDestination 的 WNavBar，量 WNavBar / WPressable 高度

```dart
WNavBar(
  controller: WNavController(length: 3),
  destinations: const [
    WNavDestination(icon: Icons.home, label: '首页'),
    WNavDestination(icon: Icons.person, label: '我的'),
    WNavDestination(icon: Icons.settings, label: '设置'),
  ],
)
// 实测：WNavBar 800x42；每个 WPressable 266.7x42
```

- 期望：底部导航每一项的点击区域至少 48 高（Material / 无障碍基线），或提供最小高度参数。
- 实际：默认项高 42（图标 24 + SizedBox 2 + labelSmall 16），整个 `WNavBar` 也是 42；`WPressable` 的点击区就是这 42。`WNavBar` 没有 `height` / `minItemHeight` / `tapTargetSize` 参数，`safeArea` 只加底部 inset。
- 影响：底部导航是最高频操作之一，42 比 48 少 6px，手指容易点到旁边或点空；和本项目按钮统一用 `WButtonSize.tapTargetSize=48` 的投入不一致。`WPressable` 文档也明确「不负责最小点击区域」，所以这里没有兜底。
- 建议：`WNavBar` 默认最小高度 48（或 Material 的 56），提供 `minItemHeight` / `padding`；补一个「item 高度 >= 48」的测试。
- 复现数据：WNavBar=42 高，每个 item 266.7×42

```text
navbar=Size(800.0, 42.0)
item 0: Size(266.7, 42.0)
item 1: Size(266.7, 42.0)
item 2: Size(266.7, 42.0)
label rect: Rect.fromLTRB(121.8, 584.0, 144.8, 600.0)
```

- 状态变更：2026-11-23 待处理

### [待处理] ui: WButton 设了 semanticLabel 时 loading 的 liveRegion 被排除，读屏听不到「加载中」

- 包/版本：w_tools_ui 14.0.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：WButton(semanticLabel: 保存, loading: true) + debugDumpSemanticsTree

```dart
WButton.filled(
  icon: Icons.save,
  semanticLabel: '保存',
  loading: true,
  onTap: () {},
)
// debugDumpSemanticsTree:
//   flags: isButton, hasEnabledState
//   label: "保存"      // 无 liveRegion / loading 子节点
// 不传 semanticLabel 时：
//   └─ liveRegion label: "Loading" / role: loadingSpinner
```

- 期望：传了 `semanticLabel` 时，loading 仍向读屏播报「加载中」（`loadingLabel` 文档承诺的读屏文案）。
- 实际：`WButton.build` 在有 `semanticLabel` / `semanticHint` 时用 `Semantics(..., excludeSemantics: true)` 包住按钮，把 `_buildButtonLoading` 里的 liveRegion 一起排除了；语义树只剩「保存 + disabled」，没有 loading 文案。纯图标按钮按断言要求必须传 `semanticLabel`，所以这个组合很常见。
- 影响：读屏用户点击提交后只听到按钮变成禁用态，不知道正在加载，可能反复尝试或以为无响应。
- 建议：有 `semanticLabel` 且 `loading` 时把 loading 文案并入 label（如 `'保存，加载中'`），或不要 exclude 内层 liveRegion；补一条 `matchesSemantics` 测试覆盖「semanticLabel + loading」。
- 复现数据：按钮语义 label=保存，无 liveRegion；不传 semanticLabel 时有 liveRegion "Loading"

```text
SemanticsNode flags: isButton, hasEnabledState
label: "保存"
（无 liveRegion 子节点）
不传 semanticLabel 时：子节点 flags: isLiveRegion, label: "Loading", role: loadingSpinner
```

- 状态变更：2026-11-23 待处理

### [待处理] ui: WButton 同时传 tooltip 和 onLongPress 时长按只显示后者，tooltip 永远不出现

- 包/版本：w_tools_ui 14.0.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：WButton(tooltip: 保存草稿, onLongPress: …) + tester.longPress

```dart
var longs = 0;
WButton.filled(
  label: '保存',
  tooltip: '保存草稿',
  onLongPress: () => longs++,
  onTap: () {},
)
await tester.longPress(find.byType(WButton));
// longs == 1, find.text('保存草稿') == 0
```

- 期望：`tooltip` 与 `onLongPress` 同时存在时，至少按文档能显示提示；或者明确互斥并在 debug assert。
- 实际：长按只触发 `onLongPress`，Tooltip 的长按识别器被按钮内的 `GestureDetector(onLongPress)` 抢走，提示永远不出现。`WButton.tooltip` 文档写「长按 / hover 提示」，在移动端长按是唯一入口。
- 影响：同时需要长按操作和提示的按钮（例如长按删除 + 提示说明），移动端用户看不到提示；桌面 hover 正常，所以只在手机暴露。
- 建议：检测 `tooltip != null && onLongPress != null` 时 debug assert 并文档写互斥，或把长按行为合并到 Tooltip 的触发链（例如 onLongPress 内同时 showTooltip），或提供 `tooltipTriggerMode`。
- 复现数据：longs=1，tooltipVisible=0

```text
longs=1 tooltipVisible=0
```

- 状态变更：2026-11-23 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
