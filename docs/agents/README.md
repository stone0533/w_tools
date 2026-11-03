# Agent 文档索引

## 各包首选入口（给人和 AI 的速查）

| 包 | 首选入口 | 不要用（已弃用 / 内部） | 示例 |
| --- | --- | --- | --- |
| core | `WStorage` / `WToken` / `WValidator` / `WLogger` / `WDebounce` | `WConfig`、`WUx.debounce/throttle`、`WRegExpPattern`（3.0 已删除） | `packages/core/example` |
| async | `WAsyncController` + `WAsyncView`；无 UI 用 `WAsync` + `WAsyncOptions` | `WAsyncConfig`、`WAsyncBuilder`、`WAsyncViewDefaults` | `packages/async/example` |
| ui | `WText` / `WButton` / `WImage` / `WScaffold` | `WRowButtons`、`HexColor`、`WRow/WColumn/WSizeBox`、`WImageConfig`（旧名） | `packages/ui/example` |
| form | `WForm` + 直接字段；边框 `WFormBorderConfig.fromTheme` | `Config.build`、`*Core`（`@internal`）、`WFormDefaults` | `packages/form/example` |
| api | `WApiConfig` + `DioRegistry`；`WLogInterceptor(parts:)` | 直接 `Dio()`、旧 bool 日志参数 | `packages/api/example` |
| app | `WApp.start()` + `WAppPlugin`；`WBottomSheet` | 手写 `runApp` 初始化顺序 | `packages/app/example` |
| toast | `WToast.showXxx` + `WToastStyle` + `WToastTheme` | `WToastConfig` | `packages/toast/example` |
| map | `WMap` + `WMapZone` + `WMapItemMapper` | 直接 `GoogleMap`；手改 `zone.markers` | `packages/map/example` |
| qr | `WQrView`（`onScanned` 或 `onQRViewCreated` 二选一） | 直接 `QRView` | `packages/qr/example` |

> 新项目只依赖具体子包（ADR-0002）；根包 `w_tools` 只用于快速体验。

- [Form 使用规则](form.md)
- [Button 使用规则](button.md)
- [UI 组件选择规则](ui.md)
- [Figma 取数与 Flutter 页面](figma.md)
- [Async 规则](async.md)（深入：[async_module](../modules/async_module.md)）
- [网络规则](api.md)（深入：[api_module](../modules/api_module.md)）
- [启动规则](app.md)（深入：[app_module](../modules/app_module.md)）
- [基础工具](core.md)（深入：[core_module](../modules/core_module.md)）
- [扫码规则](qr.md)（深入：[qr_module](../modules/qr_module.md)）
- [地图规则](map.md)（深入：[map_module](../modules/map_module.md)）
- [Toast 规则](toast.md)（深入：[toast_module](../modules/toast_module.md)）
- [组合用法](../recipes/README.md)：分页 / 登录刷新 / App 根装配
- [使用反馈](../feedback/README.md)：用 w_tools 撞到的问题按模板记录（`docs/feedback/<包>.md`）
- [Issue tracker](issue-tracker.md)
- [Triage labels](triage-labels.md)
- [Domain docs](domain.md)
> 这些文件属于 w_tools 维护仓库，`w_tools_cli:init` 不会把整个 docs/agents 目录复制到消费方。
> 消费方 AI 看到的是生成的 AGENTS 摘要；需要完整说明时读本仓库或对应包文档。
>
> 强制提交规则以根 [`AGENTS.md`](../../AGENTS.md) 为准，本索引只负责导航。

