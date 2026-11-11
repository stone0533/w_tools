# Changelog

## 0.2.0

### Added
- `E2eLogin.run(..., awaitAfterLogin: true)`：需要等导航完成再返回时显式开启；
  默认仍不阻塞（兼容 GetX `offAllNamed` 不 resolve 的场景）。

### Changed
- 默认只允许 **debug** 生效；profile 构建需显式 `--dart-define=E2E_PROFILE=1`，
  release 永远不生效，避免 profile 分发包意外自动登录。
- README / recipe 补生产入口 grep 守卫和 integration_test 命令。

### Breaking
- `E2eLogin.run` 签名新增可选 `awaitAfterLogin`：源码兼容，旧调用不需要改；
  公开 API 快照把方法签名变化视为 Breaking。

## 0.1.1

### Fixed
- `afterLogin` 不再阻塞登录结果：导航等善后动作失败只上报，不会把已成功的登录判成失败。
- `onError` 支持异步回调；回调自身抛错会被忽略，不再产生未处理异常。
- 收紧显式参数与平台命令校验，补齐异步错误边界（与 device 工具对齐）。

## 0.1.0

- 初始版本：端到端免登录入口。
