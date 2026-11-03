# Changelog

## 2.0.0

### Removed
- `WToastConfig` 旧门面：用 `WToastStyle` + `WToast.showXxx`。

## 1.3.0

### Added
- `WToastTheme`：在 App 根部设置默认 `WToastStyle`；`WToast.showXxx(..., context: context)`
  自动解析（显式 `style:` 仍最高优先）。`WToastStyle.of(context)` 直接读取。
- `WToast.runWithLoading(task, {message, successMessage, errorMessage})`：
  显示 loading → 执行 → 关闭 → 结果提示；失败先提示再 `rethrow`。

### Changed
- `WToast.showXxx` 的 `style` 参数改为可空（不传时按 context / 默认解析），调用方代码不变。

## 1.2.0

### Added
- `WToastStyle`：不可变样式（时长 / 对齐 / 背景 / 动画 / 5 个 builder / 回调），
  `copyWith` 传 `null` 可清空。
- `WToast.showSuccess` / `showError` / `showWarning` / `showCustom` / `showLoading` /
  `hideLoading` 静态入口，统一接受 `style:`。

### Changed
- `WToast.showLoading` 使用 `style.align`，不再硬编码居中。

### Deprecated
- `WToastConfig`：1.2 起用 `WToastStyle` + `WToast.showXxx`；2.0 移除。旧类内部已改为
  转成 `WToastStyle` 后调用 `WToast`。

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
