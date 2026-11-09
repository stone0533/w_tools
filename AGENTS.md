# Agent instructions

## 先读

所有任务先看本文件的「改动前先分类」「测试」「文档」「发布」四节；其余按任务查：

| 任务 | 读 |
|---|---|
| 找组件 / 查用法 | `dart run w_tools_cli:w_tools list <关键词> --format=prompt` / `explain <组件名> --format=prompt` + [`catalog`](packages/cli/catalog/components.yaml) |
| 改公开 API / 组件 | [`packages/cli/catalog/components.yaml`](packages/cli/catalog/components.yaml) + [`docs/modules/components.md`](docs/modules/components.md) |
| 改 AI 资产 / catalog / 模板 | [`docs/ai-contract.md`](docs/ai-contract.md) |
| 改脚本 / 门禁 | [`scripts/README.md`](scripts/README.md) |
| 改命名 / 新增公开类型 | [`docs/naming.md`](docs/naming.md) |
| 判断文档该放哪 | [`docs/documentation-map.md`](docs/documentation-map.md) |

> [`docs/ai-maintainer-prompts.md`](docs/ai-maintainer-prompts.md) 是**给人**复制场景提示词的手册（A~N），agent 不需要预读。

## 改动前先分类

1. **内部重构**：公开 API / 默认行为不变 → 只改代码 + 测试。
2. **公开变化**：API / 行为 / 新组件 → 更新 catalog / AGENTS / README / example；**抬子包版本 + 写当前版本 CHANGELOG 段**（聚合子包同时抬根包 `^x.y.z` 下界；改到 CLI `init` 约束时同步 `packages/cli/lib/src/init/versions.dart`；**公开 API 变化必须抬版本** —— `check_version_bump` 不认 `## Unreleased`；根包 / CLI 自身没有 API diff 的约束变化可以跟功能 PR，但必须写进非空 `## Unreleased`，由 K-2 折叠成版本段，见 `docs/releasing.md`；`scripts/check_versions.py` 保证所有下界 == 当前版本）；必要时 migration；改根包 `lib/` / `pubspec.yaml` 时必须同时改根 `CHANGELOG.md`，根包 re-export 变化必须抬根包版本（`check_version_bump`）。行为变化没有公开 API diff，CI 的 `check_pr_scope.py` 按 PR 模板兜底：改了公开代码（`lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/`）的 PR 必须带「## 改动类型」段并至少勾选一项（空 body 也会失败）；勾了公开类别（公开变化 / 删除废弃 / 新增包）时，每个改了公开代码的包都要改自己的 CHANGELOG，且版本要高于已发布基线（CI 带 `--online` 时用 pub.dev，取不到回退快照；或 CHANGELOG 有非空 `## Unreleased`）。
3. **删除 / 废弃**：额外清理 aliases / related / migration，把删除的公开名补进 `scripts/check_removed_api.py` 的名单，并跑 removed API 检查。
4. **新增包**：额外更新 `scripts/packages.manifest` / workspace / README / example / feature 模板 / context capabilities（仅消费入口包） / release。工具包（无 barrel）还要登记 `check_public_api_diff.py` 的 `NO_PUBLIC_API`、`check_docs_facts.py` 的 `TOOLS`、`check_naming.py` 的 `TOOL_PACKAGES`，并生成 header-only 快照（否则 `check_public_api_diff` 缺基线会失败）。首次发布前把裸名加进 `scripts/pending_first_release.txt`（首发成功后删行），否则周检会因 pub.dev 404 判红。

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

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立测试 / 发布。Flutter 子包用 `flutter test`；纯 Dart 包（`map` / `cli` / `figma` / `device`）用 `dart test`；`e2e` 以 pubspec 为准。根 `test/` 只放聚合契约（`w_tools.dart` 重导出）与跨包回归，单包行为测试不要放这里。

守卫 / 错误分支 / 边界 clamp 的用例要能证明「删掉被守逻辑它就红」：用 `bash scripts/mutate_guard.sh` 做一次定向变异（`--expect` 与 `bash -c` 写法见 `CONTRIBUTING.md` §4 和 `scripts/README.md`「测试有效性（人工）」）。只断言 `takeException()` / `returnsNormally` 的用例优先查——删掉功能它也可能绿；变异存活先补正向断言，再考虑删守卫。

本机 / agent 沙箱没有 Flutter cache 写权限时，用 `bash scripts/preflight.sh --sandbox` 跳过 Flutter 测试（由 CI 覆盖）；单包改动用 `--package`，多包用 `--changed`，不要默认全量 `--with-tests`。preflight 用 `dart analyze`（同一 analyzer，不需要 Flutter engine cache）；CI 的每包 job 仍会跑 `flutter analyze`。

## 文档

改 `docs/` 后跑 `bash scripts/check_docs.sh`（链接、旧命令、安装版本、文档符号 / import 边界、已删除 API、索引、事实一致性；CI 也会跑）；公开 API 变化还要跑 `python3 scripts/check_public_catalog.py`。

## 发布

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。发布后核对线上 / 快照：`python3 scripts/release_status.py --online`（每周一 CI 也会跑，`--check` 把「落后 / 快照漂移 / 缺快照 / pub.dev 404」判失败；网络不可达返回 2，周检按跳过处理）。子包与聚合包版本独立，发布根包前 `release_check --strict` 要求根包的 `^x.y.z` 约束覆盖子包当前版本，并且**根聚合包**的 API 快照版本 == 本地（工具包 / 不聚合的包允许待发布；`w_tools_cli` 是独立工具包，根包不依赖它）。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。正式发布时脚本自己会先 `git fetch`，再要求干净工作区、`main` 且 HEAD == 最新的 `origin/main`、并跑 `release_check --strict`；子包还会过快照基线守卫（最新快照已提交，本地版本不得低于 / 等于快照，新包首发在 `pending_first_release.txt` 时除外）。脚本里的 `--force --reason "..."` 只用于明确的例外。

子包发布成功后，脚本先把快照写到 `.w_tools/release-snapshots/`（gitignored，不会挡住下一个包）；一批发完运行 `bash scripts/apply_snapshots.sh` 应用到 `scripts/api_snapshots/`，再走分支 + PR：`pre-push` 禁止直接 push main，而发布脚本要求 `HEAD == origin/main`。同一波还要发根包时，先合入快照 PR 并 `git pull --ff-only`，再发根包（详见 `docs/releasing.md` 第 7 步）。

### 本机网络（pub 的 OAuth 校验）

`pub login` / `pub publish` 的 OAuth 校验要连 `accounts.google.com` / `oauth2.googleapis.com`；
本机直连这两个域不通，而 pub 没有超时——现象是**没有任何输出地卡住**（进程停在 `SYN_SENT`），
看起来像"命令没反应"。`pub.dev` 自己直连是通的。本机 Clash 代理在 `127.0.0.1:7890`：

```bash
export HTTPS_PROXY=http://127.0.0.1:7890
export HTTP_PROXY=http://127.0.0.1:7890
export NO_PROXY=localhost,127.0.0.1,pub.flutter-io.cn,storage.flutter-io.cn,pub.dev
dart pub login   # 秒回 "You are already logged in as ..." 即代理生效
```

pub 只认 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 环境变量，不读 macOS 系统代理设置。
换端口 / 换机器时先用 `nc -z 127.0.0.1 <port>` 探活再导出；CI 不需要这一节。

### 发布窗口判断

先查 pub.dev 最新版本，再决定 `remove-in` / breaking 写给哪个版本：

- 基线是 pub.dev 最新发布版本（= `scripts/api_snapshots/` 的最新快照）。
- 删除 / 改名**已发布** API：抬 major（7.x → 8.0.0），`remove-in` 写 8.0.0。
- 只在上次发布之后新增、从未发布的 API：可在当前未发布版本直接改 / 删，不抬 major。
- 例：ui `7.0.0` 已发布、本地 `7.1.0`：`7.0.0` 里存在的 API 删除 → `8.0.0`；
  `7.1.0` 新增的 API 改名 → 仍在 `7.1.0`（若尚未发布），不需要 `remove-in`。
- 0.x 工具包按 semver 预发布语义（minor 可破坏）；细节见 ADR-0001 的 2026-11-07 补充。
- 判断命令：`curl -s https://pub.dev/api/packages/<pkg> | jq -r .latest.version`，
  或 `python3 scripts/release_status.py --online`（把「待发布」显示为正常状态；
  `release_check --online` 在断网时返回 2，发布前不要用它做判断）。

## 改代码时的组件硬规则

- 新页面表单用 `WForm` + 直接字段（`WFormTextField` 等）；不要从 `Config.build` 开始，直接字段不要传 `config`。
- 普通业务按钮用 `WButton`；任意 child 点击用 `WPressable`；表单字段值选择用 `WFormButton`。
- 新增/修改组件前先读 [`CONTRIBUTING.md`](CONTRIBUTING.md)、[`docs/naming.md`](docs/naming.md) 和 [`docs/modules/components.md`](docs/modules/components.md)，不要重复造。
- 详细选择规则见 [`docs/agents/README.md`](docs/agents/README.md)。

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

- 本仓库内反馈用 `dart run w_tools_cli:w_tools feedback submit ... --ledger`（自动维护 `docs/feedback/` 与索引）；
  消费方开启 `feedback.enabled` 后**本地台账优先、其次 Issue**；都没有 → `submit` exit 4（什么都没写）
- [`docs/conventions.md`](docs/conventions.md) §7 的规则表（doctor 的 R1~R9）
- [`docs/modules/components.md`](docs/modules/components.md)（若涉及组件建议）
- `packages/cli/test/internal/init_test.dart` / `internal/doctor_test.dart` 的用例
- `packages/cli/CHANGELOG.md`

**改了 `DoctorConfig` 的默认值**必须同步 `renderDefaultConfig()`（`doctor --print-config` 的输出），
`packages/cli/test/internal/config_render_test.dart` 会挡住漂移。

**改了 `packages/cli/templates/` 下的模板文件后必须跑**（在 `packages/cli/` 下）：

```bash
dart run tool/gen_templates.dart
```

生成 `lib/src/init/templates.g.dart`，否则 `test/internal/templates_fresh_test.dart` 会红 ——
这是有意的：模板只允许有一份来源（`templates/`）。

**改了 `packages/cli/catalog/components.yaml` 后必须跑** `dart run tool/gen_catalog.dart`
（生成 `lib/src/catalog/catalog.g.dart` 和 `docs/modules/components.md` 的 §1~§9 表格），
否则 `test/internal/catalog_test.dart` 会红 —— 组件目录同样只允许有一份来源。

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

- 默认关闭：不写文件、不生成链接、不建 Issue（`submit` 会 exit 4 并说明什么都没写）；
- 需要反馈时在 `.w_tools_doctor.yaml` 设置：
  ```yaml
  feedback:
    enabled: true
  ```
- 然后（默认路由：本机 w_tools 台账 → Issue）：
  ```bash
  dart run w_tools_cli:w_tools feedback submit \
    --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md
  ```
- 本机有 w_tools 仓库检出（path / git 依赖）→ 写**那个仓库**的 `docs/feedback/`，不建 Issue；
  仓库 clone 在别处时用 `feedback.ledger: <路径>` 指过去；
  没有检出才建 Issue（需已安装 gh；gh 读取 `GH_TOKEN` / `GITHUB_TOKEN`，或 `gh auth login`）；
- 公开 Issue 每个项目每天最多 5 条（`feedback.max_issues_per_day`，0 = 不限），额度耗尽 exit 2；
  本地台账不占额度；
- `--issue` 只在「本机有台账但确实要公开提 issue」时用；开关未开启时会被拒绝（exit 2）；
- 消费方**不要**直接改 `docs/feedback/` 的索引（没有索引维护能力）。

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

single-context — one root `GLOSSARY.md` shared by the app and all packages, with architecture decisions in `docs/adr/`. `GLOSSARY.md` 按需创建（当前还没有），不存在时静默继续。See `docs/agents/domain.md`.

## 包级硬规则（细节见 docs/agents/）

> 本文件不复制包级细节：每包只留最容易违反的一条，完整规则点进去看。
> 包级用法冲突时，以 `docs/agents/` 与对应包 README 为准；仓库提交门禁以本文件为准。

| 包 | 最短硬规则 | 详情 |
|---|---|---|
| core | `WStorage` 读前 `await WStorage.init()`；`WValidator` / `WRegExp` / `WLogger`；`WEncrypt` 的 AES-CBC 不提供完整性 | [core](docs/agents/core.md) |
| async | `WAsyncController` + `WAsyncView`；`WAsyncTheme` 放根节点；分页失败写 `loadMoreError` | [async](docs/agents/async.md) |
| ui | 新代码 `WText(variant:)` + `WTextStyles`；普通按钮 `WButton`、任意 child 点击 `WPressable`；图片 `WImage` | [ui](docs/agents/ui.md) |
| form | `WForm` + 直接字段；不要从 `Config.build` 开始，字段不传 `config` | [form](docs/agents/form.md) |
| api | `WApiConfig` + `DioRegistry.forBaseUrl`；不要直接 `Dio()`；token 用 `WToken` | [api](docs/agents/api.md) |
| toast | `WToast` + `WToastStyle` / `WToastTheme`；根节点一次 `BotToastInit` | [toast](docs/agents/toast.md) |
| app | `WApp.options(WAppOptions(...)).start()`；插件用 `WAppPlugin`，有顺序要求用 `dependsOn` | [app](docs/agents/app.md) |
| qr | `WQrView` + `WQrController`（重扫 `controller.restart()`），不要直接用 `QRView` | [qr](docs/agents/qr.md) |
| map | `WMap` / `WMapZone` 来自 `w_tools_map_google`；`markerId` 必须稳定；不要直接用 `GoogleMap` | [map](docs/agents/map.md) |

## 启动与主题（跨包）

- 不要在 `main()` / 顶层 `final` 计算 `.sp`；在 `ScreenUtilInit.builder` 或 `WAppPlugin.builderWrapper` 的 build 期构建。
- `WAppPlugin.wrapApp` 在 MaterialApp 外，没有 Theme / MediaQuery；需要 Theme 用 `builderWrapper`。
- `WAsyncTheme` 只存 builder，可放 `wrapApp`。

> 组件目录由 [`catalog/components.yaml`](packages/cli/catalog/components.yaml) 生成；
> README / example 是该包的用户事实源与可运行场景。
