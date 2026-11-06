# ui 7.0 迁移：WImage 配置收敛

7.0 把 WImage 的公开面做了一次集中清理。核心入口仍是 `WImage.source` + `WImageSource`，
行为修复见 [`packages/ui/CHANGELOG.md`](../../packages/ui/CHANGELOG.md)。

## 1. 配置类型更名

| 6.x | 7.0 |
|---|---|
| `WImageLoadConfig(...)` | `WImageLoadOptions(...)`（只保留行为字段） |
| `config: WImageLoadConfig()` | `options: const WImageLoadOptions()` + `slots:`（7.0 起只接受 `options:`） |

行为字段（`memCacheWidth` / `retryCount` / `gaplessPlayback` 等）仍在
`WImageLoadOptions`；占位 / 错误 / 进度 / 重试 UI 移到 `WImageSlots`：

```dart
// 6.x
WImage.source(
  source: ...,
  config: const WImageLoadConfig(
    retryCount: 1,
    placeholder: _placeholder,
    showRetryButton: true,
  ),
)

// 7.0
WImage.source(
  source: ...,
  options: const WImageLoadOptions(retryCount: 1),
  slots: const WImageSlots(
    placeholder: _placeholder,
    showRetryButton: true,
  ),
)
```

旧名不保留；7.0 也不保留 `config:` 别名。

## 2. 默认作用域收窄

`WImageDefaultsScope` 删除，改用 `WImageTheme` + `WImageSlots`：

```dart
// 6.x
WImageDefaultsScope(
  defaults: WImageLoadConfig(
    placeholderBuilder: _placeholder,
    errorWidgetBuilder: _error,
    progressBuilder: _progress,
  ),
  child: app,
)

// 7.0
WImageTheme(
  slots: WImageSlots(
    placeholderBuilder: _placeholder,
    errorWidgetBuilder: _error,
    progressBuilder: _progress,
  ),
  child: app,
)
```

`WImageSlots` 接收占位 / 错误 / 进度的 builder 或固定 Widget，以及
`showRetryButton` / `retryLabel`。行为字段（`retryCount`、`memCacheWidth` 等）仍在
**单张图**的 `WImageLoadOptions`；scope 不会静默覆盖它们。

优先级：

```text
单图 slots 的非空字段 > WImageTheme 同名字段 > 内置兜底
```

> 4.x 曾有一个 `WImageTheme`（承载加载配置），已在 4.3 删除；7.0 的 `WImageTheme`
> 是**新类型**，只承载 `WImageSlots`，不要按旧语义传 `defaults` / `WImageLoadOptions`。

## 3. 删除的旧成员

| 旧 API | 替代 |
|---|---|
| `WImage.type` | `image.source.type` |
| `WImage.data` | `image.source.raw` |
| `WImageStyle.merge(other)` | 用 `copyWith(...)` 逐字段覆盖 |
| `WImageDefaultsScope` | `WImageTheme(slots: WImageSlots(...))` |
| `WImageSlots.isEmpty` | 无（未使用，直接删除） |

`WImageStyle.merge` 之前无法区分“未设置”和默认值（`fit` / `alignment` / `filterQuality`
会被空样式覆盖），且没有内部调用方；7.0 删除。

## 4. Controller 状态

`WImageController.state` 现在是非空 `ValueListenable<WImageLoadSnapshot>`，创建时即为 `idle`：

```dart
// 6.x
controller.state?.addListener(...);
expect(controller.state!.value.attempt, 0);

// 7.0
controller.state.addListener(...);
expect(controller.state.value.isIdle, isTrue);
controller.dispose();
```

`WImageLoadStatus` 新增 `idle`；`WImageLoadSnapshot.status` 不再可空。

## 5. 预加载

`WImageSource` 新增 `resolve`，与 `WImage` 使用同一套 decode / network 参数：

```dart
final provider = await WImageSource.asset('logo.png').resolve(
  memCacheWidth: 240,
  memCacheHeight: 240,
);
await precacheImage(provider, context);
```

## 6. 行为变化

- `gaplessPlayback` 现在真正生效：换 source 时保留上一帧，重试时仍回到占位。
- `borderRadius + border` 的边框改为绘制在图片之上（之前会被图片盖住）。
- `aspectRatio` 作用在图片内容上，padding/margin 在外层；不能再和固定 `width` / `height`
  同时设置。
- `WImageErrorView` 小尺寸优先显示重试按钮；160×90 这类尺寸现在可看到重试。
- `WImageProgress` 新增 `isComplete` / `WImageProgress.complete()`；完成时不再伪造 1/1 字节。
- `retryDelayMs` 现在是实际排队延迟（含抖动），不是基础间隔。
- `onProgress` 对相同进度只回调一次；进度变化不再触发 WImage 整棵子树重建。
- controller 状态通知在 build 期会延后到 post-frame，外部监听器可以安全 `setState`。
- `WStepStyle.completedColor` / `currentColor` / `upcomingColor` 现在可空；未设置时取
  `ColorScheme.primary` / `primary` / `outline`。6.1.1 的默认是 `Colors.blue` / `Colors.grey`，
  需要固定颜色时显式传入。
- `WGradientCircularProgressIndicator.backgroundColor` 现在可空；未设置时取
  `ColorScheme.surfaceContainerHighest`。6.1.1 固定为 `0xFFEEEEEE`，需要固定颜色时显式传入。
- `WTabBar` 未配置 `overlayColor` 时不再强制透明，交给 `TabBarTheme` / Material 默认。


## 7. 扩展改名

7.0 按 `Extension` 角色统一了早期扩展名；旧扩展不保留别名（同名实例方法会冲突）：

| 6.x / 7.0 工作区 | 7.0 |
|---|---|
| `WImageStyleX` | `WImageStyleExtension` |
| `WHexColor` | `WColorExtension`（静态入口改为 `WColorExtension.fromHex`） |
| `WTextStylesThemeData` | `WThemeDataExtension` |
| `WNotificationListenerBuilderExtension` | 删除；用 `WNotificationListener` 包住 child |

`'#RRGGBB'.toColor()` 仍可用，内部改为 `WColorExtension.fromHex`。
