> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0012：应用树的语言 / 应用实例作用域

- 状态：已采纳（2026-11-15）
- 相关：[ADR-0005](0005-app-options-and-plugin-ownership.md)、[`docs/agents/app.md`](../agents/app.md)、
  [`docs/modules/app_module.md`](../modules/app_module.md)

## 背景

`WApp` 把语言与路由栈改为实例状态后，页面只能通过调用方保存的 `WApp` 变量访问
（示例是顶层 `late WApp app`）。这等于把原来的全局单例交给使用方保管：

- 页面无法在 widget 树里拿到 `app.language` / `app.routeStack`；
- 组件测试要给页面注入一个假实例时没有入口；
- 每个页面都依赖一个隐式全局，和“实例化语言 / 路由栈”的初衷相反。

## 决策

1. **`WLanguageScope`（`w_tools_app`）**：`InheritedNotifier<ValueListenable<String>>`，
   持有 `WLanguage`；`WLanguageScope.of(context)` 读取最近实例。
   语言切换时依赖者自动重建。
2. **`WAppScope`（`w_tools_app_getx`）**：普通 `InheritedWidget`，持有 `WApp`；
   `WApp.of(context)` / `WApp.maybeOf(context)` 读取最近实例。
3. **由 `WApp.run()` 自动注入**，顺序自外向内：

   ```text
   WAppScope
     → WLanguageScope
       → WAppOptions.appWrapper
         → GetMaterialApp
           → WAppOptions.builder
             → 页面
   ```

4. **嵌套取最近 scope**；`WAppScope` 只按实例 identity 通知，`WLanguageScope` 按语言变化通知。
5. **失败语义**：`of` 找不到 scope 时抛 `FlutterError` 并给出修复方式；`WApp.maybeOf` 返回 null。
6. 不在 `WApp` 上加“当前实例”静态单例；scope 是唯一的树内入口。

## 后果

- 页面不再需要保存全局 `app`；`WApp.of(context)` 可读路由栈，`WLanguageScope.of(context)`
  可读语言并在切换时重建；
- 测试可以手动包 `WAppScope` / `WLanguageScope`，不必启动完整应用；
- 新增两个公开类型，按 [ADR-0011](0011-api-surface-budget.md) 在
  `scripts/api_budget.yaml` 的 `exceptions` 登记到 `5.0.0`，进入已发布快照后删除；
- `WAppScope` 暴露整个 `WApp`，但只有读取实例一个职责；不把 `language` / `routeStack`
  再镜像成 scope 字段。

## 不做什么

- 不做全局 `WApp.instance` / `WLanguage.instance` 静态单例；
- 不让 `WLanguageScope` 回退到“默认语言”静默兜底（会掩盖漏包 scope）；
- 不把 `WLanguage` 改成 `ChangeNotifier` 再让 scope 依赖它：现有
  `languageListenable` 已经够用，避免扩大 `WLanguage` 的类型契约。

## 重新评估的条件

- 同一进程需要并存多个 `WApp` 且页面需要跨树读取（当前 `runApp` 只有一个根）；
- 语言之外的 app 状态（如插件生命周期）也需要页面级读取，`WApp.of` 的宽接口开始失控；
- Flutter 提供新的依赖注入机制，或 `WApp` 不再作为单根启动器。
