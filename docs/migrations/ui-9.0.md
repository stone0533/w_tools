# ui 9.0 迁移

9.0 统一 `copyWith(null)` 的语义为「保留字段」，并清理不再产生的
`WImageErrorKind.empty`。

## 1. WImageStyle.copyWith

`copyWith` 的参数从 `Object?` 改为具体类型；**传 null 表示保留当前值**，不再清空。

| 8.x | 9.0 |
|---|---|
| `style.copyWith(width: null)` | `style.withoutWidth()` |
| `style.copyWith(height: null)` | `style.withoutHeight()` |
| `style.copyWith(aspectRatio: null)` | `style.withoutAspectRatio()` |
| `style.copyWith(borderRadius: null)` | `style.withoutBorderRadius()` |
| `style.copyWith(border: null)` | `style.withoutBorder()` |
| `style.copyWith(boxShadow: null)` | `style.withoutBoxShadow()` |
| `style.copyWith(margin: null)` | `style.withoutMargin()` |
| `style.copyWith(padding: null)` | `style.withoutPadding()` |
| `style.copyWith(semanticLabel: null)` | `style.withoutSemanticLabel()` |

`copyWith` 本身仍可用于修改值：

```dart
const style = WImageStyle(width: 120, height: 68);
final next = style.copyWith(width: 160); // width: 160, height: 68
final noWidth = style.withoutWidth();     // width: null, height: 68
```

## 2. WImageLoadOptions.copyWith

`memCacheWidth` / `memCacheHeight` 改为 `int?`；传 null 表示保留。

| 8.x | 9.0 |
|---|---|
| `options.copyWith(memCacheWidth: null)` | `options.withoutMemCacheWidth()` |
| `options.copyWith(memCacheHeight: null)` | `options.withoutMemCacheHeight()` |

其余字段（`gaplessPlayback` / `retryCount` / `retryDelay`）不变。

## 3. WImageErrorKind.empty

删除 `WImageErrorKind.empty`。空 data 从 8.1 起就不再产生该错误，继续用：

```dart
WImageSlots(
  emptyWidget: const Icon(Icons.image_not_supported),
  // 或 emptyBuilder
)
```

`WImageError.message` 仍是固定中文；`WImageErrorView` 的错误文案按当前 `Locale` 本地化。

## 4. 内置文案默认值

`WButtonSemantics.loadingLabel` / `WImageErrorView.retryLabel` 的默认值从固定中文改为
空字符串：空表示按当前 `Locale` 取内置文案（zh 中文 / 其他英文）。需要固定文案时继续
传非空字符串即可。

## 5. WScreen：从全局 delegate 到 scope

9.0 推荐在 App 根节点注入 `WScreenScope`，在 build 期用 `WScreen.of(context)` 取缩放：

```dart
// 9.0
WScreenScope(
  widthScaler: (v) => ScreenUtil().setWidth(v),
  heightScaler: (v) => ScreenUtil().setHeight(v),
  fontScaler: (v) => ScreenUtil().setSp(v),
  child: app,
);

final screen = WScreen.of(context);
screen.w(16); screen.h(24); screen.sp(14);
```

旧入口 `WScreen.w/h/sp` 与 `WScreen.delegateWidth/Height/Font` 已弃用（remove-in: 10.0.0）。
`WScreen.of` 在没有 scope 时会回退旧 delegate，迁移期可以逐个页面替换。
