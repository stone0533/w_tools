> 分析记录：**P0 / P1 / P2-a / D-1 / C3 / P3 已落地并发布**（`w_tools_app 4.2.0` /
> `w_tools_app_getx 3.3.0` / `w_tools_cli 2.9.14`，2026-11-26；PR #430 / #432，
> 快照 PR #431 / #433，`release_status --online --check` 正常）。剩余 A3、P2-b、预设包。
> 基线 `main @ 7f0b3d92`。设计决策见 [ADR-0019](../adr/0019-app-runtime-state.md)。

# w_tools_app 完善方案分析（2026-11-26）

> 问题：以 `w_tools_app`（契约内核）+ `w_tools_app_getx`（GetX 启动层）为对象，
> 结合当前全部 w_tools 分包（core / async / async_ui / ui / form / api / toast / qr /
> map / map_google / e2e）判断「app 还需要怎么完善」，给出可执行建议。
> 关联 ADR：[0005](../adr/0005-app-options-and-plugin-ownership.md)、
> [0012](../adr/0012-app-tree-scopes.md)、[0017](../adr/0017-app-startup-observability.md)、
> [0011](../adr/0011-api-surface-budget.md)、[0006](../adr/0006-package-topology.md)。

## 结论

1. **机制层已经够用，不需要再往 app 塞能力。** 4.1.0 / 4.1.1 把插件依赖分层、首帧钩子、
   超时 / 关键性、启动报告、测试宿主、系统栏兜底补齐了；app 现在 60 条公开面、只依赖
   flutter，这个边界是对的（ADR-0005 / 0006）。
2. **真正的短板有三类**：① 两个**已实测**的语义缺陷（非关键插件失败后永不重试、
   直接使用 runner 时并发 `init()` 重复执行插件）；② **应用级状态不对称**（语言是活状态，
   外观是死值；语言还缺「跟随系统」的表达）；③ **与其它子包的装配缺一份可编译的真相**
   ——9 个运行时包里 6 个需要消费方在启动期写代码（core / api / toast / async / ui / e2e），
   app 只提供机制不提供内容，消费方各自抄 4~6 个插件，而现有 recipe 用的还是裸
   `MaterialApp`。
3. **推荐方案**：不新增包、不给 app 加依赖，按「P0 修语义 → P1 补状态 → P2 补装配」
   三段走（详见下文「方案」）。新预设包（`w_tools_app_presets`）留作有反馈证据后的选项；
   「插件塞进 app」维持 ADR-0005 的否决。

## 现状盘点

### app 的两层与职责

| 层 | 位置 | 依赖 | 公开面（快照条目） | 职责 |
|---|---|---|---|---|
| 契约内核 | `packages/app`（lib 648 行 / 测试 673 行） | 只有 `flutter` | 60 | 插件契约与编排、语言状态与 scope、外观配置 |
| GetX 启动层 | `packages/app_getx`（lib 926 行） | `get` / `flutter_localizations` / `w_tools_app` | 71 | `WApp` / `WAppOptions`、路由栈与观察者、底部弹窗、启动报告、测试宿主 |

### 4.1.x / 3.2.0 已经解决的问题

| 能力 | 落点 | 评价 |
|---|---|---|
| `dependsOn` 分层 + 同层串行 | `app_plugin_runner.dart` | 足够表达「storage → api → 业务」顺序 |
| `onFirstFrame` + 补排一帧 | 同上 | 闪屏 / e2e ready / 预热有地方放 |
| `timeout` / `critical` + typed 异常 | 同上 | 白屏问题有了可控边界 |
| `WAppStartupReport` + `startupLog` | `startup_report.dart` / `app.dart` | 启动慢可定位到插件名 |
| `buildRoot()` 测试宿主 | `app.dart` | 消除了 49 处手搭装配 |
| `WAppScope` / `WLanguageScope` | `app.dart` / `language_scope.dart` | 页面不再保存全局 app |
| 系统栏 `AnnotatedRegion` 兜底 | `app.dart` | 浅色页面返回后能恢复 |

结论：这一层不需要「再加一个大功能」。缺的是语义收口与状态补全。

### 9 个分包的启动期要求 vs app 的承接方式

| 包 | 启动期要求（事实源） | app 现在怎么接 | 是否需要消费方写代码 |
|---|---|---|---|
| core | `await WStorage.init()` 后才能读写（`packages/core/README.md:43`） | 无插件 | 是，自建插件 |
| api | `WApiSettings.baseOptions` / `DioRegistry.forBaseUrl` / token getter（`packages/api/example/lib/main.dart:50-100`） | 无插件 | 是，自建插件，且要 `dependsOn` storage |
| toast | `BotToastInit()` 必须在 `MaterialApp.builder`；`BotToastNavigatorObserver`（`packages/toast/README.md:23-27`） | `builder` + 插件 `navigatorObservers` 可承接 | 是，两处手写 |
| async | `WAsyncTheme` 根注入；`WAsyncExecutor` 由 app 层注册（ADR-0015，`packages/async/README.md:215`） | `appWrapper` + 插件可承接 | 是，抄 README 的 `AsyncExecutorPlugin` |
| async_ui | 依赖 `WAsyncTheme` | 同上 | 否（随 async） |
| ui | `WScreenScope` / `WTextStyles` 在 build 期构建（`packages/ui/README.md:482`、`docs/modules/ui_module.md:40-50`） | `builder` 可承接 | 是，配方散在 AGENTS / ui 文档 |
| form | `localizationsDelegates`（`packages/form/README.md:176`） | `WAppOptions.localizationsDelegates` | 否，已覆盖 |
| qr | 相机生命周期 / 平台权限 | 页面级 | 不属 app 职责 |
| map_google | API key 平台配置 | 非 Dart 启动期 | 不属 app 职责 |
| e2e | `E2eSignals.ready` 首屏标记（`docs/recipes/e2e-login.md`） | 插件 `onFirstFrame` 最合适 | 是，自建插件 |

**读法**：机制齐全、内容为零。9 个运行时包里 6 个需要消费方在启动期写代码（core / api /
toast / async / ui / e2e），其中 form 已被 `localizationsDelegates` 覆盖、async_ui 随 async；
qr / map 的启动期工作不在 Dart 层。而 app 只给了「放哪儿」（插件 / `appWrapper` / `builder` /
`navigatorObservers`），没给「写什么」。

## 缺口

### A. 内核语义缺陷（patch 级，已实测）

> 本节记录**修复前**的事实；A1（非关键失败可重试）、A2（并发去重）与首帧补发已在
> `w_tools_app 4.1.2` 修复，见下文「落地结果」。

**A1 非关键插件失败后永不重试，但文档说的是「从失败点继续」**

- 代码：`packages/app/lib/src/plugins/app_plugin_runner.dart:97-108` —— `critical: false`
  失败时同时写 `_failed` 和 `_completed`；下一次 `init()` 的 `pending` 按 `_completed`
  过滤，于是这个插件被永久跳过。
- 文档：`packages/app/lib/src/plugins/app_plugin.dart:49-51` 与 README 只写了
  「已成功的插件不会重复执行」，读者会理解成失败插件会重试。
- 实测（临时探针，已删除）：两次 `await runner.init()`，非关键失败插件 `onInit` 只执行
  **1** 次；同等条件下关键插件是 2 次。
- 影响：非关键插件（埋点 / 推送 / 预取）失败后，即使调用方按文档重试 `start()`，
  它也永远起不来，且没有任何提示。

**A2 直接使用 `WAppPluginRunner` 时，并发 `init()` 会重复执行插件**

- 代码：`init()` 只在结尾写 `_initialized`，没有 in-flight future 去重；
  `WApp` 自己用 `_initFuture` 挡住了（`packages/app_getx/lib/src/app.dart:99-113`），
  runner 没有。
- 实测：同时调两次 `runner.init()`，`onInit` 执行 **2** 次。
- 影响：runner 是对外声明「任何应用壳都可以复用」（`app_plugin_runner.dart:10-13`），
  非 GetX 壳没有 WApp 那层保护；`WApp` 之外的入口是裸奔的。

**A3 `dependsOn` 只表达顺序，不表达前置条件**

- `critical: false` 的插件失败后，依赖它的插件**仍然执行**，且这一行为被测试锁定
  （`packages/app/test/plugin_runner_test.dart:224`）。
- 这不算 bug，但缺一个表达「依赖失败就别跑我」的开关；api 依赖 storage 这类场景
  一旦 storage 失败，api 插件的失败会以更难懂的方式暴露。

### B. 应用级状态不对称

**B1 外观是死值：没有运行时切换主题模式的能力**

- `WAppTheme.mode` 在 `buildRoot()` 里读一次（`app_getx/lib/src/app.dart:350-353`）；
  `WApp.options` 与 `WAppOptions.theme` 都是 `final`，而 `start()` 只能调一次。
- 对比语言：`WLanguage` 有 `ValueNotifier` + `WLanguageScope`，切语言自动重建。
  **深色模式开关这个最普通的需求，当前公开 API 无法实现**（只能新建 `WApp` 实例再
  `runApp`，`WAppScope` 等全部重来）。
- 这是本文认为最有产品价值的一条。

**B2 语言没有「跟随系统」的表达，`hasExplicitSelection` 几乎不可用**

- `WLanguage.fromConfig(config)` 只要 `config != null` 就把 `explicitSelection` 置 true
  （`packages/app/lib/src/language/language.dart:23-39`）；
  `WApp.buildRoot` 因此恒用 `language.currentLocale`（`app_getx/lib/src/app.dart:315`）。
- 不传 `localeConfig` 时，`WLanguage.supportedLanguages` 只有 `en_US`
  （`language.dart:28-31`），`changeLanguage('zh_CN')` 返回 false —— 语言开关根本转不动。
- 结果：**「传了语言列表」= 强制某个语言；「不传」= 只有英语且不能切**。
  「用户没选过 → 跟随系统；选过 → 用选择」这个标准场景没有 API 能表达，
  也没有 `didChangeLocales` 的运行时同步（全仓 grep 无该回调）。
- 相关：`hasExplicitSelection` 只有在「完全没配语言」时才是 false，语义边界没有文档，
  容易被误当成「用户是否手动切过」。

**B3 没有释放路径**

- `WLanguage` 的 `StreamController` / `ValueNotifier` 从不 close；`WApp` 的语言监听
  只加不减（`app_getx/lib/src/app.dart:380-389`，`buildRoot()` 每次都调）；
  runner 也没有 reset。
- 影响：widget 测试里反复 `buildRoot()` 会累积 listener；同一进程多实例（测试 / 预览）
  没有干净的拆卸方式。当前靠「应用只起一次」兜着。

### C. 与子包的装配缺一份可编译的真相

**C1 没有「全栈启动」的配方或示例**

- `docs/recipes/app-shell-theme.md` 讲根装配，但用的是**裸 `runApp` + `MaterialApp`**，
  不是 `WApp`；`docs/agents/app.md` 只有零散片段。
- `packages/app_getx/example` 里全是假插件（env / route-observer / feature），
  不接任何真子包；根 `example/` 只演示聚合包，不含 app。
- 后果：没人能证明「storage + api + toast + async executor + e2e ready」这套顺序在
  `WApp` 下真的能跑；每个消费方各自拼，漂移无从发现。

**C2 CLI 不生成启动骨架，但生态已经假设消费方有 `bootstrap()`**

- `w_tools_cli init` 生成 `toolkit.dart` / `AGENTS` / UI starters，**不生成**
  `main.dart` 或 `lib/app/app_boot.dart`（`packages/cli/lib/src/init/command.dart` 的生成清单）。
- 而 `docs/recipes/e2e-login.md` 直接假设消费方有 `bootstrap(afterStart: ...)`。
- 于是「初始化顺序」这件事既没有产物、也没有模板，只在文档里口口相传。

**C3 跨包组合没有测试兜底**

- app / app_getx 的测试不与任何子包组合（`packages/app_getx/test/` 全部用假插件）。
- 装配漂移（`appWrapper` 漏 `WToastTheme`、`builder` 漏 `BotToastInit`）只能靠人肉发现。

### D. 可观测 / 测试的尾巴

- `packages/app/coverage/lcov.info` 只有 5 行（仅 `app_plugin.dart`），说明覆盖率产物
  不完整、也没进任何门禁；新增能力的回归网实际是「测试文件在不在」。
- 缺 A1 / A2 的用例 —— 正是这两处漏网的原因。
- `firstFrame()` 串行 `await` 每个插件（`app_plugin_runner.dart:131-145`），一个慢插件
  会拖住后面的首帧收尾；启动报告也没有回调入口（埋点只能 `start()` 之后轮询）。

## 方案

### 方案 1（推荐）：不新增包、不给 app 加依赖，分三段补

#### P0 修语义（已完成：app 4.1.2 / app_getx 3.2.1，均为 patch，无公开 API 变化）

| 项 | 做法 | 状态 / 证据 |
|---|---|---|
| A1 | 非关键失败只进 `_failed`，不写 `_completed`；`init()` 的「已完成」判断改为「成功后不再执行，有失败就重试」；`WApp` 按上一轮 runner 记录决定是否放行 `init()` | ✅ `packages/app/lib/src/plugins/app_plugin_runner.dart`、`packages/app_getx/lib/src/app.dart`；两次 `init()` → 非关键失败插件执行 2 次 |
| A2 | runner 内部加 in-flight `Future` 去重，与 `WApp._initFuture` 一致 | ✅ 并发两次 `init()` → `onInit` 只执行 1 次 |
| A3 | 文档明确「`dependsOn` 只表顺序」；「依赖失败就跳过」留作单独评估（会改行为，需 ADR） | ✅ 文档已写明；跳过开关未做 |
| 报告 | `WAppStartupReport.pluginRuns` 只保留最近一轮，重试后 `failures` 不再残留历史失败 | ✅ `packages/app_getx/lib/src/startup_report.dart` + `app.dart` |
| 首帧 | `firstFrame()` 改为「已成功且未通知」筛选：重试后才成功的插件补发一次，每个插件仍最多一次 | ✅ `plugin_runner.dart` |
| 测试 | 两条守卫各自做定向变异（`scripts/mutate_guard.sh`），删掉修复必红 | ✅ 变异均被杀死 |

> 落地时发现：`WApp` 的重试放行可以只用「上一轮 `runs` 增量」判断，不需要新增公开成员，
> 因此 A1/A2 仍是 patch（`scripts/check_api_budget.py` 通过）；代价是 `WApp` 内部多一个
> 私有标记，没有暴露成 API。

##### 落地结果（2026-11-26）

- `w_tools_app 4.2.0`：runner 并发去重、失败可重试、首帧补发（原计划 4.1.2，因与 P1 同波未单独发布，
  CHANGELOG 已并入 4.2.0）；`w_tools_app_getx 3.3.0`：`init()` 可重试失败插件、启动报告只留最近一轮；
- `w_tools_cli 2.9.14`：`init` 的 `versions.dart` 跟随上述两包；
- 门禁：`preflight --changed`、`check_versions`、`check_api_budget`、`check_docs`、
  `release_check` 全绿；
- 未做：A3 的「依赖失败跳过」开关（需要 ADR），P1 / P2 全部未动。

#### P1 补状态（app 4.2.0 / app_getx 3.3.0，minor）

| 项 | 建议 API | 预算 |
|---|---|---|
| B1 主题运行时可切 | `WApp.themeMode`（`ValueListenable<ThemeMode>`）+ `WApp.setThemeMode(ThemeMode)`；`buildRoot` 读实时值 | 2 成员，app_getx 默认 growth 3，**不需要例外** |
| B2 语言跟随系统 | `WLocaleConfig.followSystem` + `WLanguage.followSystem`；`WApp` 作 `WidgetsBindingObserver`，`didChangeLocales` 时用 `basicLocaleListResolution` 解析并回写 | 2 成员，app 默认 growth 3，**不需要例外**；但语义变化要写 ADR |
| B3 释放 | `WLanguage.dispose()` / `WApp.dispose()`（移除 listener / observer、close controller） | 2 成员 |

注意：

- 预算余量正好用满：`allowed_growth = max(3, ceil(快照条目数 × 3%))`，app（60 条）与
  app_getx（71 条）都是 3。上表 B1+B3 用满 app_getx 的 3 个、B2+B3 用满 app 的 3 个，
  再想加成员就得拆成两个 minor 或抬 `growth`（后者要写理由）。
- 新增**公开类型**（例如把主题状态抽成 `WThemeModeController`）要 ADR + `scripts/api_budget.yaml`
  例外（ADR-0011）；只加成员不受影响。建议先加 `WApp` 成员，等出现非 GetX 需求再抽类型。
- B2 会改 `hasExplicitSelection` 的语义，属于行为变化；需要一段迁移说明
  （`docs/migrations/app-4.2.md`）与「旧行为 → 新写法」对照。

#### P2 补装配（docs + cli，不新增运行时依赖）

1. **`docs/recipes/app-boot.md`（新增）**：一份 `WApp` 版全栈启动，含
   `storage → api（依赖 storage）→ async executor / toast → e2e ready` 的 `dependsOn` 链，
   以及「8 个包的启动期要求 → 在 `WApp` 里放哪」映射表（插件 / `appWrapper` / `builder` /
   `navigatorObservers`）。同时给 `app-shell-theme.md` 加一句「WApp 项目看 app-boot」，
   避免两份配方互相打架。
2. **CLI 生成启动骨架（可选，收益最大也最贵）**：`init --profile=full|api` 生成
   `lib/app/app_boot.dart`（消费方可删的骨架，插件带 `dependsOn` 注释），进 `templates/`
   + `gen_templates.dart` + drift 检查。这样「初始化顺序」有了产物，CLI 也不用知道消费方
   具体 SDK。
3. **示例至少接一个真子包**：`packages/app_getx/example` 建议接 `w_tools_core`
   （`WStorage` 插件），证明插件不是摆设；更重的 api / toast 留在 recipe 里，避免把
   dio / bot_toast 拖进示例的解析成本。
4. **防止 recipe 漂移**：仿 `command_contract_test.dart`，用测试断言 recipe 里出现的插件名
   与 `dependsOn` 顺序和 `docs/agents/app.md`、catalog 的 `explain WApp` 一致
   （比人手维护两份散文便宜）。

### 方案 2（可选，成本高）：新增可选应用层包 `w_tools_app_presets`

- 依赖 `w_tools_app` + core / api / toast / async，提供 `WStoragePlugin` / `WApiPlugin` /
  `WToastPlugin` / `WAsyncExecutorPlugin` + 一个 `wToolsAppWrapper()`。
- 拓扑上合法：ADR-0006 允许「应用层 → 核心」的单向例外，ADR-0013 的 `async_ui` 是先例。
- 但代价是**再开一个聚合面**：`get` + `dio` + `bot_toast` + `cached_network_image` 会一起进
  依赖图，与 ADR-0002「装多少用多少」的精神相抵；还要 manifest / 文档矩阵 / CI / 发布顺序。
- **触发条件**：`docs/feedback/` 里出现 ≥3 个消费方重复同一套插件，或 C1/C2 落地后仍有
  反馈说「不知道启动该写什么」。没有证据前不做。

### 方案 3（否决）：把「一等公民插件」塞进 `w_tools_app`

ADR-0005 已否决（会把 `cached_network_image` 等拖进所有 app 用户）；本文复核后结论不变：
app 的价值在「零依赖的机制层」，一旦承载具体 SDK 就退化成聚合包。

## 建议排期

| 阶段 | 内容 | 版本 | 公开 API | 门禁 |
|---|---|---|---|---|
| 1 | A1 / A2 + 报告 / 首帧 + 文档口径 | ✅ 已并入 app 4.2.0 / app_getx 3.3.0 | 无 | 已通过：`preflight --changed`、`mutate_guard`、`release_check` |
| 2 | B2（跟随系统）+ B3（`WLanguage.dispose`） | ✅ app 4.2.0 | 有（3 成员，用满） | 已通过：`preflight --changed`、`check_api_budget`、`check_public_api_diff` |
| 3 | B1（主题运行时可切）+ B3（`WApp.dispose`） | ✅ app_getx 3.3.0 | 有（3 成员，用满） | 同上 |
| 4 | `docs/recipes/app-boot.md` + `app-shell-theme` 交叉引用 | ✅ docs（契约测试未做） | 无 | `check_docs.sh` |
| 5 | CLI 生成 `app_boot.dart` | 待做：cli minor（按需） | 命令产物 | `gen_templates` + CLI 测试 + `init_test` |
| 6 | A3（`dependsOn` 失败跳过） | 待做：app 4.3.0（等反馈） | 有（2 成员） | 同上 + 定向变异 |
| 7 | 预设包（仅在触发条件下） | 未排期 | 新包 | 新增包清单（AGENTS「新增包」全部条目） |
| 8 | D：覆盖率下限 / 启动报告回调 | 待做：chore / 下个 minor | 无 / 1 成员 | CI + `check_coverage` |


## 未做项：设计与建议（2026-11-26 追加）

> P0 已落地；本节只覆盖剩下的 A3 / P1（B1、B2、B3）/ P2（C1、C2、C3）/ D。
> 每项写清「现状 → 选项 → 推荐 → 预算与版本 → 验收 → 风险」。
> 结论先行：**B2+B3（app）与 B1+B3（app_getx）同一波；P2-a 文档紧跟；P2-b、A3 按反馈**。

##### 落地结果（2026-11-26，P1 + P2-a）

- `w_tools_app 4.2.0` / `w_tools_app_getx 3.3.0` / `w_tools_cli 2.9.14`；设计决策见
  [ADR-0019](../adr/0019-app-runtime-state.md)；配方见 [`docs/recipes/app-boot.md`](../recipes/app-boot.md)。
- 实现偏差（相对本节预测）：① B2 用 `changeLanguage(..., userSelected: false)`，没有新增
  `applySystemLocale`（省 1 个成员给 `dispose`）；② 实现时发现 GetX 自带的
  `GetMaterialController.didChangeLocales` 会把 `Get.locale` 设成未按 `supportedLocales`
  解析的 `deviceLocale` 并整树 reassemble，所以 `WApp` 在首帧后把它移除（ADR-0019 决策 3）；
  ③ 系统语言不命中时显式走 `fallbackLanguage`，不依赖 `basicLocaleListResolution` 的“退回第一个”。
- 预算：两包各 +3 成员 / 预算 3，**未登记例外**；`changeLanguage` 与
  `WLocaleConfig.new` 的新参数是 additive，已在 CHANGELOG 记录。
- 附带修门禁误报：`scripts/check_public_api_diff.py` 与 `scripts/check_api_budget.py`
  不再把**私有成员**（`X._` 私有构造）的签名变化当作公开 API 变化要求 Breaking / 抬 major，
  两处各补了单测（私有构造签名变化 → 不报）。
- 测试：`theme_mode_test.dart` 锁「切主题不重置路由栈」；`system_locale_test.dart` 覆盖
  启动解析 / 系统变化 / 用户选择优先 / fallback；`language_test.dart` / `locale_config_test.dart`
  覆盖 `followSystem` 语义与 `dispose`。
- 定向变异（`scripts/mutate_guard.sh`）：把 `themeMode: mode` 改回 `appTheme.mode`、
  去掉 `_syncSystemLocale` 的 `isFollowingSystem` 守卫，两条用例均变红（变异被杀死）。

### 0. 先算预算（决定哪些能同批）

| 包 | 已发布基线 | 默认 growth | 计划净增 | 结论 |
|---|---|---|---|---|
| `w_tools_app` | 60 条（4.1.1 快照） | `max(3, ceil(60×3%))` = 3 | B2：`WLocaleConfig.followSystem`、`WLanguage.isFollowingSystem`；B3：`WLanguage.dispose` = **3** | 用满，不需要例外；A3 的 2 个（`WAppPlugin.requiresDependencies`、`WAppPluginRun.skipped`）留给下个 minor |
| `w_tools_app_getx` | 71 条（3.2.0 快照） | 3 | B1：`themeMode`、`setThemeMode`；B3：`WApp.dispose` = **3** | 用满；`onStartupReport` 之类要等下一个 minor |

两条容易踩的规则：

- **预算按「已发布快照」重新起算**：4.2.0 用满 3 个不影响 4.3.0 再要 2-3 个，所以 A3 单独一批是可行的。
- **不要给 `WApp` 加 `with WidgetsBindingObserver`**：`check_public_api_diff.py` 合并父类型成员时只认
  包内声明的类型（未知父类型直接跳过），flutter 的继承成员不会进快照、预算拦不住，但
  `didChangeAppLifecycleState` 这些会真的变成 `WApp` 的公开可调用面。用私有 observer 类承接。

### A3 `dependsOn` 失败传播（建议：先只写文档，实现等反馈）

现状（4.1.2 保留）：非关键插件失败后，依赖它的插件**仍然执行**，且这条被测试锁定
（`packages/app/test/plugin_runner_test.dart` 的 `critical: false` 用例）。

| 选项 | 成本 | 评价 |
|---|---|---|
| ① 文档 + 配方示例：「强依赖」在 `onInit` 自己检查前置（抛错或直接 return） | 0 | 现在就能写清；不改语义 |
| ② 每插件 `bool get requiresDependencies` + `WAppPluginRun.skipped` | app +2 成员 | 强 / 弱依赖可区分（storage→api 是硬依赖，analytics→push 不是），表达力最好 |
| ③ runner 级开关 + `WAppOptions.skipDependentsOnFailure` | app +1、app_getx +1 | 一个应用只能一种策略，粗；且要动 options |

推荐 ①。理由：没有反馈证明需要；一旦加就有三个语义要定（skip 算不算失败、要不要重试、报告怎么显示），
属于「先设计再动手」的改动。

若将来做 ②，规则建议固定为：

- skip **不是失败也不是完成**：`_failed` 只收真失败，skip 走本轮的局部集合（循环里排除、pass 结束从 pending 移除）；
- skip 的插件不进 `_completed` → 下一次 `init()` 会重试（依赖可能已经恢复）；
- `WAppPluginRun.ok` 仍是 `error == null`，新增 `skipped`；`WAppStartupReport.failures` 过滤掉 skipped；
- `WApp._hasPluginFailures` 要把 skip 算进去，否则不会触发重试；
- 验收：A 失败 → B 被跳过 → A 重试成功后 B 在下一轮执行；删掉传播逻辑必红。

### B1 运行时主题切换（✅ 已落地：app_getx 3.3.0）

> 实现与本节设计一致：`themeMode` + `setThemeMode`，`ValueListenableBuilder` 包在
> `appWrapper` 内侧；没有引入 `WThemeController`。测试见
> `packages/app_getx/test/theme_mode_test.dart`（含「切主题不重置路由栈」）。

现状：`WAppTheme.mode` 只在 `buildRoot` 读一次（`packages/app_getx/lib/src/app.dart` 的 `themeMode:`），
`WApp.options` 与 `WAppOptions.theme` 都是 `final`，`start()` 只能一次 —— 深色模式开关没有公开入口。

推荐 API（只加成员，不加类型）：

| 成员 | 类型 | 语义 |
|---|---|---|
| `themeMode` | `ValueListenable<ThemeMode>` | 只读；初值 `options.theme?.mode ?? ThemeMode.system` |
| `setThemeMode(ThemeMode)` | `void` | 运行时切换；不持久化（与语言一致，持久化归消费方） |

实现要点：

- `WApp` 构造时建 `ValueNotifier<ThemeMode>`；`buildRoot` 在 `appWrapper` 与 `GetMaterialApp` 之间插
  `ValueListenableBuilder`，只重建 MaterialApp 子树（`ThemeMode` 是 MaterialApp 的入参，更新不会重置 Navigator）；
- 优先级不变：`start(theme:)` / `buildRoot(theme:)` 仍只覆盖亮色 `ThemeData`；运行时模式以 `themeMode` 为准；
- `setThemeMode` 不需要 `Get.rootController.update()`（MaterialApp 自己的 `AnimatedTheme` 会处理）。

不做 `WThemeController` + `WThemeScope`：对称是优点，但新类型要 ADR + `api_budget` 例外 + 文档矩阵；
`WApp` 本身就是 GetX 壳，非 GetX 壳不消费它，等真有需求再抽（那时再把 notifier 移进 app 是纯重构）。

验收 / 风险：

- widget 测试：`setThemeMode(ThemeMode.dark)` → `pump` → `Theme.of(context).brightness` 变；`app.themeMode.value` 同步；
- 切换后 `app.routeStack.routes` 不变、GetX 弹窗不丢（用 `WBottomSheet` 用例锁住）；
- `dispose()` 之后 `setThemeMode` 应抛 `StateError`（不要静默写已 dispose 的 notifier）。

### B2 语言跟随系统（✅ 已落地：app 4.2.0 / app_getx 3.3.0）

> 落地偏差：① 采用 `changeLanguage(..., userSelected: false)`（不是新增 `applySystemLocale`），
> 省下 1 个成员给 `dispose`；② 实现时发现 **GetX 自带** `GetMaterialController.didChangeLocales`
> 会把 `Get.locale` 直接设成 `deviceLocale` 并整树 reassemble，所以 `WApp` 在首帧后把它
> `removeObserver` 掉（ADR-0019 决策 3）；③ 系统语言不命中时显式走 `fallbackLanguage`，
> 不依赖 `basicLocaleListResolution` 的「退回第一个」。测试见
> `packages/app_getx/test/system_locale_test.dart`（含用户选择优先、fallback）。

现状：`WLanguage.fromConfig(config)` 只要 `config != null` 就把 `explicitSelection` 置 true
（`packages/app/lib/src/language/language.dart`），`WApp.buildRoot` 因此恒用 `currentLocale`；
不传 `localeConfig` 时支持列表只有 `en_US`。全仓没有 `didChangeLocales`。
结果：「跟随系统 + 用户可覆盖」这个标准场景没有入口。

推荐 API（2 个成员 + 1 个 additive 参数；加上 B3 的 `dispose` 正好 3 个）：

| 成员 | 位置 | 语义 |
|---|---|---|
| `followSystem` | `WLocaleConfig` | 默认 false；为 true 时启动与系统语言变化都跟随系统；与 `initialLanguage` 互斥（构造期 `ArgumentError`） |
| `isFollowingSystem` | `WLanguage` | `config.followSystem && !已由用户选择`；UI 语言选择器用它可以显示「跟随系统」态 |
| `changeLanguage(code, {bool userSelected = true})` | `WLanguage` | 加可选参数（additive，不新增成员）：系统驱动时传 false，不把「用户已选」置位 |

语义表：

| 场景 | 行为 |
|---|---|
| `followSystem: true`，启动 | 解析系统语言 → 命中支持列表就用它；不命中用 `fallbackLanguage`，再退第一个 |
| 系统语言运行期变化 | `didChangeLocales` → 重新解析 → 更新 `currentLanguage` / `currentLocale`；`WLanguageScope` 依赖者重建 |
| 用户显式切语言 | `isFollowingSystem` 变 false；之后系统变化不再覆盖用户选择 |
| `followSystem: false`（默认） | 与 4.1.x 完全一致 |

实现要点：

- `WApp` 用**私有** `_SystemLocaleObserver extends WidgetsBindingObserver`（见 §0 的坑）：
  `init` / `run` 里 addObserver，`dispose` 移除；
- 解析用 `basicLocaleListResolution(WidgetsBinding.instance.platformDispatcher.locales, supportedLocales)`
  （flutter/widgets 导出），再映射回 `lang` / `lang_COUNTRY` / `lang_Script_COUNTRY` 写进 `WLanguage`；
- **自己解析并显式传 `locale:`**：`effectiveLocale = (hasExplicitSelection || followSystem) ? currentLocale : null`。
  不要留 null 让 Flutter 和 GetX 各解析一次（GetX `Translations` 找不到 key 时还会走 `fallbackLocale`）；
- 语言监听里仍同步 `Get.locale`，但值用我们解析后的 `currentLocale`（单一真源仍是 `WLanguage`）；
- 持久化仍不管：恢复上次选择 = `start()` 之前 `changeLanguage(saved)`（此时 `userSelected` 默认 true，会覆盖跟随系统）。

验收 / 风险：

- widget 测试用 `tester.binding.platformDispatcher.localesTestValue = [Locale('zh','CN')]` + `onLocalesChanged()`，
  断言 `currentLanguage` / `currentLocale` / 页面文案 / `Get.locale` 四处一致；`followSystem: false` 时现有测试全绿；
- 需要 `localizationsDelegates` 覆盖目标语言（现有默认 `GlobalMaterialLocalizations.delegates` 已含常用语言）；
- `WLocaleConfig` 的 `==` / `hashCode` 要带上新字段（现有实现手写，漏了会导致 options 比较失效）；
- 这是 opt-in 语义变化，**不需要迁移文档**；但 `docs/modules/app_module.md`、`docs/agents/app.md` 要写「跟随系统」段。
- 建议用一份 ADR（0019）把「`hasExplicitSelection` 语义 + followSystem 解析规则」记下来：它不是新类型、
  ADR-0011 不强制，但和 0012 的作用域决策同属「应用级状态」的约定，后面再改有据可查。
- 被否的替代方案：新增 `WLanguage.applySystemLocale(Locale)`（更直白，但 app 的 3 个成员预算就没了，
  `dispose` 得单独再排一个 minor）；把 `followSystem` 只留在 app_getx（非 GetX 壳读不到配置，语义不完整）。

### B3 释放（✅ 已落地：两个包各 1 个成员）

| 类型 | 行为 |
|---|---|
| `WLanguage.dispose()` | close `languageChanges`、dispose `languageListenable`；幂等；dispose 后 `changeLanguage` 抛 `StateError` |
| `WApp.dispose()` | 移除语言监听 / 系统语言 observer、dispose `themeMode`；幂等；重置 `_languageListenerAttached`（允许 `buildRoot` 重新挂） |

不做 `WAppPlugin.onDispose`：插件没有 teardown 契约，要定超时 / 异常 / 顺序，收益低；真需要时再按 ADR 加。
`WApp.dispose` 里不要 `Get.reset()`（全局副作用会波及同进程其它测试）。

验收：连续 `buildRoot()` + `dispose()` 不累积 listener（dispose 后切语言不触发重建、无异常）；
测试 `tearDown` 统一 `app.dispose()`；`dispose` 后 `buildRoot()` 抛 `StateError`（避免复用已销毁实例）。

### P2-a 全栈启动配方（✅ 已落地：`docs/recipes/app-boot.md`）

- 新增 `docs/recipes/app-boot.md`，`docs/recipes/README.md` 加一行，`app-shell-theme.md` 顶部加「WApp 项目看 app-boot」。
- 骨架（API 已核对）：

  | 层 | 放什么 |
  |---|---|
  | 插件（顺序） | `StoragePlugin`（`await WStorage.init()`）→ `ApiPlugin`（`dependsOn: ['storage']`，设 `WApiSettings.baseOptions`、`DioRegistry.forBaseUrl`、`WTokenInterceptor(tokenGetter: WToken.getToken)`）→ `AsyncExecutorPlugin`（`registerService(() => ...)` 或 `Get.put(WAsyncExecutor(...))`） |
  | 插件（首帧） | `SplashPlugin.onFirstFrame` 移除原生闪屏；`E2eReadyPlugin.onFirstFrame` 调 `E2eSignals.ready()`（只在 `tool/main_e2e.dart` 依赖 e2e） |
  | `appWrapper`（MaterialApp 外） | `WAsyncTheme(...)`、`WToastTheme(style: WToastStyle.defaults, ...)`、`RepaintBoundary` |
  | `builder`（MaterialApp 内） | `BotToastInit()`、`WScreenScope(...)`、`Theme(...extensions: [WTextStyles...])`；`.sp` 只能在这里算 |
  | `navigatorObservers` | `BotToastNavigatorObserver()`（插件 `navigatorObservers` 或 `WAppOptions.navigatorObservers` 二选一，别重复加） |
  | 页面级 / 非 Dart | qr 相机生命周期、map API key、平台权限 |
  | start 之后 | `await E2eLogin.run(login: ..., afterLogin: ...)`（e2e recipe 已写） |

- 代码块里带 `dependencies:` 片段：`check_package_docs.py` 会校验 `^当前版本`，版本漂移会被文档门禁抓住。
- 防漂移（可选，成本低）：在根 `test/`（跨包回归）加一条正则契约测试，断言配方里出现的插件 `name` 唯一、
  每个 `dependsOn` 引用的名字都在文中定义 —— 子包测试不能读仓库根 `docs/`，所以放根 `test/`。
- 不做：把配方做成包内示例（需要给示例加 dio / bot_toast 等 hosted 依赖 + overrides，维护成本大于收益）。

### P2-b CLI 生成 `app_boot.dart`（按需，成本最高）

- 形态：`lib/app/app_boot.dart` 生成成 **starter**（`_FileKind.starter`：已存在就不覆盖，`--force-starters` 才刷新，
  `--check` 只报缺失）。**不要用 generated**：`--check-drift` 会把用户改过的启动代码判成漂移。
- 生成链：`templates/app_boot.dart.tpl` → `gen_templates.dart` → `templates.g.dart` → `templates_fresh_test`；
  内容按 features 拼（core→storage、api→api、toast→navigator observer、async→executor）。
- 编译守护是主要成本：`tool/check_templates_compile.dart` 现在只把 UI starters 放进 `packages/ui/example` 跑 `dart analyze`。
  要覆盖 app_boot，得给它一个同时有 app_getx + core/api/toast/async 的宿主；折中是 starter 只 import
  `w_tools_app_getx`、插件体留 TODO（能编译，但「能跑没内容」，价值打折）。
- 成本清单：模板 1 + `templates.g.dart` 生成 + `init_project.dart` 1 处 + `features.dart`（要不要新 flag）+
  `init_test` / `expected.dart` / drift 用例 + CLI minor + `agent_budget --record`。
- 建议：先做 P2-a；等「≥2 个消费方反馈不知道启动该写什么」再做。生成的代码是消费方自己拥有的，
  好处是免抄，坏处是每个项目一份要各自跟进 API 变化。

### D 可观测 / 测试尾巴

| 项 | 结论 |
|---|---|
| 覆盖率门禁 | CI 已对每个 Flutter 包跑 `flutter test --coverage`，只是**下限只卡 ui**。建议加两个 step：`app` 90、`app_getx` 85（widget 装配天然低），先只报不卡也行。成本：CI 时长 +约 1 分钟/包 |
| `firstFrame` 并行 | **不改**。顺序确定性 > 省几十 ms；`Future.wait` 会让「先移除闪屏再预热」变成竞态 |
| `onStartupReport` 回调 | 延后。`startupReport` 已经能读，回调只省轮询；app_getx 预算此刻已用满 |
| `packages/app/coverage/lcov.info` | 是本地产物（`.gitignore` 有 `coverage/`），不用清；别把它当覆盖率报告引用 |

## 已拍板的点（ADR-0019）

1. 主题状态放 `WApp`（`themeMode` + `setThemeMode`），不抽 `WThemeController`；
2. 「跟随系统」用 `changeLanguage(..., userSelected: false)`（additive 参数），不新增 `applySystemLocale`；
3. A3 暂不做（等反馈），设计保留在「未做项」里。

## 剩余项复核（2026-11-26 12:40，P1 / P2-a 落地后）

> 复核基线：`w_tools_app 4.2.0`（63 条公开面）/ `w_tools_app_getx 3.3.0`（74 条），P0 已并入
> 4.2.0。预算按已发布快照重算，两包下一个 minor 各仍有 3 个净增额度。
> 本节把「还剩什么、现在做不做、成本多少」重排一遍；设计细节仍看上文「未做项」。

### 复核后的顺序

| # | 项 | 现在做？ | 理由 | 落点 |
|---|---|---|---|---|
| 1 | 发布当前这波（P0 + P1 + P2-a） | **必须** | 新预算基线、新快照都要等发布；不发就会一直拿旧快照算预算 | app 4.2.0 / app_getx 3.3.0 / cli 2.9.14 |
| 2 | D-1：两包覆盖率下限 | ✅ 已落地 | 实测 app 94.8% / app_getx 94.8%，CI 各加一个 `--min-lines 90` step | `.github/workflows/ci.yml` |
| 3 | C3：示例接一个真子包 | ✅ 已落地 | 示例接了 `w_tools_async`：插件注册 `WAsyncExecutor`，页面 `Get.find` 调用，smoke test 断言 | `packages/app_getx/example` |
| 4 | P3：三处硬化 | ✅ 已落地（并入 3.3.0 / 2.9.14） | `buildRoot` 无 binding 的报错、`followSystem` 解析源、catalog pitfall | app_getx 3.3.0 / cli 2.9.14 |
| 5 | P2-b：CLI 生成 `app_boot.dart` | 路线 C ✅ 已落地；A/B 暂缓 | `init` 的「下一步」现在直接给配方入口（`docs/recipes/app-boot.md`）；生成代码仍要换编译宿主 | cli 2.9.14（并入） |
| 6 | A3：`dependsOn` 失败跳过 | 暂缓（等反馈） | 查过台账与 issues，没有需求；已加 catalog pitfall 引导「强依赖自己检查」 | app 4.3.0（2 成员） |
| 7 | 预设包 `w_tools_app_presets` | 暂缓（同前） | 没有消费方重复证据，且会再造一个聚合面 | 新包 0.1.0 |

### D：可观测 / 测试尾巴（带实测）

- **覆盖率（✅ 已落地）**：`flutter test --coverage` 实测 app **94.8%（199/210）**、
  app_getx **94.8%（343/362）**；CI 已加 `--package app --min-lines 90` 与
  `--package app_getx --min-lines 90` 两个 step（报告本来就在生成，时长不变）。
- **`onStartupReport` 回调**：`startupReport` 在 `await start()` 后就能读，唯一增量是「首帧耗时」
  要等一帧。消费方现在可以 `await start(); WidgetsBinding.instance.addPostFrameCallback((_) =>
  report(app.startupReport))`。加回调是 +1 个 app_getx 成员（预算 3 还有余量），但收益主要是
  埋点少两行 —— **暂缓**。
- **`firstFrame` 并行**：不做（顺序确定性 > 省几十 ms；`Future.wait` 会让「先移除闪屏再预热」竞态）。
- 跑覆盖率会生成 `packages/{app,app_getx}/coverage/lcov.info`，都是 gitignored 的本地产物。

### C3：示例接一个真子包（✅ 已落地）

> 落地形态：示例接 `w_tools_async`（不是 core —— core 的 `WStorage` 依赖
> `shared_preferences` 原生插件）；`AsyncExecutorPlugin` 在 `onInit` 里
> `Get.put(WAsyncExecutor(WAsyncHooks(...)))`，首页「执行异步任务」用
> `Get.find<WAsyncExecutor>().run(...)`，smoke test 断言注册 + 结果 + hooks。

- **选 `w_tools_async`，不选 core**：core 的 `WStorage` 基于 `shared_preferences`（原生插件），
  示例测试要 mock；async 只有 Flutter 依赖，`WAsyncExecutor` 正好是配方里「executor 插件」的
  真子包对照。
- 改动清单（约半天）：`example/pubspec.yaml` 加 hosted `w_tools_async: ^8.2.0`；
  `example/pubspec_overrides.yaml` 加 `../../async` path；`main.dart` 加
  `AsyncExecutorPlugin`（`Get.put(WAsyncExecutor(...))`）；某一页用 `Get.find<WAsyncExecutor>().run(...)`；
  smoke test 加断言；README 一句。
- 发布约束已核：`check_example_paths.py` 只允许 `example` 里的 path 落在**当前包目录内**，
  跨包必须在 `pubspec_overrides.yaml`（发布脚本排除）；app_getx 的自引用 `path: ../` 合法。
- 收益：插件契约 + 执行器注册在 CI 里有回归，配方里的 executor 段有可运行参照。

### P2-b：CLI 生成 `app_boot.dart`（路线 C ✅ 已落地）

> 落地形态：`init` 的 `_nextActions` 固定追加一条
> `启动顺序 / 多包装配看全栈启动配方：https://github.com/.../docs/recipes/app-boot.md`，
> `cli_test` 的 `--json` 用例断言 `nextActions` 里出现 `app-boot`。
> 完整生成（A/B 路线）仍暂缓，理由见下。

生成链要动的地方：`templates/app_boot.dart.tpl` → `tool/gen_templates.dart` 的 `_templates` 登记 →
`lib/src/init/templates.dart` 新 getter → `init_project.dart` 写入（`_FileKind.starter`）→
`init_test` / `--check` / drift 用例（`templates_fresh_test` 自动管新鲜度）。

分水岭是**编译守护**：`tool/check_templates_compile.dart` 现在的宿主是 `packages/ui/example`，
只装 ui 依赖；要编译含 core/api/toast/async import 的生成物，得换/加宿主（或给 app_getx example
补这些 hosted 依赖）。三条路线：

| 路线 | 内容 | 成本 | 评价 |
|---|---|---|---|
| A | 完整生成 + 新编译宿主 | 高（模板 + 宿主 + CI） | 价值最高；也最容易随包 API 漂移 |
| B | 生成只 import `w_tools_app_getx` 的骨架 + 注释里的真实写法 | 中 | 能编译（app_getx example 即可），但内容打折 |
| C | 不生成；`init` 输出一行「启动见 docs/recipes/app-boot.md」 | 低 | 配方已覆盖，零漂移 |

推荐 **C 现在做（一行提示）**，收到「≥2 个消费方不知道启动该写什么」再评估 A/B。

### A3：`dependsOn` 失败跳过（设计就绪，差需求；catalog 已加提示）

> 需求核查（2026-11-26）：`docs/feedback/` 与 GitHub issues 里没有「依赖失败后仍执行」
> 的反馈（只有已闭环的 timeout / critical）。已在 catalog 的 `WAppPlugin` pitfalls 加
> 「依赖失败后依赖者仍会执行（dependsOn 只表顺序）；强依赖请在 onInit 里自己检查前置」，
> 先让消费方和 agent 能绕开。

- 预算复核：app 4.2.0 是 63 条 → 下个 minor 允许 3 个净增；A3 的
  `WAppPlugin.requiresDependencies` + `WAppPluginRun.skipped` = 2，放得进 4.3.0。
- 关键规则（同「未做项」）：skip 是第三态、不进 `_completed`（下轮可重试）、
  `WApp._hasPluginFailures` 要把 skip 算进去、`WAppStartupReport.failures` 过滤 skipped、
  `firstFrame` 不给 skipped 发回调。
- 真正的成本不是代码，是**语义扩散**：报告、日志、未来的启动 UI 都要解释「第三种状态」。
- 建议：把「强依赖自己在 `onInit` 里检查」写进 app-boot 配方（已写）+ catalog 加一条 pitfall；
  等真实反馈再实现。

### P3：本轮落地时发现的硬化项（✅ 已落地）

1. **`buildRoot()` 无 binding 的报错**：改成 `StateError('buildRoot() 需要已初始化的
   WidgetsBinding：widget 测试请先调用 TestWidgetsFlutterBinding.ensureInitialized()…')`，
   `buildRoot` dartdoc 补一句；`build_root_binding_test.dart` 锁文案（纯 `test()` 里跑）。
2. **`followSystem` 解析源**：解析改用 `WLocaleConfig.supportedLanguages`
   （`WAppOptions.supportedLocales` 只覆盖 Flutter 列表），并给 Locale → 语言码加语言码兜底；
   `supportedLocales` 校验失败时提示「形态一致」；`system_locale_test.dart` 覆盖
   形态一致 / 不一致两种配置。
3. **catalog pitfall**：`WApp` 增加「首帧后移除 GetX 系统语言观察者」一条（已 `gen_catalog`）。
4. （未做，保留）**持久化配方**：语言 / 主题持久化写进 app-boot 配方，不加 API。

### 各项的版本与门禁

| 项 | 包 | 版本 | 公开面 | 门禁 |
|---|---|---|---|---|
| D-1 覆盖率下限 | — | — | 无 | CI（`check_coverage`） |
| C3 示例接 async | example（不发布） | — | 无 | `example` test + `check_example_paths` |
| P3-1/2 硬化 | app_getx | 3.3.0（并入未发布版本） | 无 | preflight + 定向变异（报错文案 / 解析用例） |
| P3-3 catalog pitfall | cli | 2.9.14（并入未发布版本） | 产物 | `gen_catalog --check` + `check_public_catalog` |
| P2-b 生成 | cli | minor | 命令产物 | `gen_templates` + `init_test` + 模板编译 |
| A3 跳过 | app | 4.3.0（minor） | +2 成员 | `check_api_budget` + 三态用例 + 变异 |

## 不做什么

- 不做 `WAppOptions.startupErrorBuilder` / 库内兜底错误页（ADR-0017 已论证：主题 / 本地化 /
  重试语义属于应用壳）；
- 不做全局 `WApp.instance` / `WLanguage.instance` 单例（ADR-0012）；
- 不恢复 `WAppTheme.copyWith`（4.0.0 有意删除，`buildRoot` 让测试复用运行时 options）；
- 不新增 `w_tools_test` 包（ADR-0017 已否决：会再造一份会漂移的装配）；
- 不为了省成员数给 `WAppOptions` 加 dummy 字段（ADR-0011 的预算语义）。

## 验证清单（实施时逐条跑）

```bash
bash scripts/preflight.sh --package app          # 单包
bash scripts/preflight.sh --package app_getx
python3 scripts/check_public_catalog.py          # 有公开变化时
python3 scripts/check_api_budget.py              # 预算 / 例外
bash scripts/check_docs.sh                       # 改 docs 后
bash scripts/mutate_guard.sh ...                 # A1 / A2 的定向变异
```

A1 / A2 的用例要满足「删掉被守逻辑它就红」：并发 `init()` 断言执行次数为 1、
非关键失败插件断言第二次 `init()` 执行次数为 2 —— 这两条在修复前必须是红的（本文已用
临时探针验证过事实，探针未入库）。
