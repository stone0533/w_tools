> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0019：应用级运行期状态（主题切换 / 语言跟随系统 / 释放）

- 状态：已采纳（2026-11-26）
- 相关：[ADR-0005](0005-app-options-and-plugin-ownership.md)、
  [ADR-0011](0011-api-surface-budget.md)、[ADR-0012](0012-app-tree-scopes.md)、
  [ADR-0017](0017-app-startup-observability.md)、
  [`docs/analysis/2026-11-26-app-improvement-plan.md`](../analysis/2026-11-26-app-improvement-plan.md)、
  [`docs/modules/app_module.md`](../modules/app_module.md)

## 背景

4.1.x 之后 `WApp` 的生命周期与启动可观测性已经够用，但应用级状态还有三处不对称：

1. **语言是活状态，外观是死值**：`WLanguage` 有 `ValueNotifier` + `WLanguageScope`，
   而 `WAppTheme.mode` 只在 `buildRoot()` 读一次；`WAppOptions` / `WApp.options` 都是
   `final`、`start()` 只能调一次 —— 深色模式开关没有公开入口。
2. **语言无法表达「跟随系统」**：`WLanguage.fromConfig(config)` 只要 `config != null`
   就把 `explicitSelection` 置 true，`WApp.buildRoot` 因此恒用 `currentLocale`；
   不传 `localeConfig` 时支持列表只有 `en_US`。结果「用户没选过 → 跟随系统；
   选过 → 用选择」这个标准场景没有 API 能表达，全仓也没有 `didChangeLocales` 处理。
3. **没有释放路径**：`WLanguage` 的变化流 / 值监听、`WApp` 的语言监听都不释放；
   widget 测试反复 `buildRoot()` 会累积监听，测试 teardown 没有干净的拆卸方式。

## 决策

1. **主题运行时状态放 `WApp`（app_getx），不抽新类型**
   - 新增 `ValueListenable<ThemeMode> get themeMode`（初值 `options.theme?.mode ??
     ThemeMode.system`）与 `void setThemeMode(ThemeMode)`；
   - `buildRoot()` 在 `appWrapper` 与 `GetMaterialApp` 之间插 `ValueListenableBuilder`，
     只重建到 `GetMaterialApp`（`themeMode` 是 MaterialApp 入参），不重置 Navigator、
     不重建 `appWrapper` / scope；
   - 不做 `WThemeController` + `WThemeScope`：新类型要 ADR + `api_budget` 例外 + 文档矩阵，
     而 `WApp` 本身就是 GetX 壳，非 GetX 壳不消费它。等出现非 GetX 启动器需求再抽，
     那时把 notifier 移进 `w_tools_app` 是纯重构。
2. **「跟随系统」用配置 + 一个 additive 参数表达**
   - `WLocaleConfig.followSystem`（默认 false）：为 true 时启动与系统语言变化都由系统解析；
     与 `initialLanguage` **互斥**（同时给出在构造期抛 `ArgumentError`），避免「跟随 + 固定初值」二义；
   - `WLanguage.isFollowingSystem`：`followSystem && !用户已显式选择`；
   - `WLanguage.changeLanguage(code, {bool userSelected = true})`：加可选参数（additive，
     不新增成员）。`userSelected: false` 表示「系统解析结果」，不把 `hasExplicitSelection` 置位；
   - 解析规则：`basicLocaleListResolution(平台 locales, supportedLocales)`；系统语言不命中支持列表时
     用 `fallbackLanguage`，再退第一个；结果映射回语言码写入 `WLanguage`（单一真源）；
   - `WApp` 自己解析并**显式传 `locale:`**（`hasExplicitSelection || isFollowingSystem` 时非 null），
     不让 Flutter 与 GetX 各解析一次；
   - 用**私有** `_SystemLocaleObserver extends WidgetsBindingObserver` 接 `didChangeLocales`，
     不让 `WApp` 自己实现 observer：`check_public_api_diff` 只合并包内父类型，包外继承成员
     预算拦不住，但生命周期方法会真的变成 `WApp` 的公开面。
3. **首帧后移除 GetX 自带的系统语言观察者**
   - `GetMaterialController.didChangeLocales` 会把 `Get.locale` 直接改成 `Get.deviceLocale`
     （只看首选 locale，不按 `supportedLocales` 解析），并整树 reassemble；这会绕过
     `WLanguage` 的唯一真源，也会覆盖用户的显式选择；
   - `WApp` 在首帧后 `removeObserver(Get.rootController)`；`Get.locale` 仍由
     `_onLanguageChanged` 维护（`GetMaterialApp` 构建时用 `Get.locale ?? locale`），
     语言切换仍是局部重建，不做整树 reassemble。
4. **释放路径**
   - `WLanguage.dispose()`：close 变化流、dispose 值监听，幂等；之后 `changeLanguage` 抛 `StateError`；
   - `WApp.dispose()`：移除语言监听 / 系统语言 observer、dispose `themeMode`、`language.dispose()`；
     幂等；之后 `init` / `run` / `buildRoot` / `setThemeMode` 抛 `StateError`；
   - 不引入 `WAppPlugin.onDispose`：插件没有 teardown 契约，要定义超时 / 异常 / 顺序，收益低；
     真需要时另开 ADR。
5. **公开面预算**
   - `w_tools_app 4.2.0`：`WLocaleConfig.followSystem`、`WLanguage.isFollowingSystem`、
     `WLanguage.dispose` = 3 个净增成员（`changeLanguage` 的新参数是 additive）；
   - `w_tools_app_getx 3.3.0`：`WApp.themeMode`、`WApp.setThemeMode`、`WApp.dispose` = 3 个；
   - 两个包都正好用满默认 growth（`max(3, ceil(快照条目数 × 3%))` = 3），**不登记例外**。

## 后果

正向：

- 深色模式开关成为一行调用，且不重置路由 / 不重建包装层；
- 「跟随系统 + 用户可覆盖」有了完整语义，系统语言变化能同步到 `WLanguage` / `WLanguageScope`；
- 显式选择语言后，系统语言变化不再被 GetX 强行覆盖（这是移除 GetX observer 的直接收益）；
- 测试 teardown 有 `app.dispose()`，不再累积监听。

代价 / 已知局限：

- `WApp.dispose()` 会连 `language` 一起释放；dispose 后再读 `currentLanguage` 或切语言都会失败，
  必须重新创建应用实例；
- 跟随系统依赖 `WApp` 的 observer；非 GetX 壳要自己接 `didChangeLocales` 并调用
  `changeLanguage(code, userSelected: false)`，`WLocaleConfig.followSystem` 对它们只是配置声明；
- 移除 `Get.rootController` 的 observer 是对 GetX 的定向覆盖：WApp 是应用根的 owner，可以接受，
  但 GetX 升级若改变 root controller 的 locale 行为需要复核；
- 主题 / 语言都不持久化（与 4.x 一致），持久化仍归消费方。

## 落地结果

- `w_tools_app 4.2.0` / `w_tools_app_getx 3.3.0` / `w_tools_cli 2.9.14`；
- 证据：`packages/app/lib/src/language/`、`packages/app_getx/lib/src/app.dart`、
  `packages/app_getx/test/theme_mode_test.dart`、`packages/app_getx/test/system_locale_test.dart`、
  `docs/modules/app_module.md`、`docs/agents/app.md`。

## 备选方案

1. **抽 `WThemeController` + `WThemeScope`**：拒绝。对称性收益在有非 GetX 启动器之前用不上，
   成本是新类型 + ADR + 预算例外 + 文档矩阵；等需求出现再抽是纯重构。
2. **新增 `WLanguage.applySystemLocale(Locale)` 而不是加参数**：拒绝。多 1 个成员后
   `dispose` 就没预算了，要么抬 growth 写理由，要么拆两个 minor；语义上 `changeLanguage`
   加 `userSelected` 更贴近「同一切换入口」。
3. **保留 GetX 的 locale 观察者、事后再纠正**：拒绝。需要依赖 observer / Timer 的执行顺序，
   还会多一次整树 reassemble，且中间帧会闪错语言。
4. **`WAppPlugin.onDispose`**：拒绝。插件 teardown 需要定义超时 / 异常 / 顺序 / 与 runner 的关系，
   当前没有消费方需求。
5. **把 followSystem 只放 app_getx**：拒绝。`WLocaleConfig` 是语言配置的事实源，放壳里会让
   非 GetX 壳读不到配置，语义不完整。

## 重新评估的条件

- 出现非 GetX 启动器（`WAppPluginRunner` 直接使用）也需要运行时主题状态 → 把 notifier 移进 `w_tools_app`；
- GetX 移除 / 改变 `GetMaterialController.didChangeLocales`，或提供可配置的 locale 策略；
- 同一进程需要并存多个 `WApp` 且测试要反复创建 / 销毁 → 需要更完整的实例级 teardown；
- 语言持久化成为多个消费方的重复实现 → 再评估是否在 app 层提供存储钩子（当前不做）。
