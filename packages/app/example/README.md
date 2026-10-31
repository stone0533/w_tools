# w_tools_app 示例

真实场景示例，覆盖：

- `WApp.start()` 一站式启动
- `WAppPlugin` / `dependsOn` 插件分层
- GetX 路由
- `WRoute` / `WRouteObserver`
- 插件 `navigatorObservers` 路由事件
- 插件 `builderWrapper` / `wrapApp`
- `WApp.builder` / `WApp.appWrapper`
- `WRoute.popUntilRoute`
- `WLanguage` 语言切换
- `WBottomSheet`

## 运行

```bash
cd packages/app/example
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
  查看路由栈

详情页
  返回
  移除当前路由后返回
```

## 启动流程

```text
main
  → createApp()
  → WApp.start()
  → init(): 系统设置 + 插件 onInit
  → run(): GetMaterialApp
```

插件：

```text
FeaturePlugin dependsOn ['env']
  → EnvPlugin 先完成
  → FeaturePlugin 再完成
```

## 说明

示例使用 GetX；这是 `w_tools_app` 的强依赖。

`WRouteObserver` 由 `WApp.run()` 自动追加，示例没有手工添加。
