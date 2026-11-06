# Agent 文档索引

## 各包首选入口（给人和 AI 的速查）

| 包 | 首选入口 | 不要用（已弃用 / 内部） | 示例 |
| --- | --- | --- | --- |
| core | `WStorage` / `WToken` / `WValidator` / `WLogger` / `WDebounce` | `WConfig`、`WUx.debounce/throttle`、`WRegExpPattern`（3.0 已删除） | `packages/core/example` |
| async | 页面用 `WAsyncController` + `WAsyncView`；滚动页 / `SmartRefresher` 用 `WAsyncStateBuilder`；无 UI 用 `WAsync.tryRun` + `WAsyncResult`，或 `WAsync.run`（失败抛异常） | `WAsyncConfig`、`WAsyncBuilder`、`WAsyncViewDefaults`（3.0 已删除）；旧 `WAsync.run(onSuccess:)` / `runValue` / `WAsyncLoading` | `packages/async/example` |
| ui | `WText` / `WButton` / `WImage` / `WScaffold` | `WRowButtons`、`HexColor`、`WRow/WColumn/WSizeBox`、`WImageConfig`（5.0 已删除） | `packages/ui/example` |
| form | `WForm` + 直接字段；边框 `WFormBorderConfig.fromTheme` | `Config.build`、`*Core`（`@internal`）、字段 `config` 参数、`WFormDefaults`（4.0 已删除） | `packages/form/example` |
| api | `WApiConfig` + `DioRegistry`；`WLogInterceptor(parts:)` | 直接 `Dio()`、旧 bool 日志参数 | `packages/api/example` |
| app | `WApp.options(WAppOptions(...)).start()` + `WAppPlugin`；`WBottomSheet` | 手写 `runApp` 初始化顺序；`WApp.appWrapper`（字段在 `WAppOptions`） | `packages/app_getx/example` |
| toast | `WToast.showXxx` + `WToastStyle` + `WToastTheme` | `WToastConfig`（已删除） | `packages/toast/example` |
| map | `WMap` + `WMapZone` + `WMapItemMapper` | 直接 `GoogleMap`；手改 `zone.markers` | `packages/map_google/example` |
| qr | `WQrView`（`onScanned` 或 `onQRViewCreated` 二选一） | 直接 `QRView` | `packages/qr/example` |
| cli | `init` → 补依赖 → `doctor`；AI 用 `context` / `list` / `explain` | 手改生成物；业务代码按 `explain` 的子包 import 写 | [cli.md](cli.md) |
| device | `dart run w_tools_device:device ...` | 手写 adb / DeviceHub 标定 | [device-testing.md](device-testing.md) |
| e2e | `tool/main_e2e.dart` + `--dart-define=E2E=1` | 把 E2E 入口 import 进 `lib/main.dart` | [device-testing.md](device-testing.md) |

> 本表只做包级入口；具体组件 / 参数查 [`components.md`](../modules/components.md) 或 catalog。
> 新项目只依赖具体子包（ADR-0002）；根包 `w_tools` 只用于快速体验。
> 本表写的入口名必须能在该包规则页找到 —— `scripts/check_agents_consistency.py` 会检查。

## 包级规则

- [基础工具 core](core.md)（深入：[core_module](../modules/core_module.md)）
- [UI 组件选择](ui.md)
- [Button 选择](button.md)
- [Form 规则](form.md)（深入：[form_module](../modules/form_module.md)）
- [Async 规则](async.md)（深入：[async_module](../modules/async_module.md)）
- [网络规则](api.md)（深入：[api_module](../modules/api_module.md)）
- [启动规则](app.md)（深入：[app_module](../modules/app_module.md)）
- [Toast 规则](toast.md)（深入：[toast_module](../modules/toast_module.md)）
- [扫码规则](qr.md)（深入：[qr_module](../modules/qr_module.md)）
- [地图规则](map.md)（深入：[map_module](../modules/map_module.md)）

## 工具与工作流

- [CLI 使用规则](cli.md)
- [设备验证](device-testing.md)
- [Figma 取数与 Flutter 页面](figma.md)

## 仓库流程

- [Issue tracker](issue-tracker.md)
- [Triage labels](triage-labels.md)
- [Domain docs](domain.md)
- `workspace.yaml`：工具配置，不是文档

## 元文档

- [文档地图](../documentation-map.md)：每个文档写什么、信息该放哪
- [AI 使用契约](../ai-contract.md)：catalog / explain / AGENTS 的更新、检查与完整性边界
- [维护者 AI 提示词](../ai-maintainer-prompts.md)：按场景复制
- [ADR 索引](../adr/README.md)：历史决策、状态词与模板（改架构前先看有没有已定方案）
- [组合用法](../recipes/README.md)：分页 / 表单提交 / App 根装配
- [使用反馈](../feedback/README.md)：用 w_tools 撞到的问题按模板记录（`docs/feedback/<包>.md`）

> 这些文件属于 w_tools 维护仓库，`w_tools_cli:init` 不会把整个 docs/agents 目录复制到消费方。
> 消费方 AI 看到的是生成的 AGENTS 摘要；需要完整说明时读本仓库或对应包文档。
>
> 根 [`AGENTS.md`](../../AGENTS.md) 是入口与跨包硬规则；本目录是包级详细规则。
> 包级用法以本目录 + 对应包 README 为准，仓库提交门禁以 `AGENTS.md` 为准。

