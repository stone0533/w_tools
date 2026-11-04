# Agent instructions

## 先读

- 文档定位：[`docs/documentation-map.md`](docs/documentation-map.md)
- AI 契约：[`docs/ai-contract.md`](docs/ai-contract.md)
- 维护者提示词：[`docs/ai-maintainer-prompts.md`](docs/ai-maintainer-prompts.md)
- 脚本手册：[`scripts/README.md`](scripts/README.md)

## 改动前先分类

1. **内部重构**：公开 API / 默认行为不变 → 只改代码 + 测试。
2. **公开变化**：API / 行为 / 新组件 → 更新 catalog / AGENTS / README / example；必要时 migration。
3. **删除 / 废弃**：额外清理 aliases / related / migration，并跑 removed API 检查。
4. **新增包**：额外更新 workspace / README / example / feature 模板 / context capabilities / release。

## 改代码后更新 AI 资产

公开变化时：

1. 先改 [`packages/cli/catalog/components.yaml`](packages/cli/catalog/components.yaml)；
2. 规则变化改 [`packages/cli/templates/agents/`](packages/cli/templates/agents/)；
3. 跑生成器：
   ```bash
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
   ```
4. 更新 README / example；
5. 跑：
   ```bash
   python3 scripts/check_public_catalog.py
   python3 scripts/check_package_docs.py
   bash scripts/preflight.sh --with-tests
   ```

不要手改这些生成物：

```text
catalog.g.dart
templates.g.dart
docs/modules/components.md
```


## 测试

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立测试 / 发布。Flutter 子包用 `flutter test`；纯 Dart 包（`map` / `cli` / `figma` / `device`）用 `dart test`；`e2e` 以 pubspec 为准。根 `test/` 只留聚合契约（`w_tools.dart` 的重导出）。

## 文档

改 `docs/` 后跑 `bash scripts/check_docs.sh`（链接、旧命令、包清单、README、事实一致性；CI 也会跑）；公开 API 变化还要跑 `python3 scripts/check_public_catalog.py`。

## 发布

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。子包与聚合包版本独立，根包的 `^x.y.z` 约束必须覆盖子包当前版本（`w_tools_cli` 是独立工具包，根包不依赖它，不在此列）。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。

## 组件约定

新页面表单默认使用 `WForm` + 直接字段（`WFormTextField` 等），不要从 `Config.build` 开始（form 5.0 起 Config / Core 仅内部实现，直接字段不再接受 `config` 参数）；详见 [`docs/agents/form.md`](docs/agents/form.md)。

按钮、图片、页面骨架和弹层的组件选择规则，以及各包「首选入口 / 不要用」速查，见 [`docs/agents/README.md`](docs/agents/README.md)。

- 普通业务按钮用 `WButton`；任意 child 点击用 `WPressable`；表单字段值选择用 `WFormButton`。

改动 `packages/*` 里的组件前：先读 [`CONTRIBUTING.md`](CONTRIBUTING.md)（新增组件的 4 条硬性要求），
再查 [`docs/modules/components.md`](docs/modules/components.md)（有没有现成的、别重复造），
接口设计原则见 [`docs/conventions.md`](docs/conventions.md) §6。

> 消费方项目的接入方式（聚合入口、暂存层、`AGENTS.md` 片段）**不要**写进本文件 ——
> 那些由 `dart run w_tools_cli:w_tools init` 生成到**对方**仓库里；本文件只管「在本仓库怎么改」。

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

- 本仓库内反馈用 `dart run w_tools_cli:w_tools feedback submit ... --ledger`（自动维护 `docs/feedback/` 与索引）；消费方用 issue 入口
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

CLI 是纯 Dart 包：测试用 `dart test`；发布统一用 `bash scripts/publish_package.sh packages/cli`，不要直接 `dart pub publish`。

设备验证工具：`packages/device`（`w_tools_device`）与 `packages/e2e`（`w_tools_e2e`）。
需要模拟器 / Android / 真机截图、点击、稳定等待或 E2E 自动登录时，先读
[`docs/agents/device-testing.md`](docs/agents/device-testing.md)，不要手写 adb / DeviceHub 标定。

Figma 取数工具在 `packages/figma/`（`w_tools_figma`，独立 CLI 包）。需要设计稿规格 / token / diff 时，
先看 [`docs/agents/figma.md`](docs/agents/figma.md)，不要直接手写 Figma API 调用。

## 使用反馈（遇到问题先查再记）

用 `w_tools_*` 时撞到问题，**先查重，再提交** —— 这是完善 w_tools 的主要输入。

### 本仓库内（维护者 / 仓库 AI）

```bash
dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>
dart run w_tools_cli:w_tools feedback submit \
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
  dart run w_tools_cli:w_tools feedback submit \
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

## 启动与主题（ScreenUtil / WTextStyles）

- 不要在 `main()` / 顶层 `final` 计算 `.sp`；在 `ScreenUtilInit.builder` 或 `WAppPlugin.builderWrapper` 的 build 期构建。
- `WAppPlugin.wrapApp` 在 MaterialApp 外，没有 Theme / MediaQuery；需要 Theme 用 `builderWrapper`。
- `WAsyncTheme` 只存 builder，可放 `wrapApp`。

## 文字（w_tools_ui）

- 新代码用 `WText(variant:)` + `WTextStyles`；`WTextConfig` 已移除。
- 局部用 `style` / `maxLines` / `overflow` / `textScaler` 覆盖；字体统一放 `WTextStyles`。
- 先复用已有 variant；新增 variant 按 breaking change 评估。

详见 [`docs/agents/ui.md`](docs/agents/ui.md)。

## 异步区块（w_tools_async）

- 页面用 `WAsyncController` + `WAsyncView`；每个区块一个 Controller，不要手写 `ValueNotifier`。
- `WAsyncTheme` 放 App 根节点；滚动壳用 `WAsyncStateBuilder`，Sliver 用 `WAsyncStateSliver`。
- 分页用 `WAsyncPagedController`；`loadMore` 失败写 `loadMoreError`，不要替换列表。
- 纯执行用 `WAsync.tryRun`（`WAsyncResult`）或 `WAsync.run`（失败抛异常）；取消用 `WCancelToken`。
- Controller 自己维护四态，不要传 `options.activity`。

详见 [`docs/agents/async.md`](docs/agents/async.md)。

## 网络（w_tools_api）

- 统一 `WApiConfig` + `DioRegistry.forBaseUrl`，不要直接 `Dio()`；同一 baseUrl 只初始化一次，换配置先 `dispose`。
- Token 用 `WToken`；拦截器只注入回调。日志用 `WLogInterceptor`，不要依赖它做业务错误处理。

详见 [`docs/agents/api.md`](docs/agents/api.md)。

## 启动（w_tools_app_getx）

- 入口用 `WApp.options(WAppOptions(...)).start()`；不要手写 `runApp` 初始化顺序。
- 插件用 `WAppPlugin`；有顺序要求用 `dependsOn`。`WRouteObserver` 由 `WApp` 自动追加。
- 多语言用 `WLanguage().changeLanguage(...)`。

详见 [`docs/agents/app.md`](docs/agents/app.md)。

## 基础工具（w_tools_core）

- `WStorage` 读之前必须 `await WStorage.init()`；`WStorage` / `WToken` 是明文存储，不是安全存储。
- 校验用 `WValidator`，正则用 `WRegExp`，日志用 `WLogger`，不要 `print`。
- `WEncrypt` 的 AES-CBC 不提供完整性；需要防篡改用 AES-GCM。

详见 [`docs/agents/core.md`](docs/agents/core.md)。

## 扫码（w_tools_qr）

- 用 `WQrView`，不要直接用 `QRView`；默认 `scanOnce = true`，连续扫描显式 `false`。
- 重扫用 `GlobalKey<WQrViewState>.restartScan()`；配置相机权限。
- `onScanned` 只在 `Barcode.code` 非空时触发。

详见 [`docs/agents/qr.md`](docs/agents/qr.md)。

## 地图（w_tools_map + w_tools_map_google）

- `WMap` / `WMapZone` 来自 `w_tools_map_google`，模型 / mapper 来自 `w_tools_map`；不要直接用 `GoogleMap`。
- Google Maps 需要 API Key；地图默认关闭，用 `init --map`。
- `markerId` 必须稳定；生成模型用 `WMapItemMapper`；选中/关闭用 `WMapController`。

详见 [`docs/agents/map.md`](docs/agents/map.md)。

## 包级规则入口

- core / ui / form / async / api / app / qr / map 的详细规则分别在 [`docs/agents/`](docs/agents/)；
- 组件目录由 [`catalog/components.yaml`](packages/cli/catalog/components.yaml) 生成；
- README / example 是该包的用户事实源与可运行场景。
