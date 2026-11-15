> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0012：语言作用域与 4.0 删除计划

- 状态：已采纳（2026-11-15）
- 相关：[ADR-0005](0005-app-options-and-plugin-ownership.md)、[`docs/agents/app.md`](../agents/app.md)

## 背景

`WApp` 把语言与路由栈改为实例状态后，页面只能通过调用方保存的 `WApp` 变量访问语言。
3.1 的审计建议补一个树内入口，避免把全局单例又交回使用方。

同时，3.1 之后新增的内核 API 已经稳定，下一轮需要删除一批重复入口
（插件渲染钩子 / runner 增删 / 语言回调 / copyWith）。直接在一个 major 里删除会与
依赖方 `w_tools_app_getx` 的发布顺序冲突：`app_getx` 的新版本需要新的 `app`，而
`app` 的 PR 又要求依赖已发布。因此按「先弃用、再删除」两段式推进。

## 决策

1. **3.2.0 新增 `WLanguageScope`**：`InheritedNotifier<ValueListenable<String>>`，
   `WLanguageScope.of(context)` 读取最近的语言实例；语言切换时依赖者重建。
   `WLanguage` 仍留在 `w_tools_app`，scope 只是页面侧的读取入口。
2. **3.2.0 标记弃用，4.0.0 删除**：
   - `WAppPlugin.builderWrapper` → `WAppOptions.builder`
   - `WAppPlugin.wrapApp` → `WAppOptions.appWrapper`
   - `WAppPluginRunner.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins`
     → 构造时传完整列表
   - `WLanguage` 5 参构造 / `listenLanguageChange` / `bindLocaleUpdater`
     → `WLanguage.fromConfig` / `languageChanges` / `languageListenable`
   - `WLocaleConfig.copyWith` / `WAppTheme.copyWith` → 直接构造
   - 每个弃用入口带 `remove-in: 4.0.0`。
3. **3.2.0 不改变默认行为**：系统栏、插件并行 / 串行、语言码解析等保持 3.1.1 行为；
   行为变化留到 4.0.0，与删除同批发布。
4. **3.2.0 只修一个 bug**：runner 失败重试跳过已成功的插件，避免重复执行副作用。
5. **顺序**：发布 `app 3.2.0` → 发布 `app_getx 3.0.0`（依赖 `>=3.2.0 <5.0.0`）→
   发布 `app 4.0.0`（删除 + 行为变化）。`app_getx` 3.0.0 不依赖任何被删除的 API，
   因此可以先于 4.0.0 发布。

## 后果

- `app_getx 2.1.1` 仍可解析 `app 3.2.0`，不需要兼容桥；3.0.0 再迁移到新入口。
- 3.2.0 的 API 增加只有 `WLanguageScope`，按 [ADR-0011](0011-api-surface-budget.md) 在
  `scripts/api_budget.yaml` 登记例外，进入已发布快照后删除。
- 4.0.0 删除时不需要再改 `app_getx` 的依赖下界（已经允许 `<5.0.0`）。
- 页面可在 `app_getx 3.0.0` 里自动插入 scope；3.2.0 阶段仍由调用方手动包。

## 不做什么

- 不在 3.2.0 里改变系统栏 / 插件执行顺序 / 语言码解析；
- 不为 `app_getx 2.1.1` 做兼容桥或临时放宽约束；
- 不在 3.2.0 引入 `WAppScope` / `WApp.of`；它们属于 `app_getx 3.0.0`。

## 重新评估的条件

- `app_getx 3.0.0` 先于 3.2.0 发布，或 3.2.0 需要引入行为变化；
- 出现第二个非 GetX 应用壳，`WLanguageScope` 的归属需要重新划分；
- Flutter 提供新的依赖注入机制。
