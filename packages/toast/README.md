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
  w_tools_toast: ^1.0.0
```

同时请按 `bot_toast` 文档完成初始化（`BotToastInit` 与 `BotToastNavigatorObserver`）。

> 本包最低要求 Flutter 3.27.0。

## 快速开始

```dart
import 'package:w_tools_toast/w_tools_toast.dart';

final toast = WToastConfig();

toast.showSuccess('保存成功');
toast.showError('网络异常');
toast.showLoading();
toast.hideAll();
```

自定义样式：

```dart
final toast = WToastConfig()
  ..duration = const Duration(seconds: 3)
  ..align = Alignment.bottomCenter;
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 文本提示 | `WToast.showText` / `WToastConfig.showText` |
| 成功 / 错误 / 警告 | `WToastConfig.showSuccess` / `showError` / `showWarning` |
| 加载 | `WToastConfig.showLoading` |
| 自定义 | `WToastConfig.showCustom` |
| 关闭全部 | `WToast.hideAll` / `WToastConfig.hideAll` |
| 配置复制 | `WToastConfig.copy` / `copyWith` |

## License

MIT
