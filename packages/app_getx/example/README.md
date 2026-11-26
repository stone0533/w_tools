# w_tools_app 示例

真实场景示例，覆盖：

- `app.start()` 一站式启动
- `WAppPlugin` / `dependsOn` 插件分层
- GetX 路由
- `app.routeStack` / `WRouteObserver`
- 插件 `navigatorObservers` 路由事件
- `WApp.of(context)` / `WLanguageScope.of(context)`（页面不再保存全局 app）
- `WAppOptions.builder` / `appWrapper`
- `customTasks` / `onLazyInit`
- `app.routeStack.popUntilRoute`
- `app.language` 语言切换与 `WLocaleConfig`
- `WBottomSheet`
- 真实子包：`w_tools_async` 的 `WAsyncExecutor` 在插件里注册、页面里 `Get.find`

## 运行

```bash
cd packages/app_getx/example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 页面

```text
首页
  查看插件初始化顺序
  切换语言
  打开详情路由
  底部弹窗
  执行异步任务（WAsyncExecutor）
  查看路由栈

详情页
  返回
  移除当前路由后返回
```

## 启动流程

```text
main
  → createApp()
  → app.start()
  → init(): 系统设置 + 插件 onInit
  → run(): GetMaterialApp
```

插件：

```text
FeaturePlugin dependsOn ['env']
  → EnvPlugin 先完成
  → FeaturePlugin 再完成

AsyncExecutorPlugin dependsOn ['env']
  → Get.put(WAsyncExecutor(WAsyncHooks(...)))
  → 页面 Get.find<WAsyncExecutor>().run(...)
```

## 说明

示例使用 GetX；`w_tools_app_getx` 强依赖 GetX，`w_tools_app` 只提供插件契约。

`WRouteObserver` 由 `WApp` 自动追加，示例没有手工添加。
语言由 `app.language` 维护，示例通过 `WLocaleConfig.initialLanguage` 启动为中文。
