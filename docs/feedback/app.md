# w_tools_app 反馈

## 待处理

（暂无）

## 已确认

### [已确认] app: WAppPlugin 没有「首帧后」钩子：文档写了 onLazyInit，实际只有 App 级单回调

- 包/版本：w_tools_app 4.0.1（本地检出 `packages/app`；`WApp` 编排在 w_tools_app_getx 3.1.0）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；项目 ureward_member_app（`lib/app/w/w_plugins.dart` 六个插件）
- 命令 / 输入：项目现状（`lib/app/w/w_plugins.dart`）
  ```dart
  class SplashPlugin extends WAppPlugin {
    @override String get name => 'native-splash';
    @override
    Future<void> onInit() async {
      FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
    }
  }
  // 首帧后想做的事没有插件级位置，只能塞进「第一个被打开的页面」：
  // lib/app/modules/nav/controllers/nav_controller.dart:35
  FlutterNativeSplash.remove();
  ```
- 期望：`WAppPlugin` 提供「首帧后」钩子（每个插件各自一次），插件可以自己收尾/预热，例如：
  ```dart
  abstract mixin class WAppPlugin {
    Future<void> onLazyInit() async {}   // runApp 之后、首帧后调用
  }
  ```
- 实际：`WAppPlugin` 只有 `name` / `dependsOn` / `onInit` / `navigatorObservers`（`packages/app/lib/src/plugins/app_plugin.dart:22-75`）；`onLazyInit` 其实是 `WApp.init()/start()` 的**参数**（单个 App 级回调，`packages/app_getx/lib/src/app.dart:85`，在 `:116` 的 `addPostFrameCallback` 里调用），插件拿不到。
  而 `WAppPlugin` 的文档（同文件 `:5-13`）又把 `customTasks（并行）` 和「首帧后 onLazyInit()」写进了**插件生命周期**里，读起来像插件钩子 —— 文档与 API 语义不一致。
- 影响（我因此做错了什么 / 多花了什么）：本项目的「移除原生闪屏」只能依赖 `NavController.initState`（`lib/app/modules/nav/controllers/nav_controller.dart:35`）。只要启动后落到的不是 nav（深链、登录态恢复直接进内页、以后换初始路由），闪屏就永远不消失，而且没有编译期提示。首帧后的预热/埋点/预取也没有正规位置，容易散落在控制器里。
- 建议：
  1. `WAppPlugin` 增加 `Future<void> onLazyInit() async {}`，由 `WApp` 在首帧回调里**逐个插件**调用；单个插件失败只上报/记日志，不中断其它插件；
  2. 生命周期文档把「App 级（`customTasks` / `onLazyInit` 参数）」和「插件级（`onInit` / `onLazyInit`）」分开写，避免再被当成插件钩子；
  3. 补测试：插件注册后 `onLazyInit` 在首帧后被调用、抛错不影响其它插件、`WApp.start()` 仍成功。
- 复现数据：
  - `packages/app/lib/src/plugins/app_plugin.dart:5-13`（生命周期注释里出现 `customTasks` / `onLazyInit`）、`:22-75`（实际成员只有 name/dependsOn/onInit/navigatorObservers）；
  - `packages/app_getx/lib/src/app.dart:85`（`init({onLazyInit, customTasks})`）、`:102-117`（`_doInit` 里 `addPostFrameCallback((_) => onLazyInit?.call())`）；
  - 本项目：`lib/app/w/w_plugins.dart:126-135`（SplashPlugin 只 preserve）、`lib/app/modules/nav/controllers/nav_controller.dart:35`（remove 在 nav 控制器里）。
- 关联 issue：#406
- 状态变更：2026-11-25 已确认 → #406

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
