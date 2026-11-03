# Changelog

## 1.1.0

### Changed
- 默认样式跟随主题：文本气泡取 `colorScheme.inverseSurface`、文字取 `textTheme.bodyMedium` +
  `onInverseSurface`；成功 / 错误 / 警告 / 加载的默认内容同样从主题取色与字号。
- `WToastConfig.backgroundColor` 默认值改为 `null`：遮罩仍用中性半透明黑，文本气泡取主题反色
  （原先固定 `Colors.black38` / `Colors.black54` / 白字 17sp / 14sp）。
- 文本提示改用 `BotToast.showCustomText`（原生 `showText` 不接受 Builder，拿不到 Overlay 里的 Theme）。

## 1.0.0

首次发布。

- 新增 `WToastConfig`：时长、对齐、背景色、动画时长、关闭回调等统一配置
- 新增文本、成功、错误、警告、加载、自定义六种提示入口
- 加载提示全局唯一，重复调用会先关闭上一个
- 新增 `WToast.hideAll` / `WToastConfig.hideAll` 一次性清理全部提示
- 新增 `copy()` / `copyWith()` 配置复用
- 提示显示失败时通过 `onError` 上报，不向调用方抛异常
