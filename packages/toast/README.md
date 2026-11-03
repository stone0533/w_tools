# w_tools_toast

[![pub package](https://img.shields.io/pub/v/w_tools_toast.svg)](https://pub.dev/packages/w_tools_toast)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_toast` 是 w_tools 的轻量提示层，基于 `bot_toast` 封装文本、成功、错误、警告、加载与自定义提示。

## 特性

- 统一配置：时长、对齐、背景色、动画时长、关闭回调
- 六种入口：`showText` / `showSuccess` / `showError` / `showWarning` / `showLoading` / `showCustom`
- 加载提示全局唯一，重复调用会先关闭上一个
- `copy()` / `copyWith()` 复用配置
- 显示失败时不会抛异常，可通过 `onError` 观测

## 安装

```yaml
dependencies:
  w_tools_toast: ^1.3.0
```

先在 `MaterialApp` 上完成 BotToast 初始化（只做一次）：

```dart
MaterialApp(
  builder: BotToastInit(),
  navigatorObservers: [BotToastNavigatorObserver()],
  ...
);
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:w_tools_toast/w_tools_toast.dart';

WToast.showSuccess('保存成功');
WToast.showError('网络异常');
WToast.showLoading();
WToast.hideAll();
```

自定义样式（可复用）：

```dart
final style = WToastStyle.defaults.copyWith(
  duration: const Duration(seconds: 3),
  align: Alignment.bottomCenter,
);
WToast.showSuccess('保存成功', style: style);
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 文本提示 | `WToast.showText` |
| 成功 / 错误 / 警告 | `WToast.showSuccess` / `showError` / `showWarning` |
| 加载 | `WToast.showLoading` / `hideLoading` |
| 自定义 | `WToast.showCustom` / `showCustomDialog` |
| loading + 结果提示 | `WToast.runWithLoading` |
| 关闭全部 | `WToast.hideAll` |
| 样式复用 | `WToastStyle`（不可变，`copyWith`） |

> `WToastConfig` 已在 2.0 删除；用 `WToastStyle` + `WToast.showXxx`。

## 全局默认样式

```dart
WToastTheme(
  style: WToastStyle.defaults.copyWith(duration: const Duration(seconds: 3)),
  child: MaterialApp(...),
)

WToast.showSuccess('保存成功', context: context);
```

`runWithLoading` 可把「loading → 执行 → 结果提示」收成一行：

```dart
await WToast.runWithLoading(
  () => api.save(),
  message: '保存中...',
  successMessage: '保存成功',
);
```

## License

MIT

## 示例

最小可运行示例见 [`example/`](example/)。
