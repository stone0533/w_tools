# ADR 0005：`WApp` 单配置面与插件归属

- 状态：已采纳（2026-11-03）
- 相关：[ADR-0002](0002-consumers-depend-on-subpackages.md)、[ADR-0003](0003-subpackage-typography-without-ui.md)、
  [`docs/analysis/2026-11-03-remediation-plan.md`](../analysis/2026-11-03-remediation-plan.md)（5.2/5.3）、
  [`docs/agents/app.md`](../agents/app.md)

## 背景

`WApp` 现在有 **11 个可变公共字段**（`title` / `initialRoute` / `getPages` / `theme` / `locale` /
`fallbackLocale` / `builder` / `navigatorObservers` / `defaultTransition` / `systemUiOverlayStyle` /
`orientations` / `appWrapper`），同时 `start()` 又接受一套同名参数；两者覆盖关系靠 `??` 逐字段处理。

路线图 5.3 还想把 `WToastPlugin` / `WScreenPlugin` / `WAsyncDefaultsPlugin` / `WFormIconsPlugin`
做成 app 的"一等公民插件"。但 `w_tools_app` 目前**只依赖 `get`**；把插件放进 app 意味着 app 反向依赖
ui / toast / async / form —— 会把 `cached_network_image`（50 个传递包、10 个原生插件）拖进所有用户，
与 ADR-0002 / ADR-0003 的分层直接冲突。

## 决策

1. **新增不可变 `WAppOptions`，两段式迁移**
   - 字段：`title` / `initialRoute` / `getPages` / `theme` / `translations` / `locale` / `fallbackLocale` /
     `builder` / `navigatorObservers` / `defaultTransition` / `systemUiOverlayStyle` / `orientations` /
     `appWrapper` / `plugins`；
   - `WApp(options)` / `WApp.start(options)` 为新入口；`run()` 的同名参数保留一版并弃用；
   - 合并规则只有一条：**options 显式值 > 已弃用字段 > 默认值**，不再逐字段 `??`。

2. **语言配置只解决"支持列表"，不新增第二个真源**
   - `WLocaleConfig`（不可变）：`supportedLanguages` + `defaultLanguage` / `fallback`；
   - 运行期"当前语言"仍然唯一真源是 `WLanguage.currentLanguage`（底层 `WAppConfig.currentLanguage`）；
   - 禁止出现可写的第二份 current。

3. **插件归属：谁配置谁提供；app 不反向依赖**
   - `w_tools_app` 的依赖保持只有 `get`；
   - 插件分两类：
     - **生命周期插件**（初始化顺序 / 原生能力）：由业务方或能力包提供，只要能力包已经依赖 app；
     - **主题 / 默认视图组合**：用 `WApp.appWrapper` 组合，不需要插件：
       ```dart
       WApp.options(
         WAppOptions(
           title: 'Demo',
           appWrapper: (child) => WAsyncTheme(
             child: WToastTheme(style: WToastStyle.defaults, child: child),
           ),
         ),
       ).start();
       ```
   - 路线图 5.3 的 4 个"一等公民插件"**撤回**：改成文档 snippet +
     `docs/recipes/app-shell-theme.md`；不在 app 里引入 ui/form/toast/async。

4. **`WRoute` 去静态（两段式）**
   - 新增实例 `WRouteStack`，由 `WApp` 持有并通过 `WApp.routeStack` 暴露；
   - `WRouteObserver` 接受可选实例，默认回退到旧静态；
   - 静态 `WRoute` 标记弃用一个 major，下个版本删除。

5. **`WBottomSheet` 保持工具类**，不引入插件；它的参数已经透传 `Get.bottomSheet`。

## 影响

- 调用方从"改字段"变成"传 options"，`const` / `==` 可比较，测试可注入；
- 插件不再成为 app 的依赖负担，消费方按需组合；
- 代价：迁移期同时存在 options 与旧字段，需要 `WAppOptions` 的 `copyWith` 与冲突规则测试；
- ADR-0004 的命名规则适用于本 ADR：`Options` 表行为，`Config` 不再新增。

## 不做什么

- 不为了"插件齐全"让 `w_tools_app` 依赖 ui / form / toast / async；
- 不做全局可写的 `currentLanguage` 第二真源；
- 不在本次发布前改 `WApp` 的公共构造（属于下一个 minor 的破坏性迁移）。
