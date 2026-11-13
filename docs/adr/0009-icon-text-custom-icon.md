> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0009：WIconText 自定义图标走静态构造器 + Widget，不引入 flutter_svg

- 状态：已采纳（2026-11-13）
- 相关：[`WIconText`](../../packages/ui/lib/src/components/text/icon_text.dart)、
  [ui 模块文档](../modules/ui_module.md)、[catalog](../../packages/cli/catalog/components.yaml)

## 背景

`WIconText` 目前只收 `IconData`，无法直接放 SVG / 资源图 / 品牌图标。常见诉求是：

```dart
WIconText(icon: Icons.star, text: '收藏');
// 想放 SvgPicture.asset('assets/star.svg') 或 Image.asset(...)
```

把 `icon` 从必填 `IconData` 改成可空 `IconData?` 并新增 `Widget? iconWidget` 最符合类型直觉，
但会让现有读取 `.icon` 的代码从非空变成可空，是 breaking change。直接引入 `flutter_svg`
作为 `w_tools_ui` 依赖也会把 SVG 渲染器的体积 / 平台问题带进所有消费方。

## 决策

1. **保持 `WIconText(icon: IconData)` 不变**：`icon` 继续必填、非空，不破坏现有读取方。
2. **新增静态构造器** `WIconText.custom({required Widget icon, ...})`，返回一个私有实现；
   参数与主构造器保持一致（`text` / `variant` / `style` / `color` / `gap` / `iconSize` /
   `iconColor` / `iconOffset` / `maxLines` / `overflow` / `semanticsLabel` 等）。
3. **不新增 `flutter_svg` 依赖**：调用方自己传 `SvgPicture.asset` / `Image.asset` /
   任意 `Widget`；`WIconText` 只负责行盒中点对齐、间距、语义与文本样式。
4. `iconSize` / `iconColor` 通过 `IconTheme` 传给自定义图标；SVG 等不读 `IconTheme` 的
   Widget 由调用方自行控制颜色 / 尺寸，文档写清。
5. **实现时共享布局**：主构造器与 `custom` 共用私有的 `_WIconTextLayout`，避免两套
   `Text.rich + WidgetSpan + PlaceholderAlignment.middle` 漂移。

## 后果

- 现有 `WIconText` 调用零改动；新增能力是纯 additive，可走 minor（10.2.0）。
- `WIconText.custom` 返回 `Widget` 而不是 `WIconText` 子类型，`find.byType(WIconText)`
  不会命中自定义图标；测试用 `find.text` / 目标 Widget 类型断言。
- 静态构造器不能 `const`；需要 const 的场景仍用 `WIconText(icon:)`。
- 不把 SVG 渲染器强加给所有消费方；需要 SVG 的项目自行添加 `flutter_svg`。

## 被否决的替代方案

| 方案 | 否决原因 |
|---|---|
| `icon` 改可空 + `iconWidget` | 类型最干净，但 `.icon` 变可空是 breaking；留到 11.0 再评估 |
| 新增公开类 `WIconTextWithWidget` | 多一个近似类型，命名与教学成本高 |
| `w_tools_ui` 直接依赖 `flutter_svg` | 所有消费方被迫带 SVG 渲染器；平台/体积成本高 |
| 在 `WIconText` 里塞一个占位 `IconData` + `Widget` | `icon` 字段语义错误，容易误用 |

## 落地结果

- 10.2.0 已实现：`WIconText.custom` + `_WIconTextLayout` 抽取 + 测试 / catalog / README。
- 主构造器仍为 `WIconText(icon: IconData)`；`custom` 返回私有实现，`find.byType(WIconText)`
  不命中，测试用文本 / 目标 Widget 断言。
