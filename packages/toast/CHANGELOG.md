# Changelog

## 1.0.0

首次发布。

- 新增 `WToastConfig`：时长、对齐、背景色、动画时长、关闭回调等统一配置
- 新增文本、成功、错误、警告、加载、自定义六种提示入口
- 加载提示全局唯一，重复调用会先关闭上一个
- 新增 `WToast.hideAll` / `WToastConfig.hideAll` 一次性清理全部提示
- 新增 `copy()` / `copyWith()` 配置复用
- 提示显示失败时通过 `onError` 上报，不向调用方抛异常
