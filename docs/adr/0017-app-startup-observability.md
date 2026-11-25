> 决策记录：记录当时的决策背景；当前实现以文档和代码为准。

# ADR 0017：应用启动可观测性、插件首帧钩子与测试宿主

- 状态：已采纳（2026-11-25）
- 相关：[`0011-api-surface-budget.md`](0011-api-surface-budget.md)、
  [`app_plugin.dart`](../../packages/app/lib/src/plugins/app_plugin.dart)、
  [`app.dart`](../../packages/app_getx/lib/src/app.dart)、
  [`e2e_config.dart`](../../packages/e2e/lib/src/e2e_config.dart)、
  [`docs/modules/app_module.md`](../modules/app_module.md)、
  [`docs/feedback/app_getx.md`](../feedback/app_getx.md)、
  [`docs/feedback/app.md`](../feedback/app.md)、
  [`docs/feedback/e2e.md`](../feedback/e2e.md)

## 背景

消费方反馈集中暴露了同一条链路上的缺口：

1. `WAppPlugin` 的文档写了「首帧后 `onLazyInit()`」，但插件契约里没有这个钩子；
   移除原生闪屏只能塞进某个页面的 `initState`，深链 / 恢复登录时闪屏不消失。
2. 启动期没有逐插件耗时 / 失败 / 首帧日志，也没有结构化报告；插件失败只表现为
   `start()` 抛错，排查启动慢 / 卡死只能加临时 `print`。
3. 插件没有超时与关键性标记：某个插件挂住会无限期卡启动；失败时 `runApp` 不执行，
   真机白屏。
4. 消费方 49 个 widget 测试各自手搭 `ScreenUtilInit` + `MaterialApp`，与运行时
   `WApp` 装配漂移（`designSize` 都不一致）。
5. `w_tools_e2e` 条件不满足时静默返回；`[E2E] auto login ok` 不代表首屏就绪，
   设备黑盒只能 sleep；没有登录前清会话钩子。
6. `WAppTheme.systemUiOverlayStyle` 只在启动时设置一次，浅色状态栏页面 pop 后
   不回落，无标注页面没有全局兜底。

前 3 条与 4 / 5 都需要新增公开 API；`systemUiOverlayStyle` 是行为修复，不新增类型。
`WListViewSliver.overlap` 的最后一项点击死区是同批反馈里的纯行为修复，不涉及 API。

## 决策

1. **插件级首帧钩子**：`WAppPlugin.onFirstFrame()`；`WAppPluginRunner.firstFrame()`
   负责首帧后逐个调用（幂等、失败隔离）。App 级 `onLazyInit` 保留，生命周期文档
   分 App 级 / 插件级两段。
2. **插件超时与关键性**：`WAppPlugin.timeout`（默认 null，opt-in）与
   `WAppPlugin.critical`（默认 true）；关键插件失败 / 超时抛
   `WAppPluginInitException(pluginName, cause, stackTrace, timedOut)`；非关键插件
   记录后继续启动，依赖它的插件仍执行。
3. **启动可观测**：`WAppPluginRun`（逐插件耗时 / 失败）+ `WAppPluginRunner.runs` /
   `totalDuration`；`WAppStartupReport`（插件、customTasks、init、首帧）+
   `WApp.startupReport`；`WAppOptions.startupLog`（null 跟随 debug）输出固定格式日志。
4. **测试宿主**：`WApp.buildRoot()` 用与 `run()` 相同的装配构建根（不 `runApp`、
   不要求 `init`）；测试用运行时 `WAppOptions.copyWith(home: ...)` 复用
   `appWrapper` / `builder` / theme / scope，不再新造平行装配。
5. **e2e 可诊断 / 可等待**：`E2eSkipReason` + `E2eConfig.skipReason`；条件不满足时
   打 `[E2E] skip: <reason>`；`E2eLogin.run(beforeLogin: ...)`；`E2eSignals` 提供
   稳定的 `[E2E] ready` 标记。**不**新增等待 API（日志管道由设备工具负责）。
6. **系统栏兜底**：`WAppTheme.systemUiOverlayStyle` 从一次性设置改为根部
   `AnnotatedRegion` 全局兜底；页面 `WScaffold` / `WAppBar` 标注优先。不新增开关，
   默认行为对没有标注页面的项目保持不变。
7. **公开面预算**：`app` growth 21、`app_getx` growth 13、`e2e` growth 11（均为本次
   实际净增成员数）；新增类型 `WAppPluginRun` / `WAppPluginInitException` /
   `WAppStartupReport` / `E2eSignals` / `E2eSkipReason` 在
   [`scripts/api_budget.yaml`](../../scripts/api_budget.yaml) 登记例外，`until`
   分别指向下一 minor；类型进入发布快照后删除例外。
8. **不做**：
   - `WAppOptions.startupErrorBuilder`：兜底页需要 MaterialApp / 主题 / 本地化 /
     重试生命周期，库不托管应用壳 UI；提供 typed exception + 可重试 `start()` +
     README 配方。
   - 新 `w_tools_test` 包或 CLI `test/support` starter：会再造一份运行时会漂移的装配；
     `buildRoot()` 复用同一份配置。
   - 恢复 `WAppTheme.copyWith`（4.0.0 有意删除）：`buildRoot()` 让测试复用运行时
     options，不需要改主题。

## 后果

正向：

- 插件能自己完成「首帧后收尾」，闪屏不再依赖页面被打开；
- 启动慢 / 卡住 / 失败可以定位到插件名与耗时；
- 非关键插件不再让 App 起不来；失败页有明确的异常类型与重试路径；
- 测试宿主与运行时共享装配，49 处样板可逐步收敛；
- e2e 黑盒有稳定等待点，残留会话可在登录前清掉；
- 系统栏样式从浅色页面返回后能恢复。

代价 / 已知局限：

- 公开面增加 5 个类型与约 45 个成员，需要 ADR + 预算例外（ADR 0011 的显式成本）；
- `WAppPlugin.onInit` 失败的错误类型从「原异常」变为
  `WAppPluginInitException`（`cause` 保留原异常），属于行为变化；
- `startupReport` 的首帧耗时在首帧回调后才填入，对象不是完全不可变；
- `buildRoot()` 不执行插件初始化，测试需要自行 `await app.init()`（如果用例依赖插件）；
- e2e 只提供 `[E2E] ready` 标记，不自带日志等待工具。

## 落地结果

- 状态：已完成（2026-11-25）
- 发布：`w_tools_app 4.1.0` / `w_tools_app_getx 3.2.0` / `w_tools_e2e 0.3.0` /
  `w_tools_ui 14.1.1` / `w_tools_cli 2.9.8` / 根包 `w_tools 21.1.4`
- 证据：PR #410 / #412；快照 PR #411 / #413；`release_status --online --check`
  状态正常；新类型进入快照后已从 `scripts/api_budget.yaml` 移除例外、growth 回默认。

## 备选方案

1. **只改文档、不加插件首帧钩子**：拒绝。文档与实现一致了，但「闪屏依赖页面」
   的真实问题仍在，每个消费方继续绕。
2. **把启动报告做成 `Map<String, Object>`**：拒绝。无字段约束、无 IDE 提示，
   测试与埋点容易拼错 key。
3. **默认 10s 超时**：拒绝。会把「慢但合法」的首次迁移 / 预加载直接判成启动失败；
   改为 opt-in + 文档建议值。
4. **库内提供兜底错误页**：拒绝。库不拥有应用壳的主题 / 本地化 / 重试语义；
   类型化异常 + 配方更小且可组合。
5. **新增 `w_tools_test` 包**：拒绝。会复制 `WApp` 装配，正是反馈里「漂移」的根因。
