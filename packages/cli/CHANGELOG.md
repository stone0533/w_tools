## 1.20.40

### Changed
- catalog 删除 `WRetryInterceptor` 的 `Retry-After` / `retryOnUnknownErrors` 说明，
  `WLogInterceptor` 删除 `replace*` 参数说明；6.1.0 收敛为更小的功能面。
- `init` 的 `w_tools_api` 约束保持 `^6.1.0`（同版本内收敛）。

## 1.20.39

### Changed
- catalog 同步 `w_tools_api` 6.1 的 LRU / TTL 语义：淘汰不再强制中断在途请求，
  显式 dispose / clearCache 仍 force。
- 同步日志超大 body 限量和 retry 退避取消行为。

## 1.20.38

### Changed
- catalog 补 `WPage` 分页边界：`page` 只支持 1-based 页码分页，offset / cursor 用
  `WApiClient.send` 手工构造；同步 `WApiClient.page` 非法 `page` / `pageSize` 的
  `ArgumentError` 说明。

## 1.20.37

### Changed
- catalog 同步 `w_tools_api` 6.1：`WTokenInterceptor.shouldRefresh`、
  `WApiClient.send/page` 按请求覆盖信封、`WLogInterceptor` 错误响应片段。
- `init` 的 `w_tools_api` 约束保持 `^6.1.0`（同版本内补齐 6.1 条目）。

## 1.20.36

### Changed
- catalog 同步 `w_tools_api` 6.1：信封空 body、`DioRegistry.replace`、
  `downloadResponse` / `readTotalFromResponse`、日志脱敏追加语义、
  `Retry-After` / `retryOnUnknownErrors`、`WMetric.attempt`。
- `init` 的 `w_tools_api` 约束抬到 `^6.1.0`。

## 1.20.35

### Changed
- catalog / explain / init 模板同步 `w_tools_api` 6.0：`WApiConfig` → `WApiSettings`、
  `WApiMetricsInterceptor` → `WMetricsInterceptor`、`WApiMetric` → `WMetric`；删除空壳数据层与
  日志友好提示。
- `init` 的 `w_tools_api` 约束抬到 `^6.0.0`。

## 1.20.34

### Changed
- catalog / explain 同步 `WApiMetricsInterceptor` / `WApiMetric`。
- `init` 的 `w_tools_api` 约束抬到 `^5.6.0`。

## 1.20.33

### Changed
- catalog / explain 同步 `WApiResponse` / `WApiClient.send` /
  `WApiEnvelopeParser.authFailureCodes`。
- `init` 的 `w_tools_api` 约束抬到 `^5.5.0`。

## 1.20.32

### Changed
- catalog / explain 同步 `WApiClient.head/options` 与 `upload(method:)`。

## 1.20.31

### Changed
- `init` 的 `w_tools_api` 约束抬到 `^5.4.0`。

## 1.20.30

### Changed
- `catalog` / `templates` 同步 `w_tools_api` 5.3.0 的 `WApiClient` / `WApiEnvelopeParser` / `WPage` / `WRetryInterceptor` 条目。
- `init` 的 `w_tools_api` 约束抬到 `^5.3.0`。

## 1.20.29

### Changed
- `init` 写入的 `w_tools_device` 约束同步到 `^0.3.3`。

## 1.20.28

### Changed
- `init` 写入的 `w_tools_form` 约束同步到 `^7.0.1`，`w_tools_async` 同步到 `^6.8.0`。

## 1.20.27

### Changed
- catalog / `init` 版本约束同步 `w_tools_form` 7.0.0（公开面收口、字段参数补齐、controller 值 API 收敛）。

## 1.20.26

### Changed
- catalog 补 `WListViewSliver.overlap` 的 hit test pitfall 与 `WImageSlots`
  原始 Base64 字符串提示。

## 1.20.25

### Changed
- catalog / 模板同步 `WScaffold` 拆分：默认顶栏用 `WScaffold.basic`，
  显式 `appBar` 用 `WScaffold`。

## 1.20.24

### Changed
- catalog 把 `WNumExtension` 拆成 `WNumLayoutExtension` / `WNumFormatExtension`。

## 1.20.23

### Added
- catalog 补 `WGradientCircularProgressIndicator.indeterminate` 用法与 pitfalls。

## 1.20.22

### Added
- catalog 新增 `WNavDestination`，`WNavBar` 增加 `destinations` 默认项用法。

## 1.20.21

### Changed
- catalog 同步 `WImageSlots` 只保留 builder（删除 `placeholder` / `emptyWidget` /
  `errorWidget` 固定 Widget 入口）。

## 1.20.20

### Changed
- catalog 补 `WStep` 构造时复制 `labels` 的说明（不再是 `const` 构造器）。

## 1.20.19

### Changed
- catalog 同步 `WWidgetExtension` 精简（6 个物理 padding 删除、
  `withBottomBarSpaceOf` 改名 `withBottomSafeSpaceOf`）。

## 1.20.18

### Changed
- catalog 移除 `WImageFrame`（ui 11.0 不再从 barrel 导出）；
  `WImageStyle` 的几何字段类型说明同步。

## 1.20.17

### Changed
- catalog 把 `WButtonStyles` 合并到 `WButtonStyleSet`（`WButtonStyleSet.of(context)`）；
  `WButton` 的示例 / pitfalls 同步。

## 1.20.16

### Changed
- catalog 移除 `WTextStyleExtension` / `WUiWidgetExtension`（ui 11.0 删除，后者合并到
  `WWidgetExtension`）；`WWidgetExtension` usage 补 `toPressable`。

## 1.20.15

### Changed
- catalog / entrypoints / AGENTS 模板移除 `WClipRRect`（ui 11.0 删除，改用 Flutter `ClipRRect`）；
  同步 `w_tools_ui` 约束 `^11.0.0`。

## 1.20.14

### Changed
- catalog 补 `WAppBar` 阴影 / 两侧布局、`WBadge.offset`、`WTabBar` 交互参数、
  `WScaffold.bottomNavigationBarSafeArea`、`WButton.tooltip` / `isSelected`；
  同步 `w_tools_ui` 约束 `^10.5.0`。

## 1.20.13

### Changed
- catalog 补 `WScaffold` 抽屉 / 底部面板透传与 `WNavBar.onBeforeTap` 示例 / pitfalls；
  同步 `w_tools_ui` 约束 `^10.4.0`。

## 1.20.12

### Changed
- catalog 补 `WText.rich`、`WBadge.count` / `dot`、`WTabBarStyle` 标签颜色与
  `WNavBar.safeArea` 示例 / pitfalls；同步 `w_tools_ui` 约束 `^10.3.0`。

## 1.20.11

### Changed
- catalog 补 `WIconText.custom` 示例与 pitfalls；同步 `w_tools_ui` 约束 `^10.2.0`。

## 1.20.10

### Changed
- catalog 中 `WImageError` 的示例改用 `localizedMessage(context)`；同步 `w_tools_ui` 约束
  `^10.1.0`。

## 1.20.9

### Changed
- `init` 生成的 `lib/app/ui/README.md` 补主题接入说明：`withWTextStyles` 与
  `WImageTheme(slots: ...)`，避免消费方漏装语义字体 / 图片兜底。

## 1.20.8

### Changed
- `init` 写入的 `w_tools_async` 约束同步到 `^6.7.0`（`WAsyncController.reload()`）。
- `explain` / catalog 推荐 `reload()`；`retry()` 标为 deprecated。

## 1.20.7

### Changed
- `init` 写入的 `w_tools_async` 约束同步到 `^6.6.0`（`WAsyncStrings.loading` /
  默认视图 `liveRegion`）。
- `explain` / catalog / AGENTS 模板补充 `loading` 文案与默认可访问性语义。

## 1.20.6

### Changed
- `init` 写入的 `w_tools_async` 约束同步到 `^6.5.0`（分页 footer 状态机）。
- `explain` / catalog / AGENTS 模板补充 `WAsyncPagedFooterStatus` / `footerStatus`。

## 1.20.5

### Changed
- `init` 写入的 `w_tools_async` 约束同步到 `^6.4.0`（取消竞态修复 / `settle` /
  `replaceData` / `listWithToken` / retry 退避与观测）。
- `explain` / catalog / AGENTS 模板补充 `WAsync.settle`、`WAsyncController.replaceData` /
  `listWithToken`、`WAsync.retry` 的 `retryDelayBuilder` / `onRetry`。

## 1.20.4

### Changed
- `init` 写入的 `w_tools_async` 约束同步到 `^6.3.0`（`WAsyncPage` / `withPage`）。

## 1.20.3

### Changed
- `init` 写入的 `w_tools_ui` 约束同步到 `^8.2.0`（WTabBar noSplash / WImage 提示带 source）。

## 1.20.2

### Changed
- `feedback status`（text / json）新增公开 Issue 日额度：date / used / max / remaining / 预算文件路径。
- `feedback submit` 额度耗尽的错误补上「已用 / 上限 / 剩余」、`max_issues_per_day` 配置路径、
  默认值 5 和预算文件路径，便于直接排查 / 调整。

## 1.20.1

### Changed
- `init` 写入的 `w_tools_api` 约束同步到 `^5.2.0`（`WLogInterceptor` 的 body 敏感字段脱敏）。

## 1.20.0

### Added
- 新增 `lib/src/command_registry.dart`：`--help` 的命令段与 `context.commands` 由同一份注册表派生；
  新增命令不再 `bin/w_tools.dart` / `context_project.dart` 两处维护。

### Changed
- `context --format=prompt` 的 `命令:` 段改为每个 `key=value` 一行，避免约 700 字符挤在一行。
- `closing.md` 的反馈引导改为陈述式条件句，补上「有改进建议」，避免「被卡住？」和「才提交」的歧义。

## 1.19.1

### Changed
- `init` 的 `w_tools_async` 约束同步到 `^6.2.0`（refresh 可重入、sliver 错误条上移、
  新增 `WAsyncPagedController.replaceData`）。

## 1.19.0

### Added
- 新增 `upgrade`：把 `pubspec.yaml` 里的 `w_tools` / `w_tools_*` 抬到 hosted 上的最新版本。
  - `--check` 只读（有落后 / lock 落后 exit 1，可进 CI）；`--dry-run` 打印 diff 不写；
    默认写入后跑 `pub get`，失败还原 pubspec 并 exit 2。
  - 只动 `w_tools*`，其它依赖（含刻意钉死的版本）与 pubspec 注释一律不动；跨 major 默认只报告，
    `--major` / `--only=<包>` 才写；0.x 包跨 minor 按跨 major 处理。
  - 查最新走 `PUB_HOSTED_URL`（默认 pub.dev，认 `HTTP(S)_PROXY`），输出里带实际源。
  - `context` 的 `commands` 加 `upgrade` / `upgradeCheck`，AI 能直接发现这条入口。
- 消费方 AGENTS 片段加一条「升级依赖」路由；`AI_PROMPTS.md` 的 F-2 第 1 步改用 `upgrade`。

## 1.18.2

### Fixed
- `init` 写 `.w_tools/init.json` 时持久化 `figmaInstall`；`doctor` R8 与 `init` 共用
  `figmaInstallLine(pubspec)` 计算。修掉 pubspec 钉了 `w_tools_figma: ^x.y.z` 的项目
  `init --force` 后 R8 仍报漂移、而 init 认为「已是最新」的死循环。

### Changed
- `init` 写入的子包约束同步 `w_tools_ui: ^8.1.0`、`w_tools_device: ^0.3.2`。

## 1.18.1

### Changed
- `init` 写入的子包约束同步 `w_tools_core: ^3.1.2`（core 3.1.2 修了 `WStorage.setObject` 的错误处理）。

## 1.18.0

### Changed
- **消费方 AI_PROMPTS 与 AGENTS 对齐**：固定前缀补 `doctor --format=json`（0 error）、`test/` / `tool/` /
  `integration_test/` 下 dev-only import 例外、L-1 反馈开启片段；§3 自检清单补 doctor 与生成物清单。
- 修正与 catalog 冲突的 C-1 `validatorSettings` 说法；E-1 / §2 的 `explain` exit 1 补「匹配到多个」；
  I-1 的集成测试命令改为可直接执行（`flutter test integration_test` / `dart test test`），
  J-1 明确以 `git diff` 或用户贴的 diff 为审查输入。
- 升级场景：migration 说明改为 CHANGELOG 优先（`docs/` 不随包发布），示例更新到 ui-8.0 / form-6.0；
  F-2 明确先改 pubspec 约束并 pub get（普通 `pub upgrade` 不跨 major）；聚合包说明不再暗示「保持现状」即可通过 doctor R1。
- README / templates README：固定前缀例外补 L-1，场景清单补 L-1，§3 不再称「文末」。
- **新增两个场景**：M-1 接入 / 体检（按 doctor 报告一次修一条规则，直到 0 error）、
  N-1 小改动（单文件 / 小范围，先给最小改法再动手）；固定前缀的开发者称谓按项目类型渲染
  （纯 Dart 项目不再写「Dart / Flutter 开发者」）。
- `feedback status --json` 在通道 disabled 时附带 `enableHint`，AI 不用再猜开启方式。
- **消费方 AGENTS 片段重做**：`init` 写入 `AGENTS.md` / `CLAUDE.md` / cursor / copilot 的片段从 280 行 / 11.6k 字符
  降到 72 行 / 4.2k 字符，固定四段：`怎么用 w_tools` → `硬规则` → `组件约定`（每包一行）→ `完成前`。
- 硬规则上移并带 doctor 规则号（R1 / R2 / R4 / R5 / R9）；R2 的 import 例外（toolkit、`lib/app/ui/`、
  `lib/app/design_system/`、`test|tool|integration_test` 下的 `w_tools_cli` / `figma` / `device` / `e2e`）
  从 R2 的同一份常量渲染 —— 此前「业务代码只 import 聚合入口」是绝对值，和 R2 白名单、generated 的 `app_*.dart` 互相矛盾。
- 每个启用的包只留一行：主入口清单 + 一句话规则 + `explain` 入口；逐 API 细节从 AGENTS 删除
  （`WImage` 尺寸约束、`WText` variant 顺序、`WNavBar` vsync 等仍在 catalog `pitfalls` / `explain`，不丢事实）。
- 反馈段 68 行 → 3 行（默认关闭），完整流程指向 `.w_tools/AI_PROMPTS.md` 的 L-1；删除
  `templates/agents/{zh,en}/feedback.md`。
- Figma / 设备段改为路由：命令以 `packages/figma/README.md`、`figma --help`、
  `docs/agents/device-testing.md` 为唯一来源，AGENTS 不再维护第二份命令清单。
- 删除内联 doctor 规则速查表（`## 检查项`）；规则清单与启用状态由 `doctor --format=json` 提供。
- `## 完成前` 的 analyze / test 跟随项目类型，纯 Dart 项目不再被要求跑 `flutter`。

### Fixed
- `## 项目规则` 从标记块内移到**块外**：新建指令文件时追加一次，`init` 不再覆盖项目自己的规则；
  此前它既是块内生成内容（重跑即丢），又会把所有组件约定吞进自己的标题下。
- 普通 `init`（不带 `--force`）原地刷新指令文件标记块时，若块内内容与模板不同（手改 / 换 profile），
  先写 `AGENTS.md.bak` 再覆盖并给 warning（此前静默丢失）；README 的 `--force` 语义同步改成与实现一致。
- R8 改为按**标记块内容**比对（版本号本身不算漂移）：CLI 升版本但模板没变时不再给所有消费方报 warn；
  没有 `.w_tools/init.json` 时仍按版本标记比对。`.w_tools/init.json` 新增可选 `figmaInstall`。
- cursor target 的 `.cursor/rules/w_tools.mdc` 显式写 `alwaysApply: true`：没有它时规则会落到
  「Agent Requested」，由 agent 自己决定读不读，接入约定等于没生效。

### Tooling
- `tool/agent_budget.dart` 新增 `--json`（机器可读快照：schema / generator / rows / feedback）
  与 `--record`（写入 `docs/metrics/agents_budget.jsonl`，一个 CLI 版本一行、幂等 upsert）；
  `--check` 增加「当前版本已记录」校验，版本抬了没记录会失败。
- 周检 `.github/workflows/release-status.yml` 用 `scripts/agents_budget_trend.py` 把预算趋势
  渲染成 Markdown 表写进 job summary；只读历史，不跑 Dart、不需要外网。

### Tests
- `templates_fresh_test.dart` 新增结构预算门禁：full / minimal / en 的行数与字符数、段落顺序、
  反馈行数、zh/en 组件符号集合一致、项目规则占位必须在块外。
- 预算数据化到 `catalog/agent_budget.yaml`（抬预算 = 一处显式 diff），`tool/agent_budget.dart`
  量渲染结果并在 preflight 的 `agents budget` 步打印余量表；测试直接复用同一实现。
- 新增 `scripts/check_agents_routing.py`：AGENTS 模板每条 bullet 必须有锚
  （`explain X` / 路径 / 规则号 / 命令 / 占位符），否则要写 `<!-- no-anchor: 理由 -->` 显式豁免。
- R8 新增「版本升了但内容没变 → pass」「块内被手改 → 报内容不同」用例。

## 1.17.2

### Fixed
- `init` 生成 `w_tools_ui` 的约束同步到 `^8.0.1`（ui example patch）。

## 1.17.1

### Fixed
- `init` 生成 `w_tools_cli` 的 dev 约束改用当前 CLI 版本（`^1.17.1`）；此前停在 `^1.16.0`。
- `init_test` 改为读 `packages/cli/pubspec.yaml` 校验 `cliConstraint`，不再硬编码过期值。

## 1.17.0

### Breaking
- `feedback submit` 没有可用通道时由 exit 0 改为 **exit 4**（什么都没写）；依赖旧退出码的脚本 / CI 要改。
- `--issue` 不再绕过开关：`feedback.enabled: false` 时退出 2（项目根是 w_tools 仓库时除外）。
- 配置键 `feedback.issue` 改名 `feedback.enabled`；旧键仍兼容，同时出现时 `enabled` 优先。

### Changed
- **反馈通道改为一套判定**（`submit` / `status` / `path` / `search` / `lint` 共用）：
  项目根是 w_tools 仓库 → 写该仓库 `docs/feedback/`；开启 `feedback.enabled` 且本机有 w_tools 检出
  （path / git 依赖）→ **写那个仓库的台账**，不建 Issue；没有本地检出才建 Issue；否则跳过。
  此前 `path` 认本地台账、`submit` 却按「项目根是不是仓库」判，路径依赖的消费方会自相矛盾。
- **开关改名 `feedback.enabled`**（默认 false）；旧键 `feedback.issue` 仍兼容，`enabled` 优先。
  `doctor --print-config` 输出同步（旧键以注释保留）。
- **`--issue` 不再绕过开关**：未开启反馈时 `--issue` 退出 2，不再是一条隐式覆盖路径；
  本机有台账时 `--issue` 仍可明确要求公开 Issue。`--ledger` 需要本机 w_tools 仓库检出。
- **跳过不再是「成功」**：`feedback submit` 没有可用通道时退出 **4** 并打印「什么都没写」，
  JSON 带 `mode: skipped` / `exitCode: 4`；AI / CI 不能再把「没提交」当成功。
- `feedback status` 在 `issue` 通道下附带 `gh` 可用性（`installed` / `authenticated` / `ready`），
  不必等提交才发现 gh 没装。
- `feedback lint` 在本机没有台账时输出「跳过」而不是 `✓ 待处理 0 条`（假绿）；`search` 在无本地台账时
  提示加 `--gh`，不再静默返回空。
- 建 Issue 的正文不再带台账元数据（`### [待处理] …` + `- 状态变更：…`），预填链接同步。
- pub cache 里的 git 依赖（`~/.pub-cache/git/…`）不当作「本机 w_tools 库」：不往缓存里写台账，
  按「没有本地仓库」处理（缓存会被 `pub cache repair` 清掉，写进去等于写丢）。
- 新增 `feedback.ledger: <路径>`（相对项目根或绝对路径）：仓库 clone 在别处、依赖解析不到时
  也能命中本机台账；指向的不是 w_tools 仓库会在 stderr 提示一次并忽略（不静默写错地方）。
- 公开 Issue 加**每日额度**：`feedback.max_issues_per_day`（默认 5，0 = 不限）。CLI 没有会话概念，
  用日额度兜住「一次会话 3–5 条」；计数在 `.w_tools/feedback_budget.json`（跨天重置、删了归零），
  本地台账不占额度；额度耗尽 exit 2，`--json` 带 `issueBudgetUsed` / `issueBudgetMax`。
- 从消费方写本机 w_tools 检出时，stderr 提醒「该仓库工作区会变脏，提交前记得 commit / discard」，
  `--json` 带 `dirtiesRepo`。

### Fixed
- `init` 的 `w_tools_device` 约束同步到 `^0.3.1`（`w_tools_device` 已发 0.3.1，上一版仍写 `^0.3.0`）。

### Docs
- `templates/agents/{zh,en}/feedback.md`：写明「本地台账优先 → Issue → 跳过（exit 4）」、开关硬门禁、
  8 个必填字段、Issue 公开需脱敏；补 `feedback.ledger` 的用法。
- `templates/ai/consumer-prompts{,.en}.md`：新增场景 `L-1 记一条反馈`（先 `feedback status`，
  disabled 就停；查重 → 8 字段草稿 → 默认路由提交；不贴密钥、不超 3–5 条）。
- `docs/agents/cli.md` 的 AI 闭环标明记反馈是 `L-1`。
- 消费方 AGENTS 模板补公开 Issue 日额度、以及「写本机台账会弄脏 w_tools 工作区」的提醒。
- `docs/agents/cli.md`、`docs/feedback/README.md`、`packages/cli/README.md`、根 `AGENTS.md` 同步路由与退出码；
  删掉「消费方在本地日志做缓冲」这句与实现不一致的描述。
- `context --format=prompt` 增加一行反馈路由提示（先 `feedback status`，disabled 时不要提交）。

## 1.16.1

### Changed
- catalog / templates：同步 `w_tools_toast` 2.1（新增 `WToast.showModal`；`WToast` 条目补
  「`showCustomDialog` 默认关不掉且点击穿透」的陷阱与正确用法）；`init` 的 toast 约束同步到 `^2.1.0`。

## 1.16.0

### Changed
- catalog / templates / context：同步 `w_tools_qr` 2.0（`WQrController` 归调用方、
  `WQrOverlayStyle`、`WQrScanResult`、移除 `WQrViewState`）；`WQrController` 升为 teach，
  旧名保留为 aliases 供 `explain` 兜底；capability 摘要改为 `WQrView + WQrController（重扫 restart）`。
- `init` 的 `w_tools_device` 版本约束同步到 `^0.3.0`。
- `list --package=device` 的提示改为指向 `docs/agents/device-testing.md`（此前指向不存在的 `device.md`）。
- `doctor`：未启用的规则（默认关闭的 R6、以及用户显式关闭的规则）现在统一以
  `status: skipped` + `skipReason: 未在 rules 中启用` 出现在 `--format=json` / human / markdown
  输出里，不再整条从 `rules` 数组消失；`counts` 与退出码不受影响。

### Docs
- `templates/agents/{zh,en}/async.md`：补「`WAsync` 的 `state` 是 `ValueListenable`、不是 `Rx`，
  页面里其它 Rx 状态的 `Obx` 仍要保留」；分页补「页号读 `page` / `hasLoadedMoreThanOnePage`，
  不要用 `data.length` 变大去猜」。
- `templates/agents/{zh,en}/app.md`：插件 `onInit` 里注册 GetX 服务用 `registerService`
  （`w_tools_app_getx`），不要写 `Future<void> onInit() => Get.putAsync(...)`（会注册到 `void`）。

## 1.15.1

### Fixed
- catalog：`WLanguage` / `WLocaleConfig` / `WAppTheme` 归属改为 `w_tools_app`（`w_tools_app_getx` re-export）。
- 同步 `w_tools_app_getx` 版本约束到 `^2.0.0`、`w_tools_app` 到 `^3.1.0`（init 生成的 pubspec 与 `versions.dart`）。
- catalog/templates：修正 `WApiConfig` 的不可编译 usage；补齐 `WTokenInterceptor` / `WLogInterceptor` /
  `WLogPart` 教学条目（`WLogPart` 升为 teach）；`versions.dart` 同步 `w_tools_api` 到 `^5.1.0`。
- 同步 `w_tools_ui` 版本约束到 `^8.0.0`（init 生成的 pubspec 与 `versions.dart`）。
- 同步 `w_tools_async` 版本约束到 `^6.0.0`（init 生成的 pubspec 与 `versions.dart`）。
- catalog：修正 `WAsyncTheme` 的 `sliverLoadingBuilder` 示例（返回非滚动 Widget），并把
  `WAsyncOptions` / `WAsyncActivity` / `WCancelToken` 从合并条目拆成可独立 `explain` 的条目。
- catalog：补充 `WAsyncState.list` 与 `WAsyncPagedController.changes` 用法。

## 1.15.0

### Fixed
- 同步子包版本约束：`w_tools_form` 改为 `^6.0.0`（catalog / init 模板 / `versions.dart` 一起更新）。


### Changed
- 同步 form 组件目录与 init 模板：`WFormBorderConfig` → `WFormBorderStyle`（新增 `borderStyle:` 用法），
  新增 `WFormThemeData` 条目，`WFormButton` 标注为 `WFormFieldButton<String>` 别名，
  `WFormValidatorSettings` 改为不可变写法，`bordered: false` 的 message 改为渲染在字段下方，
  `phone()` 更新为 `hkPhone()`。
- 重构 `init` 生成的 `.w_tools/AI_PROMPTS.md`，结构对齐维护者提示词手册：
  「新手先看这里 → 0 固定前缀 → 填空说明 → 一个填好的例子 → 1 场景选择 → A~K 场景
  → 2 输出不对时 → 3 AI 完成后你必须检查 → 4 维护这份文档」。
  读者是**使用 w_tools 的 Dart / Flutter 开发者**（对提示词不熟），不是 agent。
- 场景编号从 `C-A~C-K` 改为「族字母-工序号」：`A-1`、`B-1`……；有先后关系的大任务拆成多轮，
  每轮一个可判断的产物——`A-1` 只读计划 → `A-2` 实现、`E-1` 审计 → `E-2` 修复、
  `F-1` 计划 → `F-2` 分文件替换 → `F-3` 验证。旧编号对应：`C-A→A-1`、`C-B→B-1`、
  `C-C→C-1`、`C-D→D-1`、`C-E→E-1`、`C-F→F-1`、`C-G→G-1`、`C-H→H-1`、`C-I→I-1`、
  `C-J→J-1`、`C-K→K-1`。
- 新增「填空说明」占位符表、「一个填好的例子」、「从现象反查」、「输出不对时加一句话」、
  「AI 提到的组件先用 explain 核一遍」、「默认工作流（分轮次）」。
- 固定前缀改为按项目上下文渲染：规则文件名来自本次 targets，工具链命令按 pubspec 的
  `flutter` 依赖在 `flutter` / `dart` 间切换，依赖说明区分具体子包与旧聚合包，
  toolkit 入口写真实 `package:<name>/...`；纯 Dart 与 `--targets=claude` 不再拿到错误指令。
- 选场景元提示改为两段式：先选编号，再只读该场景填占位符；K-1 明确不贴固定前缀；
  A-2 / E-2 / F-2 补同会话 / 交接材料；默认工作流补 `F-3`。
- 升级场景按子包版本填写（不再假设单一 w_tools 版本）；`E-1` 补 ui / toast / app / async
  入口、P0/P1/P2 定义与 explain 查旧 API 步骤；自检表要求标 `✅` / `N/A` / `❌`。
- 自检表收敛为全文唯一一份（§3），各场景正文不再另抄；默认输出契约上收到固定前缀，
  场景块只写差异。
- 模板头部写明「生成物 + `init --force` 无备份」，并提示项目自有提示词另存。
- `init` / `doctor` / `context` / `explain` / `feedback` 的 help、运行提示、doctor fix 与
  example 统一写 `dart run w_tools_cli:w_tools <cmd>`；兼容入口只在 dispatcher 说明里保留。
- `doctor` R1 文案改为“根包已不再聚合 app / map / qr”，地图改指向 `w_tools_map_google`。
- `doctor` R8 纳入 `.w_tools/AI_PROMPTS.md`；`--write-config` 的 help 与
  `docs/conventions.md` 改为“已存在报错，加 `--force` 覆盖”。
- `context` 的 commands 补 `list` / `explain`；`list` 在 prompt/json 下也给出工具包教学入口；
  `feedback search` 拒绝未知包；`explain` 多匹配改为退出 1，JSON 增加 `ambiguous`。
- `AI_PROMPTS` 的升级场景改为按包和版本查找 migration，不再只写 `<pkg>-<major>.md`。
- catalog 给 `WAsync` 补 `tryRun` / `run` / `map` / `retry` 方法别名，`explain` 可精确命中。
- 抽出 `ProjectPubspec` / `GeneratedFiles` / `ConditionalTemplate`，统一 pubspec 读取、
  生成物清单与 `@if` 渲染；生成器拒绝行内 marker，并修 Windows 相对路径分隔符。
- `init --force` 不再覆盖 `.w_tools_doctor.yaml`；新增 `init --force-config` 显式覆盖
  项目配置，覆盖前按 `.bak` / `.bak.<timestamp>` 备份，连续覆盖不丢旧备份。
- `doctor --write-config --force` 复用同一轮转备份逻辑；help / README / conventions
  写明 `.bak` 与 `.bak.<timestamp>`。

### Fixed
- 裁剪后不再出现悬空引用：`A-1` 的 `lib/app/ui/`、`E-1` 的能力清单、`F-1` 的 migration
  文档出处、`I-1` 的 device 段都改成按能力裁剪或条件句；`H-1` 的编号跳号已消除。
- `doctor` 统一写 `--format=json`，不再与 AGENTS 的 `--json` 混用。
- `--targets=claude|cursor|copilot` 时 AI_PROMPTS 不再引用未生成的 `AGENTS.md`。
- 纯 Dart 项目不再生成 `flutter analyze` / `flutter test` / `flutter pub upgrade`。
- 子包 import 规则与 AGENTS / doctor R2 例外对齐：toolkit、`lib/app/ui/`、
  `lib/app/design_system/` 允许直接 import `package:w_tools_*`。
- `context` 在仓库检出、workspace 包不在 `pubspec.lock` 时不再显示“（无）”。

### Added
- AI_PROMPTS 契约测试补齐：每个 feature 关闭后不得引用被裁掉的场景编号、填空表存在、
  固定前缀自足、`I-1` 不再指向不存在的 device 段。
- `check_prompt_docs.py` 把 `packages/cli/templates/ai/*.md` 纳入提示词手册级检查
  （flag / 占位符 / 场景编号双向）；场景标题正则收紧为「必须带点」，避免
  `## A filled-in example` 被误判成场景 A；`§1` 同时接受中英文标题。
- 测试覆盖 AI_PROMPTS 的 targets / 纯 Dart / 聚合包上下文渲染，以及未知占位符不泄漏。
- 新增 CLI-001~012 回归测试：旧入口扫描、R1/R8、context commands、list prompt/json、
  feedback search、explain 多匹配、migration 路径、仓库检出文案、生成器行内 marker。
- 新增 CLI-DOC-001~005 回归测试：`--force` 保留配置、`--force-config` 备份/轮转、
  check/drift 对配置的行为。

## 1.14.0

### Changed
- 未捕获异常不再以「255 + 栈」结束：统一输出错误信封，配置 / 文件问题退出码 2，
  外部工具 / 未知问题退出码 3；`explain` / `context` / `doctor` 的错误在 `--json` 下也输出 JSON。
- `doctor --print-config` / `--write-config` 支持 `--json`；`--force` 必须配合 `--write-config`。
- `explain --format=prompt` 补「不要用于」段，和 text 格式对齐。
- `list` / `explain` / `doctor` / `feedback path|status|search` 的 JSON 输出补
  `schema` / `schemaVersion`。
- `feedback` 的包清单补 `app_getx` / `map_google`，`path` 与 `submit` 共用同一份；
  本地查重不再把 `README.md` / `TEMPLATE.md` 当反馈。
- `feedback submit --issue`：`gh` 未安装 / 未登录退出码改为 3（外部不可用），不再抛栈。
- `init` 的 `toolkit_entry` 必须是项目内相对路径，拒绝绝对路径与 `..`。
- `init` 生成的 toolkit / UI starter / device 模板统一改用 `w_tools_cli:w_tools <cmd>`。
- doctor 缓存 `SourceFile`、R4 单次遍历；R3 的 `Color(...)` 与 R6 的单位不再匹配字符串字面量
  （`fromHex('#...')` 仍按字符串匹配）。
- `list --package=<工具包>` 给出 `docs/agents` / README 的专门提示。

### Fixed
- `feedback --ledger` 在索引缺失时先失败，不再留下「有台账、没索引」的半截状态。
- `init` 的 `needsPubspec` / 下一步提示改由 `InitReport.pubspecNeeded` 驱动，不再解析提示文案。

## 1.13.0

### Changed
- `init` 生成的 `w_tools_ui` 约束同步到 `^7.0.0`，UI 模板补充 `WImageTheme` /
  `WImageSlots` / `WImageSource.resolve` 规则。
- `init` 生成的 `w_tools_map_google` 约束同步到 `^2.0.0`（`WMapConfig` → `WMapOptions`）。
- `init` 生成的全部子包约束改为与仓库当前版本完全一致；修正 `w_tools_device` 仍生成
  `^0.1.4`（当前 0.2.0）的漂移，测试覆盖全部 `subpackageConstraints` 与 device。
- `context` 在 w_tools 仓库检出内标记 `repoCheckout` 并跳过消费方 doctor，
  不再把根包聚合依赖误报成 6 个 error。
- `explain` 读取 `pubspec.lock`，输出 `包版本` 与对应版本的 pub.dev `API 文档`；
  仓库文档链接仍指向 `main`，但会与包版本并列展示。
- catalog 的 `WButton` 示例不再默认推荐 `WButtonStyles`，并补「项目页面优先 AppButtons」pitfall。
- `init` 的 zh / en async 模板统一分页规则为 `WAsyncPagedController`（中文版此前仍写
  「loadMore 自己维护」），与仓库 `docs/agents/async.md` 对齐。
- `context` 在仓库检出、没有可匹配的已安装包时输出「已安装：（无）」，不再打印空值。
- catalog 的 `WText` 说明把 `WTextConfig` 标成「已移除」，让文档门禁能识别这是删除说明而不是推荐。

## 1.12.0

### Added
- `AI_PROMPTS.md` 增加白盒 / 黑盒测试场景，以及调试、补测试和页面完成自检。
- 白盒 / 黑盒段按已启用能力裁剪，避免提示不存在的场景。
- 场景表与章节同步裁剪；新增 `@if` 标记闭合校验。

### Fixed
- `init` 的 AI 提示词不再指向未启用 form / api 的章节。
- `--ai-prompts` / `--no-ai-prompts` 相反参数同时使用时明确报错。

## 1.11.1

### Fixed
- Figma AGENTS 模板补全 `fetch file` / `fetch images` / `get` / `me` / `usage` /
  `cache` / `budget` / `help` / `version` 命令，并同步 `templates.g.dart`。

## 1.11.0

### Added
- `list --package=<包>`：按包过滤组件目录。
- `explain` 输出增加文档章节锚点与示例链接。
- `feedback --allow-duplicate`：允许写入完全相同的反馈（默认拒绝）。

### Changed
- `feedback --ledger` 默认拒绝完全相同的反馈；确认重复时加 `--allow-duplicate`。

### Fixed
- `feedback lint` 增加重复条目、占位标题 / 命令 / 复现数据检查。
- `feedback submit` 自动补 `状态变更：<今天> 待处理`。

## 1.10.0

### Added
- `init` 默认生成 `.w_tools/AI_PROMPTS.md`：消费者版 AI 任务提示词。
- 新增 `--ai-prompts / --no-ai-prompts`；`--no-instructions` 时自动关闭。
- AI 提示词纳入 `--check` / `--check-drift` / manifest，升级后可发现缺失或漂移。
- 消费者提示词覆盖新页面计划、列表分页、表单、接口、审计、升级、调试、测试与自检；
  form / api 场景按项目启用能力条件生成。
- 文件开头增加“先选场景”速查表与“让 AI 帮我选场景”的新手元提示词。
- 场景表随 form / api 能力裁剪；`--ai-prompts` 与 `--no-ai-prompts` 冲突时报错。
- 已有项目升级后 `init --check` 会报告 AI_PROMPTS 缺失；运行一次 init 或用 `--no-ai-prompts` 关闭。

### Fixed
- 消费方 form AGENTS 模板移除已删除的字段 `config` 说明。

## 1.9.17

### Fixed
- 新增统一入口 `dart run w_tools_cli:w_tools <command>`；旧的 6 个 bin 保留兼容。
- `init` 的 app/map 依赖片段更新为 `w_tools_app_getx` + `w_tools_map_google`。
- 统一退出码约定：`0` 成功 · `1` findings · `2` 参数/配置 · `3` 外部不可用。
- `init --check --force` 不再写 `.w_tools_doctor.yaml` / 生成 `.bak`；只报 drift。
- 自定义 `toolkit_entry` 现在会同步进 AGENTS 的 import 路径。
- `feedback --json` 的缺字段/参数错误也输出 JSON（`ok:false`）。
- 参数解析错误在 `--json` 下输出 JSON，而不是只写 stderr。
- 修正 `init --help` / README 的 device 生成物描述与反馈命令表。

## 1.9.16

### 修复
- 移除 `tool/device_smoke.dart` 默认生成；Tab 冒烟移到 `packages/device/example/tool/device_smoke.dart`，
  不再假定 5 个 tab / 94% 高度。
- `docs/agents/device-testing.md` 模板改为通用设备命令/矩阵，移除 GetX、bootstrap 路径、会员卡等业务假设。
- 旧 `--device-test` / `tool/device_smoke` 生成物只提示 stale，不自动删除。
- `feedback path --json` 在消费方返回 `kind=disabled` / `path=null`，不再返回旧本地收件箱路径。
- 根 `AGENTS.md` 的消费方反馈说明改为“默认关闭；`feedback.issue: true` 后 `--issue`”，移除 `--local` / 预填链接。
- `init` 旧设备文档提示按当前 device 状态给出 `--device --force-starters` 或 `--force-starters`。
- `--device-test` deprecation 警告进入 `warnings`（JSON 可见），不再只写 stderr。

## 1.9.15

### 变更
- `--device-test` 标记为 deprecated：仍可传入（不会 unknown option），但只按 `--device`
  生成设备工具并提示；不再生成通用 UI keep-alive integration_test。
- `--device` 只生成设备工具，并补 `w_tools_device` 依赖；keep-alive 示例移到
  `packages/ui/example/integration_test/` + `docs/recipes/keepalive-integration-test.md`。
- 旧版生成物 `integration_test/app_keepalive_smoke_test.dart` 仅提示 stale，不自动删除；
  旧 `docs/agents/device-testing.md` 若仍含 `--device-test`，`init` 会提示用
  `--force-starters` 更新。

## 1.9.14

### 修复
- 严格判定 w_tools 仓库：必须 `pubspec name=w_tools` + `packages/cli` + `docs/feedback/`；
  消费方自带 `docs/feedback/` 不再被误写。
- 包名白名单：拒绝 `foo` 等未知包，避免污染台账索引。
- `feedback submit` 无通道时在读取正文前直接跳过；`--linked-issue=<n>` 写台账关联 issue。
- 新增 `feedback status` 查看 ledger / issue / disabled。
- 错误提示改为 `feedback submit --template`（不再指向消费方不存在的仓库文件）。
- `--issue` 文档明确需要已安装 gh（gh 读取 token 或登录态）。
- `init` 检测到 `w_tools_device` 依赖时自动生成设备 starter / `docs/agents/device-testing.md`；
  `--no-device` 可关闭，禁用时给出提示。
- `context.commands` 暴露 `deviceList` / `deviceShot` / `deviceForeground`（安装 device 时），
  并把 feedback 命令改为 `feedbackStatus` / `feedbackSubmit`。
- device README / pubspec 描述增加平台支持矩阵（iOS 真机仅 list/shot）。

## 1.9.13

### 新增
- `feedback submit` 默认策略：本地 `docs/feedback/` 存在 → 直接写台账；否则
  `.w_tools_doctor.yaml` 的 `feedback.issue: true` → 建 Issue；都不满足 → 跳过（exit 0）。
- `feedback submit --ledger`：仅 w_tools 仓库检出可用，直接追加 `docs/feedback/<包>.md`，
  自动创建缺失包的台账并更新索引待处理数量。
- `feedback submit --issue`：显式创建 Issue（覆盖配置）；`--gh` 保留为别名。
- `.w_tools_doctor.yaml` 新增 `feedback.issue`（默认 false）；生成 AGENTS 改为“默认关闭”。

## 1.9.12

### 新增
- `feedback submit`：校验必填字段，默认生成 GitHub 预填 issue 链接（不上传）；
  `--gh` 直接建 issue，`--local` 离线写收件箱，`--json` 机器可读。
- `feedback search`：本地台账/收件箱查重；`--gh` 同时搜 GitHub issues。
- `templates/agents` 的使用反馈改为 `search → submit` 闭环，收尾必查。
- 新增 `.github/ISSUE_TEMPLATE/feedback.md`；`docs/agents/cli.md` / feedback 台账说明同步。

## 1.9.11

### 改进
- `init` 生成的子包约束同步本轮大版本：core ^3.0、ui ^5.0、form ^4.0、api ^5.0、
  app ^2.0、map ^2.0、toast ^2.0、async ^3.0；新增 `--reset`。
- `init` 始终沿用 `.w_tools/init.json` 的 profile/targets/lang，`--force` 不再静默重置；
  收尾按状态给 next actions，不再无条件 `doctor`。
- `init --json` 带 schema/schemaVersion/needsPubspec/nextActions，文件条目改为 `{path, note}`。
- `doctor` 的 `rules:` 开关对 R1–R5/R7/R8 真正生效；R7 fix 使用真实版本约束；
  `--write-config` 冲突退出码改为 2。
- `list` 无匹配退出码改为 1；`feedback` 缺子命令给出用法并退出 2；统一 `--format` / `--json`。
- `context --json`；doctor issue 带 `fix`；prompt 只列 w_tools/直接依赖并按优先级截断。
- 文本扫描统一去掉块注释 / raw string；`ignore` 支持 `**`；R3 识别 8 位 alpha 颜色。
- `feedback lint` 校验已修复版本号 / 不修理由。
- 组件目录：`WRoute` 条目改为 `WRouteStack`，移除已删除的 UI 组件引用。
- 新增 `docs/agents/cli.md`。

## 1.9.9

### 新增
- `.w_tools/init.json` 记录 `generator`（写这份 manifest 的 CLI 版本）；老文件没有该字段也能读。
- `validatePackageName` / `inboxFile` 提出为可测函数，补 bin 层入参校验测试
  （`../evil` / 大小写 / 空值；收件箱路径固定）。

## 1.9.8

### 改进
- `context.commands` 新增 `feedback` / `feedbackLint`：AI 走「先拿事实」时也能发现反馈入口
- `schema/context.v1.json` 补 `install` 属性（此前 additionalProperties 让它不报错但契约缺失）
- `scripts/check_feedback.sh`：缺 `.dart_tool/package_config.json` 时 **exit 2**（原来 exit 0 静默跳过，
  等于 CI 假绿）；提示先跑 `dart pub get`

### 发布
- 首次打 tag `v1.9.8`；消费方可用 `ref: v1.9.8` 代替 40 位 sha

## 1.9.7

### 改进
- `feedback lint`：`已确认` 条目必须链 issue（`#123` 或链接），否则报错
- `packages/cli/README.md` 新增 `feedback` 命令说明（命令怎么选表 + 子命令表）

## 1.9.6

### 修复
- `feedback lint --include-inbox`：仓库检出时**不再跳过**本项目收件箱（此前该参数实际无效）
- `feedback path --package=`：校验包名（`^[a-z0-9_]+$`），防 `../` 穿越
- `lintLibrary`：索引里列了不存在的文件、或有文件没进索引，都会报错

### 改进
- `lint` 新增 `--stale-days=<n>`（默认 30，0 关闭）：待处理超期给警告（不影响退出码）
- 字段检查改为按行首 `- 字段：` 匹配（允许「命令 / 输入」「影响（…）」这类后缀），
  不再因为正文里出现关键词就过关
- 索引正则允许数字（`e2e` 这类包名此前被误判「没进索引」）
- `scripts/check_feedback.sh` 退化为薄包装：规则只在 Dart lint 里实现一次（避免两套规则漂移）

## 1.9.5

### 新增
- `w_tools_cli:feedback path [--package=<包>]`：输出反馈该写到哪个文件
  （库侧 `<repo>/docs/feedback/<包>.md`，或本项目收件箱 `docs/agents/feedback.md`）。
- `w_tools_cli:feedback lint [--include-inbox]`：校验字段齐全、状态合法、已闭环带版本号、
  索引数量一致；AI 写完反馈可自检。
- AGENTS 模板改用 `feedback path` 取路径；「完成前」加一条 lint 自检。

## 1.9.4

### 新增
- `context --format=json` 新增 `install` 段：`packageRoot` / `repoRoot` / `isRepoCheckout` /
  `feedbackDir`。AI 据此判断「库侧 docs/feedback/ 在不在本机」，不用猜路径。
- AGENTS 的「使用反馈」一节改为先跑上面这条命令取 `feedbackDir`；为空就只写本地收件箱。

## 1.9.3

### 改进
- AGENTS 的「完成前」清单新增一条：本次用过 `w_tools_*` 且有卡点 → 写一条到
  `docs/agents/feedback.md`。把「记反馈」变成收尾动作，比单独一节更容易被执行。

## 1.9.2

### 新增
- `init` 生成的 AGENTS 里新增「使用反馈（给 AI）」一节：任何新项目装完 w_tools 就有
  「遇到问题 → 写 `docs/agents/feedback.md` 收件箱 → 维护者同步到 `docs/feedback/<包>.md`」的指引，
  不用每个项目手抄一遍。

## 1.9.1

### 改进
- `init --device` 生成的镜像示例改名为 `tool/gradle-mirror.init.gradle.example`：
  它是「复制到 `~/.gradle/init.gradle` 才生效」的示例，原名容易被误认为已自动生效。
  文档里的旧路径 `docs/templates/…` 一并修正。

## 1.9.0

### Changed（破坏性：路径）
- `init` 的 manifest 从 `.w_tools_init.json` 迁到 **`.w_tools/init.json`**（工具元数据收敛到 `.w_tools/`）。
  老项目首次 `init` 会自动迁移旧文件并提示。
- 其它生成物不变：`lib/app/w/toolkit.dart`、`lib/app/ui/*`、`AGENTS.md`、`.w_tools_doctor.yaml`
  仍在约定路径（它们必须可被 Dart / agent / Flutter 直接发现）。

# Changelog

## 1.9.10

### Fixed
- `init` 与 doctor 共用 `ProjectLayout`（唯一路径来源）；`init` 现在会读 `.w_tools_doctor.yaml` 的 `toolkit_entry`，不再与 doctor 的检查路径分叉。
- `init --check` 只把用户可见生成物算作缺失：内部 `.w_tools/init.json` 与可选的 `.w_tools_doctor.yaml` 不再让 CI 假红；`--check` 也不再写 manifest，`--check-drift` 不会因 CLI 升级而永久失败。
- `doctor --write-config --force` 覆盖前写 `.bak`（此前会静默抹掉项目维护的 palette / banned / ignore）。
- `feedback lint --stale-days=0` 真正关闭 stale 检查；非法值 exit 2 而不是静默回退 30。
- R2 在 `test/` / `tool/` / `integration_test/` 放行 `w_tools_{cli,figma,device,e2e}`：`tool/main_e2e.dart` 按文档必须直接 import `w_tools_e2e`；`lib/` 仍报错。`--include-tests` 一并扫描 `integration_test/`。

### Changed
- `catalog/components.yaml` 成为唯一来源：`gen_catalog` 同时生成 `catalog.g.dart` 与 `docs/modules/components.md` 的 §1~§9 表格；`catalog_test` 校验表格新鲜度与**每个别名**可被 `explain` 找到（补上 `WStepFlow`）。
- 子包约束表同步 `ui 3.1.0` / `form 2.1.0` / `api 1.0.2` / `map 1.3.0`。

## 1.8.1

### Changed
- device/E2E AI 入口明确：`w_tools_e2e` 只放 `tool/main_e2e.dart`，生产 `main.dart` 不 import。
- `.w_tools_init.json` 在普通 init 时始终更新（不受 --force 限制）；--check 只比对。
- 旧版无 marker toolkit 首次 --force 迁移时，自动把模板外的 export 追加到 `w_tools:end` 之后，并保留 `.bak`。

## 1.8.0

### 新增
- `init --device`：生成设备验证脚手架（`integration_test/app_smoke_test.dart`、`tool/device_smoke.dart`、`docs/agents/device-testing.md`、`tool/gradle-mirror.init.gradle`）。
- `init --force-starters`（`--force-ui` 别名）：显式覆盖 UI / device starter，覆盖前写 `.bak`。

### 修复
- `init --force` 不再覆盖 UI / device starter；只刷新生成物与配置。
- `init --force` 覆盖 `.w_tools_doctor.yaml` 前先备份 `.bak`。
- doctor R2 / ProjectFacts 的包名正则支持数字（如 `w_tools_e2e`）。
- doctor 的 `// w_tools:ignore` / `ignore-file` 支持 R2~R9；R3 只在未被忽略的命中上计阈值，R1 暂不支持。

### Changed
- 设备 starter 的 `--force` 语义改为 `--force-starters`。
- `toolkit.dart` 使用 `w_tools:begin/end` 标记块；`--force` 只更新块内，保留项目追加项。
- 新增 `.w_tools_init.json` 记录 init flags；`--check` 默认回放上次参数，避免参数不同导致假 drift。

## 1.7.5

### Changed
- `--figma` 模板补充 frames 过滤、多画板 spec、node-only 和自动缓存选择说明。

## 1.7.4

### Changed
- 没有 `w_tools_figma` 依赖时，模板生成 `dart pub add dev:w_tools_figma`，不再写死兜底版本。

## 1.7.3

### Changed
- `figmaConstraint` 默认值更新为 `^0.4.0`。

## 1.7.2

### Added
- `.w_tools_doctor.yaml` 的 `ai.figma: auto|true|false`；`init` 自动检测 pubspec 的 `w_tools_figma`，避免不带 `--figma` 时删除 Figma 片段。

### Changed
- `--figma` 片段不再重复 UI / form 组件规则；版本约束收敛到单一常量。
- `init --figma` 优先使用消费方 pubspec 的 `w_tools_figma` 约束；path/git 依赖不生成 pub 版本。

## 1.7.1

### Changed
- `init --figma` 模板升级到 `w_tools_figma ^0.3.0`，补充 frames / spec 深度 / tokens map / diff --if-stale。

## 1.7.0

### Added
- `init --figma` 生成 Figma → Flutter AGENTS 片段；不引入 `w_tools_figma` 依赖、不影响 toolkit。

## 1.6.1

### Changed
- AGENTS UI 片段补充 `lib/app/ui/` 是项目永久 UI 层、不走 STAGED、不计划上移。
- banned 段落增加 R9 只匹配已登记 pattern 的边界说明；英文输出改为英文标题与说明。
- AGENTS base 明确先判断永久 UI 层 / 暂存层；英文 banned 条目使用 use / reason 标签。
- AGENTS closing 自动生成 doctor 规则速查表；CLI 示例改用真实 `Image.asset` 禁用场景；CONTRIBUTING 补充 grep 检查经验。
- DoctorRule 内置中英文 summary，AGENTS 规则表与规则定义单一来源；base 去掉 no-ui 下的具体 UI 组件名。
- base 的 UI 分层说明移回 ui 片段；R3/R4 改用 TextScan，跳过行尾注释。
- doctor 规则表 summary 只描述规则；R6/R9 启用状态改由表头说明，避免 summary 混入项目状态。
- 修正 R9 示例 id 为 `no-raw-image`，文档索引与 AGENTS 维护说明同步为 R1~R9。
- README / conventions 增加无 CLI 时 grep 与 R1/R2/R4/R9 的映射，明确 `--include-tests` 与 R4 的覆盖边界。
- AGENTS base 补充上移候选要求（默认值/测试/CHANGELOG）与 API 参数 ≤ 3 的形状建议。
- base 明确 CHANGELOG 由包维护者在进入 w_tools 时补；文档补充 doctor 文本级/字符串边界说明；补英文模板测试。

## 1.6.0

### Added
- 新增 R9 项目禁用 API：`.w_tools_doctor.yaml` 的 `banned` 支持 literal / regex、paths / ignore、use / reason 与 level。
- 支持 `// w_tools:ignore R9 reason: ...` / `// w_tools:ignore-file R9 reason: ...`，没有 reason 不生效。
- `init` 会把有效 `banned` 生成到 AGENTS；`explain` 会提示当前项目禁用项。
- README 增加 5 分钟上手、命令决策表、升级后重新生成、退出码与 R9/banned 说明；`init` / `doctor` / `list` / `explain` 的 `--help` 补示例。
- R9 预编译 regex / 缓存 glob；banned 文档说明文本级匹配边界。
- AGENTS 模板按 app / form / api / async 能力裁剪；ui README 图片示例改用 `WImage.asset`。
- `context` 区分 pubspec / doctor 配置解析错误，并按项目类型输出 `flutter` / `dart` 命令；`explain` 支持 `--root` 并兜底坏配置。
- 新增 init 单项开关 `--no-form` / `--no-app` / `--no-api`；区分 pubspec.lock 解析错误。
- 抽出 `ProjectFacts`，让 context 与 R5/R7 共用 toolkit / 暂存层 / 依赖事实；新增 `--no-toast`。
- AGENTS 模板拆成 base + feature 片段（ui / form / api / app / async / toast / core / qr / map / closing），去掉 full / no_ui 两套大模板。
- init 能力参数统一为 `--<feature>` / `--no-<feature>`；新增 `--map` / `--no-map`，保留 `--with-map` 兼容别名。
- init 的 feature help 从注册表生成；所有 feature 正反参数冲突统一报错，JSON features 改用 `toJson()`。
- `context --format=json` 增加 `schema` 标识与 v1 JSON Schema；采用新增字段兼容、破坏性变化才 bump 的策略。
- context schema 测试使用 `json_schema` 校验真实 `toJson()` 输出，并用包根定位 schema 文件。
- 内部模型收敛：InitFeatures 改为 Set<InitFeature>，ProjectSnapshot 持有 ProjectFacts，不再复制字段。
- 命令层统一通过 `ProjectFiles.loadConfig` 读取 `.w_tools_doctor.yaml`，减少重复异常处理。
- R6 / R9 共用 `TextScan` 文本扫描，统一跳过整行注释与行号计算。
- R9 预过滤无效 banned 条目，避免每个源文件行重复 validate。
- R6/R9 跳过行尾 `//` 注释；R2 同时检查 `export package:w_tools_*`。

### Changed
- 消费方 AGENTS 模板补充 `WTextVariant` 不够用时的处理顺序：先 `variant + style`，项目内重复抽本地 helper，稳定跨页面语义再提库内 variant。
- 组件目录同步 `WText` 的 variant 边界说明。
- 消费方 AGENTS 模板统一间距入口：`SizedBox` 用 `WSizeBox`，`Padding` 用 `WPadding`，`EdgeInsets` 用 `num.allPadding`；不再推荐 `num.heightBox` / `widthBox` / `squareBox`。

## 1.5.0

- 已发布版本（此前的模板与文档修正；不含 1.6.0 的 R9 / schema / feature registry）。

## 1.4.0

### Changed
- 消费方 AGENTS 模板补充 Form 直接字段、WImage、弹层与轻提示规则；修正不存在的 `WnnToast` 引用。
- 消费方 AGENTS 不再放完整按钮代码，仅保留决策规则；完整模板留在 docs/agents/button.md。
- 组件目录同步 Form 的 `WForm` / 直接字段 / `WFormFieldStyle` 入口，移除旧 App helper 名称。
- 升级 `w_tools_cli` 后，消费方需重新执行 `dart run w_tools_cli:init`（或 `--check-drift`）以更新 AGENTS 片段。
- 修复 `init` 生成的 `w_tools_ui` 约束仍为 `^2.1.0`：同步到 `^3.0.0`，避免新项目解析到旧 UI。
- 消费方 AGENTS 与组件目录补充 `w_tools_api` 的 `DioRegistry` / `WTokenInterceptor` / `WLogInterceptor` 网络规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_app` 的 `WApp.start` / 插件依赖 / `WLanguage` / `WRouteObserver` 启动规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_core` 的 `WStorage.init` / 明文存储 / `WValidator` 与 `WRegExp` 分工规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_qr` 的 `WQrView` / `WQrController` / `restartScan` 扫码规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_map` 的 `WMap` / `WMapZone` / `WMapItemMapper` 地图规则，仅在 `--with-map` 时生成。
- 新增 `example/`：命令演示与基于临时 `demo_project` 的可复现 init / check-drift / doctor / context / list / explain 流程；脚本自动准备依赖并清理临时目录。
- `DoctorConfig.copyWith` 支持覆盖 `colorMinCount` / `ignore`。

## 1.3.0

### Added
- 新增 `w_tools_async` 子包支持：`init --profile=full` 默认导出，
  `--no-async` 可关闭；`toolkit` / pubspec 片段同步。

## 1.2.0

### Added
- `init` 生成 `lib/app/ui/app_bars.dart`、`app_boxes.dart`、`app_buttons.dart`、
  `app_card.dart` 与 `app_scaffold.dart`：标准页面默认使用 `AppScaffold`，
  AppBar / 盒子 / 按钮样式统一走 `AppBars.style` / `AppBoxes` / `AppButtons`，
  重复卡片用 `AppCard`。`lib/app/design_system/` 只保留待上移组件。
  `AppBoxes.card` / `warning` 跟随主题；`AppCard` 默认使用 `AppBoxes.card(context)`，
  支持 `clipBehavior`。
- AGENTS / 暂存层规范补充：真按钮用 `WButton`，任意 child/卡片点击用 `WPressable`。
- toolkit 导出 AppScaffold/AppBars/AppButtons；AGENTS / `lib/app/ui/README.md`
  增加页面与按钮规范。
- 固定 `lib/app/ui/` 与 `lib/app/design_system/`：R2/R4/R5 与 init 使用同一套路径。
- `init --no-ui`：不生成 `lib/app/ui/` 与 `design_system/`，不导出 `w_tools_ui`，AGENTS 不写 UI 规则。
- `init --profile=minimal|ui|api|full`：按能力组合生成 toolkit 与依赖片段。
- `init --no-instructions`：不生成/不检查 AGENTS 等 AI 指令文件，优先于 `--targets`。
- help 明确 UI 生成条件；text 输出 profile / features / targets；R8 文档说明跳过 UI starter。
- `init` 报告 profile / targets 切换后遗留的 UI 与指令文件（`stale`），但不会自动删除。
- R5 / context 只统计 `.dart` 暂存文件，不再把 `design_system/README.md` 算作缺 `// STAGED`。
- R4 同时检查 `lib/app/ui/` 与 `design_system/`，项目 UI 也不得依赖业务层；R3 对这两层豁免硬编码色。
- `lib/app/ui/` 下的 App* 与 README 视为 starter：自定义后不算 drift，也不会被
  `init` / `--check-drift` 覆盖。
- 新增 `tool/check_templates_compile.dart`，CI 用 Flutter analyze 编译检查生成的 UI starter。
- 迁移：旧版生成的 `design_system/app_*.dart` 移到 `lib/app/ui/`；
  toolkit 的 export 改为 `../ui/...`。

## 1.1.1

### Changed
- `init` 生成的 pubspec 片段把 `w_tools_ui` 约束更新到 `^2.0.0`
  （配合 `w_tools_ui 1.2.0` 的 `String.toImage` 增强）。

## 1.1.0

### Added
- `dart run w_tools_cli:context`：输出项目事实（已装版本、toolkit 导出、暂存层、
  规则、当前检查结果），支持 `--format=json|markdown|prompt` 与 `--max-tokens`。
- `dart run w_tools_cli:list` / `:explain`：内置组件目录查询（来源
  `catalog/components.yaml`，生成 `catalog.g.dart`），避免凭记忆造组件名。
- `init --json`：机器可读的初始化结果。
- `init --targets=agents,claude,cursor,copilot`：同一份指令写到多个 agent 文件；
  `cursor` 新文件带 frontmatter。`--lang=zh|en` 生成中英文指令；
  `.w_tools_doctor.yaml` 的 `ai.targets` / `ai.language` 可作为默认值。
- 生成物头部带 `generated by w_tools_cli x.y.z`，`doctor` 的 R8 检查是否过期。
- `doctor` 新增 R7（toolkit 与 pubspec 依赖一致）、R8（生成物版本）。
- `doctor --format=markdown`：可直接粘给 AI / PR 评论的摘要。
- `doctor --json` 的 issue 增加结构化 `fix`（`run` / `edit`），AI 可直接执行；
  没有 `fix` 时继续用 `hint`。

### Changed
- `init` 的 AGENTS/CLAUDE 片段升级为 AI 工作流（context → list/explain → doctor）。
- 5 个入口共用 CLI runner，`--version` / `--help` 行为一致；
  `list` / `explain` 支持 `--format=json`。
- 规则注册表统一到 `doctorRules`，新增规则只改一处；规则间共享文件读取缓存。
- `R7` 不再重复报告聚合包 `w_tools`（由 R1 负责）。

### Fixed
- 生成的指令会代入真实项目名（不再留下 `<app>` 占位符）。
- R8 不再把用户手写的 `CLAUDE.md` / copilot 文件当成生成物误报。
- `init` 的 pubspec 片段在已有 `dependencies` / `dev_dependencies` 时只追加缩进行，
  避免复制出重复的顶层 key。

## 1.0.0

首次发布：`init` / `doctor`（R1~R6）、模板生成与 `.w_tools_doctor.yaml`。
