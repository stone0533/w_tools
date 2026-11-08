# ui 8.0 迁移

8.0 把 7.x 的 Config 过渡入口收口，并统一按钮 / 角标 / 通知的类型。

## 1. 删除 Config，改用 style / 直接字段

| 7.x | 8.0 |
|---|---|
| `WNavBar(config: WNavBarConfig(...))` | `WNavBar(style: WNavBarStyle(...))` |
| `WTabBar(config: WTabBarConfig(...))` | `WTabBar(style: WTabBarStyle(...))` |
| `WBadge(config: WBadgeConfig(...))` | `WBadge(position:, style:, showBadge:)` |
| `WClipRRect(config: WClipRRectConfig(...))` | `WClipRRect(borderRadius: ...)` |

`WTabBar` / `WNavBar` 的 `style` 都有默认值，不传即可。

## 2. 角标

```dart
// 7.x
WBadge(
  config: WBadgeConfig.topRight(top: 2, end: 2),
  badgeContent: Text('3'),
  child: icon,
);

// 8.0
WBadge(
  position: const WBadgePosition.topEnd(top: 2, end: 2),
  badgeContent: const Text('3'),
  child: icon,
);
```

- 默认样式改为 `ColorScheme.error` / `onError`；自定义用 `style: WBadgeStyle(...)`。
- 不再转出 `badges` 包的 `BadgePosition` / `BadgeStyle`。

## 3. 按钮

```dart
// 7.x
WButton(
  style: WButtonStyle(motion: WButtonMotion(effect: WButtonEffectType.scale)),
  label: '保存',
  onTap: save,
);

// 8.0
WButton(
  motion: const WButtonMotion(effect: WPressEffect.scale),
  label: '保存',
  onTap: save,
);
```

- `WButtonEffectType` → `WPressEffect`。
- `WButtonStyle.motion` / `.semantics` → `WButton.motion` / `.semantics`。
- `WButtonMetrics` / `WButtonStyle.metrics` 删除；布局字段仍在 `WButtonStyle`，尺寸预设用 `WButtonSize`。
- `WButtonStyles.of(context)` 返回 `WButtonStyleSet`，字段名不变（`primary` / `secondary` / `text` / `danger`）。

## 4. 通知

`WNotificationListenerBuilder` 删除：

```dart
// 7.x
WNotificationListenerBuilder<ScrollNotification>(child: list)
  .onNotificationPercentage((p) {})
  .build();

// 8.0
WNotificationListener<ScrollNotification>(
  onNotificationPercentage: (p) {},
  child: list,
);
```

## 5. 步骤条

- `WStepStyle.resolve` 返回 `WStepColors`（`completed` / `current` / `upcoming`）。
- 默认语义标签改为 `"<label> (<current>/<total>)"`；需要自定义时传 `semanticLabelBuilder`。

## 6. 其它

- `WPressable.excludeChildSemanticsWhenDisabled` → `hasChildSemanticsWhenDisabled`（默认 true）。
- `WAppBarStyle.copyWith` / `WStepStyle.copyWith` / `WButtonSize.copyWith` 传 null 表示保留，不能清空字段。
  背景在纯色与渐变之间切换改用 `withBackground(color:)` / `withBackground(gradient:)`。
- `WScaffold` 标题样式在未显式设置时优先 `WTextStyles.title`。
- `WWidgetExtension.withBottomBarSpace()` / `withTopSafeSpace()` 删除，改用
  `withBottomBarSpaceOf(context)` / `withTopSafeSpaceOf(context)`。
- `WButton.debugStyleResolutionCount` 删除（测试钩子）。
- `WActionRow` 改为 `StatelessWidget`（公开构造不变，`createState` 不再暴露）。
