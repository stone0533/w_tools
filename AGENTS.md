# Agent instructions

## 组件约定

新页面表单默认使用 `WForm` + 直接字段（`WFormTextField` 等），不要从 `Config.build` 开始（3.2 起 `build` / `*Core` 为 `@internal`，不导出）；详见 [`docs/agents/form.md`](docs/agents/form.md)。

按钮、图片、页面骨架和弹层的组件选择规则，以及各包「首选入口 / 不要用」速查，见 [`docs/agents/README.md`](docs/agents/README.md)。

- 普通业务按钮用 `WButton`；任意 child 点击用 `WPressable`；表单字段值选择用 `WFormButton`。

改动 `packages/*` 里的组件前：先读 [`CONTRIBUTING.md`](CONTRIBUTING.md)（新增组件的 4 条硬性要求），
再查 [`docs/modules/components.md`](docs/modules/components.md)（有没有现成的、别重复造），
接口设计原则见 [`docs/conventions.md`](docs/conventions.md) §6。

> 消费方项目的接入方式（聚合入口、暂存层、`AGENTS.md` 片段）**不要**写进本文件 ——
> 那些由 `dart run w_tools_cli:init` 生成到**对方**仓库里；本文件只管「在本仓库怎么改」。

## 根包（w_tools）

- `w_tools` 根包只用于快速体验 / 旧项目兼容；新业务项目仍只依赖具体子包。
- 如用户明确要求使用根包：`import 'package:w_tools/w_tools.dart';`。
- 根包只重导出 6 个基础子包（core / async / ui / form / api / toast）；app / map / qr 不聚合；不再提供旧 `WConfig` 兼容层。
- 配置走子包：token 键名用 `WToken`（`WConfig` 已在 3.0 删除），资源前缀用 `WAssets`，表单图标用 `WFormIcons`，语言用 `WAppConfig`。

## 工具（本仓库维护）

CLI 在 **`packages/cli/`（包名 `w_tools_cli`，纯 Dart）**：
入口 `packages/cli/bin/w_tools.dart`（统一 dispatcher）与 `packages/cli/bin/{init,doctor,context,list,explain,feedback}.dart`（兼容），
使用规则见 [`docs/agents/cli.md`](docs/agents/cli.md)，
实现分别在 `packages/cli/lib/src/init/`、`lib/src/doctor/`、`lib/src/context/`、`lib/src/catalog/`。

改动它们时必须同步：

- 本仓库内反馈用 `dart run w_tools_cli:feedback submit ... --ledger`（自动维护 `docs/feedback/` 与索引）；消费方用 issue 入口
- [`docs/conventions.md`](docs/conventions.md) §7 的规则表（doctor 的 R1~R9）
- [`docs/modules/components.md`](docs/modules/components.md)（若涉及组件建议）
- `packages/cli/test/init_test.dart` / `doctor_test.dart` 的用例
- `packages/cli/CHANGELOG.md`

**改了 `DoctorConfig` 的默认值**必须同步 `renderDefaultConfig()`（`doctor --print-config` 的输出），
`packages/cli/test/config_render_test.dart` 会挡住漂移。

**改了 `packages/cli/templates/` 下的模板文件后必须跑**（在 `packages/cli/` 下）：

```bash
dart run tool/gen_templates.dart
```

生成 `lib/src/init/templates.g.dart`，否则 `test/templates_fresh_test.dart` 会红 ——
这是有意的：模板只允许有一份来源（`templates/`）。

**改了 `packages/cli/catalog/components.yaml` 后必须跑** `dart run tool/gen_catalog.dart`
（生成 `lib/src/catalog/catalog.g.dart` 和 `docs/modules/components.md` 的 §1~§9 表格），
否则 `test/catalog_test.dart` 会红 —— 组件目录同样只允许有一份来源。

CLI 是纯 Dart 包：测试用 `dart test`，发布用 `dart pub publish`（`scripts/publish_package.sh` 会自动识别）。

设备验证工具：`packages/device`（`w_tools_device`）与 `packages/e2e`（`w_tools_e2e`）。
需要模拟器 / Android / 真机截图、点击、稳定等待或 E2E 自动登录时，先读
[`docs/agents/device-testing.md`](docs/agents/device-testing.md)，不要手写 adb / DeviceHub 标定。

Figma 取数工具在 `packages/figma/`（`w_tools_figma`，独立 CLI 包）。需要设计稿规格 / token / diff 时，
先看 [`docs/agents/figma.md`](docs/agents/figma.md)，不要直接手写 Figma API 调用。

## 使用反馈（遇到问题先查再记）

用 `w_tools_*` 时撞到问题，**先查重，再提交** —— 这是完善 w_tools 的主要输入。

### 本仓库内（维护者 / 仓库 AI）

```bash
dart run w_tools_cli:feedback search "<关键词>" --package=<包>
dart run w_tools_cli:feedback submit \
  --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md --ledger
```

`--ledger` 只在仓库检出可用：自动追加 `docs/feedback/<包>.md`、缺失包建档、同步索引；
不要手改索引，不要标 `已修复`（发布后由维护者补版本号）。

### 消费方项目

- 默认关闭：不写文件、不生成链接、不建 Issue；
- 需要反馈时在 `.w_tools_doctor.yaml` 设置：
  ```yaml
  feedback:
    issue: true
  ```
- 然后：
  ```bash
  dart run w_tools_cli:feedback submit \
    --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md --issue
  ```
- `--issue` 需要已安装 gh（gh 读取 `GH_TOKEN` / `GITHUB_TOKEN`，或 `gh auth login`）；
- 消费方**不要**直接改 `docs/feedback/`（没有索引维护能力）。

### 规则

- 必填：包/版本、环境、命令、期望、实际、影响、建议、复现数据；
- 状态只写 `待处理`，不要自己标「已修复」；
- 一次会话最多 3–5 条，只记真正卡住的；
- 提交前跑 `bash scripts/check_feedback.sh`（已闭环版本号、索引数量一致）。

## Agent skills

### Issue tracker

GitHub Issues in `stone0533/w_tools`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

single-context — one root `GLOSSARY.md` shared by the app and all packages, with architecture decisions in `docs/adr/`. See `docs/agents/domain.md`.

### Tests

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立 `flutter test` / 发布。根 `test/` 只留聚合契约（`w_tools.dart` 的重导出）。`packages/cli` 是纯 Dart 包，用 `dart test`。CI 用矩阵逐包跑 analyze / test / `pub publish --dry-run`。

### 文档

改 `docs/` 后跑 `bash scripts/check_docs.sh`（检查相对链接、旧命令、包清单；CI 也会跑）。

### Release

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。子包与聚合包版本独立，根包的 `^x.y.z` 约束必须覆盖子包当前版本（`w_tools_cli` 是独立工具包，根包不依赖它，不在此列）。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。


## 启动与主题（ScreenUtil / WTextStyles）

- 不要在 `main()`、顶层 `final` 或 `static final` 中调用 `flutter_screenutil` 的 `.sp`；此时 `ScreenUtil` 还没 `configure`。
- `WTextStyles` / Theme 扩展如果使用 `.sp`，应在 `ScreenUtilInit.builder` 或 `WAppPlugin.builderWrapper` 的 build 期构建。
- `WAppPlugin.wrapApp` 位于 MaterialApp 外，没有 Theme/MediaQuery；需要 Theme 的排版扩展用 `builderWrapper`。
- `WAsyncTheme` 只存 builder，可以放 `wrapApp`；不要把“放到根节点”套到需要立即计算 `.sp` 的 Theme 对象上。

## 文字（w_tools_ui）

- 新代码用 `WText(variant: WTextVariant.xxx)` + `WTextStyles`；`WTextConfig` 已移除。
- 字体/字号/字重/行高统一放 `WTextStyles` / `TextTheme`。
- 局部用 `style` / `color` / `maxLines` / `overflow` / `textScaler` 覆盖。
- 先复用已有 variant（含 `price` / `number` / `badge`）；同一语义角色跨至少 2 个页面、合计 3 次以上才考虑提升为库内 variant；消费方不能自行新增 enum；新增 variant 需按 breaking change 评估。详见 [`docs/agents/ui.md`](docs/agents/ui.md)。
- 多字体优先 `fontFamilyFallback`；同一段主动混排用 `Text.rich` + `WTextStyles`。

## 异步区块（w_tools_async）

- 页面展示异步结果：`WAsyncController` + `WAsyncView`。
- 不要手写 `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
- 每个独立区块一个 Controller；不要用一个 `WAsyncActivity` 合并多个独立区块的 Loading。
- 全局默认 loading / empty / error 用 `WAsyncTheme`；放在 App 根节点（推荐 `WAppOptions.appWrapper`，或消费方自建插件的 `wrapApp`），不要只放 `AppScaffold.body`。
- 普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`，不要把 `SmartRefresher` 包在 `WAsyncView` 外面。
- `WAsyncStateBuilder.builder` 必须始终返回同一个 `SmartRefresher + CustomScrollView`；loading / empty / error 只能作为 slivers 分支，不能在外层切换成 `Center` / `WAsyncErrorView`。
- `WAsyncTheme` 的普通 builder 只作用于 `WAsyncView`；`WAsyncStateBuilder` 由调用方自行构建状态 UI，不读默认值 —— 需要默认值时用 `WAsyncThemeViews.of(context)`。
- Sliver 页面默认视图用 `WAsyncTheme` 的 `sliver*Builder`；loading/empty/error 必须是非滚动 Widget，`refreshingSliverBuilder` 必须返回 sliver。
- 分页使用 `WAsyncPagedController`；`loadMore` 失败写 `loadMoreError` / footer，不要用 `WAsyncController.failed` 替换列表；footer 用 `hasMoreListenable` 判断「加载更多 / 没有更多」。
- `CustomScrollView` 的四态填充优先用 `WAsyncStateSliver`；`readySliverBuilder` 必须返回 sliver。
- `WAsyncStateSliver` 默认不添加 refreshing 进度条；由外层 SmartRefresher 负责，需要额外进度时显式传 `refreshingSliverBuilder`。
- `WAsyncStateSliver.onRetry` 为 null 时失败态不渲染重试按钮，也不调用自定义 error / banner builder（它们的契约要求可用的 retry）。
- `WAsyncController` / `WAsyncPagedController` 会把所有异常转为 failed，并统一回调 `options.onError`；`load()` / `refresh()` 会取消上一次的 `WCancelToken`，`dispose()` 也会取消。
- 取消是协作式的：只有 `withToken` 构造的 loader 能拿到 `WCancelToken` 并主动检查；取消会让等待尽快结束（返回 null），但不中止底层 Future。
- `WAsync` / `WAsyncOptions` / `WAsyncActivity` / `WCancelToken` 只在不需要 UI 状态时直接使用；
  要结果用 `WAsync.tryRun`（返回 `WAsyncResult`）或 `WAsync.run`（失败抛异常）；控制器的四态与 `options.activity` 不要同时用来表示同一个 Loading（控制器会断言）。

## 网络（w_tools_api）

- 统一用 `WApiConfig` + `DioRegistry.forBaseUrl`，不要直接 `Dio()`；同一 `baseUrl` 只初始化一次，命中后传入**不同** options / interceptors 会抛 `ArgumentError`（需要换配置先 `dispose`）。
- Token 存储用 `w_tools_core` 的 `WToken`；`WTokenInterceptor` 只通过 `tokenGetter` / `tokenClearer` / `tokenRefresher` 注入，不负责存储。
- 401 重试只复用已知 Dio：`DioRegistry` 自动绑定；自行 `Dio()` 必须构造传 `dio: dio`，否则不会重试（也不会隐式注册实例）。
- 日志用 `WLogInterceptor`；默认脱敏 `Authorization` / `Cookie` / `Set-Cookie` / `X-Api-Key`，不要依赖它做业务错误处理。

## 启动（w_tools_app_getx）

- 项目入口用 `WApp.options(WAppOptions(...)).start()`，不要手写 `runApp` + 初始化顺序；`start()` = `init()` + `run()`，只调用一次，重复调用会再次 `runApp`。
- 插件实现 `WAppPlugin`（消费方自建；子包不自带插件）；有初始化顺序要求时用 `dependsOn` 显式声明，不要依赖注册顺序。
- `builderWrapper` 位于 MaterialApp 内；`wrapApp` 位于 MaterialApp 外，没有 Theme / MediaQuery。
- `WRouteObserver` 由 `WApp` 自动追加，不要重复添加。
- 多语言用 `WLanguage().changeLanguage(...)`，监听 `languageStream`；语言真源是 `WAppConfig.currentLanguage`。

## 基础工具（w_tools_core）

- `WStorage` 读方法前必须 `await WStorage.init()`；未初始化读取会抛 `StateError`。
- `WStorage` / `WToken` 使用 SharedPreferences，是明文存储，不是安全存储；高敏感数据用 Keychain / Keystore。
- `WValidator` 负责业务语义校验；纯正则匹配 / 提取用 `WRegExp`，不要再手写重复正则。
- 日志统一用 `WLogger.i/d/w/e`；不要直接 `print`。
- `WEncrypt` 的 AES-CBC 不提供完整性 / 认证；需要防篡改时用 AES-GCM。

## 扫码（w_tools_qr）

- 扫码用 `WQrView`，不要直接使用 `qr_code_scanner_plus` 的 `QRView`。
- 默认 `scanOnce = true`；需要连续扫描显式传 `false`。只监听数据流 / 用 `onQRViewCreated` 时必须 `scanOnce: false`（构造有 assert）。
- 单次扫码完成后需要重新扫描时，通过 `GlobalKey<WQrViewState>` 调用 `restartScan()`。
- 相机权限：Android `CAMERA`，iOS `NSCameraUsageDescription`。
- `onScanned` 只在 `Barcode.code` 非空时触发。

## 地图（w_tools_map + w_tools_map_google）

- 地图用 `WMap` + `WMapZone`（来自 `w_tools_map_google`），数据模型用 `w_tools_map`；不要直接使用 `GoogleMap`。
- Google Maps 需要 Android / iOS API Key；地图只在启用 `--with-map` 时引入。
- `markerId` 必须稳定；不要用 `hashCode` 生成。
- `json_serializable` 模型用 `WMapItemMapper` 取字段，避免改生成代码。
- 业务 UI 选中 / 关闭 marker 用 `WMapController.select` / `closeSelection`。
