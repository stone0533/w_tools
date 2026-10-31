# Agent instructions

## 组件约定

新页面表单默认使用 `WForm` + 直接字段（`WFormTextField` 等），不要从 `Config.build` 开始；详见 [`docs/agents/form.md`](docs/agents/form.md)。

按钮、图片、页面骨架和弹层的组件选择规则见 [`docs/agents/README.md`](docs/agents/README.md)。

- 普通业务按钮用 `WButton`；任意 child 点击用 `WPressable`；表单字段值选择用 `WFormButton`。

改动 `packages/*` 里的组件前：先读 [`CONTRIBUTING.md`](CONTRIBUTING.md)（新增组件的 4 条硬性要求），
再查 [`docs/modules/components.md`](docs/modules/components.md)（有没有现成的、别重复造），
接口设计原则见 [`docs/conventions.md`](docs/conventions.md) §6。

> 消费方项目的接入方式（聚合入口、暂存层、`AGENTS.md` 片段）**不要**写进本文件 ——
> 那些由 `dart run w_tools_cli:init` 生成到**对方**仓库里；本文件只管「在本仓库怎么改」。

## 工具（本仓库维护）

CLI 在 **`packages/cli/`（包名 `w_tools_cli`，纯 Dart）**：
入口 `packages/cli/bin/{init,doctor,context,list,explain}.dart`，
实现分别在 `packages/cli/lib/src/init/`、`lib/src/doctor/`、`lib/src/context/`、`lib/src/catalog/`。

改动它们时必须同步：

- [`docs/conventions.md`](docs/conventions.md) §7 的规则表（doctor 的 R1~R8）
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
（生成 `lib/src/catalog/catalog.g.dart`），否则 `test/catalog_test.dart` 会红 ——
组件目录同样只允许有一份来源。

CLI 是纯 Dart 包：测试用 `dart test`，发布用 `dart pub publish`（`scripts/publish_package.sh` 会自动识别）。

## Agent skills

### Issue tracker

GitHub Issues in `stone0533/w_tools`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

single-context — one root `GLOSSARY.md` shared by the app and all packages, with architecture decisions in `docs/adr/`. See `docs/agents/domain.md`.

### Tests

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立 `flutter test` / 发布。根 `test/` 只留聚合契约（`w.dart` 的重导出、`WConfig` 兼容层）。`packages/cli` 是纯 Dart 包，用 `dart test`。CI 用矩阵逐包跑 analyze / test / `pub publish --dry-run`。

### 文档

改 `docs/` 后跑 `bash scripts/check_docs.sh`（检查相对链接、旧命令、包清单；CI 也会跑）。

### Release

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。子包与聚合包版本独立，根包的 `^x.y.z` 约束必须覆盖子包当前版本（`w_tools_cli` 是独立工具包，根包不依赖它，不在此列）。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。


## 启动与主题（ScreenUtil / WTextStyles）

- 不要在 `main()`、顶层 `final` 或 `static final` 中调用 `flutter_screenutil` 的 `.sp`；此时 `ScreenUtil` 还没 `configure`。
- `WTextStyles` / Theme 扩展如果使用 `.sp`，应在 `ScreenUtilInit.builder` 或 `WAppPlugin.builderWrapper` 的 build 期构建。
- `WAppPlugin.wrapApp` 位于 MaterialApp 外，没有 Theme/MediaQuery；需要 Theme 的排版扩展用 `builderWrapper`。
- `WAsyncViewDefaults` 只存 builder，可以放 `wrapApp`；不要把“放到根节点”套到需要立即计算 `.sp` 的 Theme 对象上。

## 文字（w_tools_ui）

- 新代码用 `WText(variant: WTextVariant.xxx)` + `WTextStyles`；`WTextConfig` 已移除。
- 字体/字号/字重/行高统一放 `WTextStyles` / `TextTheme`。
- 局部用 `style` / `color` / `maxLines` / `overflow` / `textScaler` 覆盖。
- 多字体优先 `fontFamilyFallback`；同一段主动混排用 `Text.rich` + `WTextStyles`。

## 异步区块（w_tools_async）

- 页面展示异步结果：`WAsyncController` + `WAsyncView`。
- 不要手写 `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
- 每个独立区块一个 Controller；不要用一个 `WAsyncConfig` 合并多个独立区块的 Loading。
- 全局默认 loading / empty / error 用 `WAsyncViewDefaults`；放在 App 根节点（推荐 `WAppPlugin.wrapApp` / `WApp.appWrapper`），不要只放 `AppScaffold.body`。
- 普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`，不要把 `SmartRefresher` 包在 `WAsyncView` 外面。
- `WAsyncStateBuilder.builder` 必须始终返回同一个 `SmartRefresher + CustomScrollView`；loading / empty / error 只能作为 slivers 分支，不能在外层切换成 `Center` / `WAsyncErrorView`。
- `WAsyncViewDefaults` 只作用于 `WAsyncView`，不作用于 `WAsyncSliverDefaults` / `WAsyncStateBuilder`。
- Sliver 页面默认视图用 `WAsyncSliverDefaults`；loading/empty/error 必须是非滚动 Widget，`refreshingSliverBuilder` 必须返回 sliver。
- `WAsyncBuilder` 是 `WAsyncStateBuilder` 的兼容别名，新代码使用后者。
- 分页使用 `WAsyncPagedController`；`loadMore` 失败写 `loadMoreError` / footer，不要用 `WAsyncController.failed` 替换列表。
- `CustomScrollView` 的四态填充优先用 `WAsyncStateSliver`；`readySliverBuilder` 必须返回 sliver。
- `WAsyncStateSliver` 默认不添加 refreshing 进度条；由外层 SmartRefresher 负责，需要额外进度时显式传 `refreshingSliverBuilder`。
- `WAsyncController` 会把所有异常转为 failed；只丢弃旧请求，不中止底层 Future。
- 需要中止请求时，由 loader 接收 `WCancelToken`。
- `WAsync` / `WAsyncConfig` / `WCancelToken` 只在不需要 UI 状态时直接使用。

## 网络（w_tools_api）

- 统一用 `WApiConfig` + `DioRegistry.forBaseUrl`，不要直接 `Dio()`；同一 `baseUrl` 只初始化一次，后续传入的 options / interceptors 会被忽略。
- Token 存储用 `w_tools_core` 的 `WToken`；`WTokenInterceptor` 只通过 `tokenGetter` / `tokenClearer` / `tokenRefresher` 注入，不负责存储。
- 401 重试依赖 `DioRegistry`；自行 `Dio()` 创建的实例重试会走另一个 registry 实例。
- 日志用 `WLogInterceptor`；默认脱敏 `Authorization` / `Cookie` / `Set-Cookie` / `X-Api-Key`，不要依赖它做业务错误处理。

## 启动（w_tools_app）

- 项目入口用 `WApp.start()`，不要手写 `runApp` + 初始化顺序；`start()` = `init()` + `run()`，只调用一次，重复调用会再次 `runApp`。
- 插件实现 `WAppPlugin`；有初始化顺序要求时用 `dependsOn` 显式声明，不要依赖注册顺序。
- `builderWrapper` 位于 MaterialApp 内；`wrapApp` 位于 MaterialApp 外，没有 Theme / MediaQuery。
- `WRouteObserver` 由 `WApp` 自动追加，不要重复添加。
- 多语言用 `WLanguage.changeLanguage`，监听 `languageStream`；语言真源是 `WAppConfig.currentLanguage`。

## 基础工具（w_tools_core）

- `WStorage` 读方法前必须 `await WStorage.init()`；未初始化读取会抛 `StateError`。
- `WStorage` / `WToken` 使用 SharedPreferences，是明文存储，不是安全存储；高敏感数据用 Keychain / Keystore。
- `WValidator` 负责业务语义校验；纯正则匹配 / 提取用 `WRegExp`，不要再手写重复正则。
- 日志统一用 `WLogger.i/d/w/e`；不要直接 `print`。
- `WEncrypt` 的 AES-CBC 不提供完整性 / 认证；需要防篡改时用 AES-GCM。

## 扫码（w_tools_qr）

- 扫码用 `WQrView`，不要直接使用 `qr_code_scanner_plus` 的 `QRView`。
- 默认 `scanOnce = true`；需要连续扫描显式传 `false`。
- 单次扫码完成后需要重新扫描时，通过 `GlobalKey<WQrViewState>` 调用 `restartScan()`。
- 相机权限：Android `CAMERA`，iOS `NSCameraUsageDescription`。
- `onScanned` 只在 `Barcode.code` 非空时触发。
