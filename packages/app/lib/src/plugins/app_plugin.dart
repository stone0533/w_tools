import 'package:flutter/widgets.dart';

/// WApp 插件接口 — 用声明式方式把初始化能力挂到应用生命周期。
///
/// 生命周期由 `WApp` 编排，分两层：
///
/// **App 级**（`WApp.init()` / `start()` 的参数，不属于插件）：
/// ```
/// WidgetsFlutterBinding.ensureInitialized()
///   → 系统设置（状态栏、屏幕方向）
///   → 插件 onInit（按 [dependsOn] 分层；同层按注册顺序串行）
///   → customTasks（并行）
///   → runApp(...)
///   → 首帧后 onLazyInit()
/// ```
///
/// **插件级**：
/// - [onInit]：`runApp` 之前，按 [dependsOn] 分层串行；
/// - [onFirstFrame]：首帧绘制之后，每个插件各一次（失败隔离）。
///
/// 只用 `WAppPluginRunner`（非 GetX 应用壳）时，runner 执行 [dependsOn] /
/// [onInit] / [onFirstFrame]；[navigatorObservers] 由 `WApp` 消费，runner 忽略它。
///
/// 本类声明为 `mixin class`，因此既可 `extends` 也可 `with` ——
/// 插件若需继承其他基类，可写 `class MyPlugin extends Base with WAppPlugin`。
abstract mixin class WAppPlugin {
  /// 插件唯一标识，用于日志、调试与 [dependsOn] 引用
  String get name;

  /// 必须先于本插件完成 [onInit] 的插件名称列表
  ///
  /// 用于表达插件之间的初始化依赖，例如"业务服务"依赖"环境变量"：
  /// ```dart
  /// class AppServicePlugin extends WAppPlugin {
  ///   @override String get name => 'app-service';
  ///   @override List<String> get dependsOn => ['env'];
  ///   @override Future<void> onInit() => Application.init();
  /// }
  /// ```
  /// 同一层的插件按注册顺序**串行**执行，下一层等待上一层全部完成。
  /// 依赖可以跨注册顺序：声明了 [dependsOn] 的插件一定在依赖之后执行。
  /// 引用未注册的插件名或存在循环依赖时，`init` 会抛出 [StateError]。
  List<String> get dependsOn => const [];

  /// 应用初始化钩子（在 ensureInitialized 之后、runApp 之前执行）
  ///
  /// 适用于：dotenv 加载、日志配置、SharedPreferences 预加载等异步准备工作。
  ///
  /// 插件按层串行执行：某个 [onInit] 抛错或超时会中断本次 `init`，同层后续
  /// 插件不再执行；重试时已成功的插件不会重复执行。失败会被包装成
  /// `WAppPluginInitException`（带 [name]，见 [timeout] / [critical]）。
  ///
  /// 在 `GetX` 应用里注册服务时，用 `w_tools_app_getx` 的
  /// `registerService<T>(...)`，不要写 `Future<void> onInit() => Get.putAsync(...)`：
  /// 后者会把实例注册到 `void` 下，`Get.find<T>()` 找不到。
  Future<void> onInit() async {}

  /// 首帧绘制之后的钩子（每个插件各调用一次）
  ///
  /// 适合：移除原生闪屏、首帧后的预热 / 埋点 / 预取。
  /// `WApp` 会在 `runApp` 后的第一帧回调里逐个调用；单个插件抛错只记录，
  /// 不影响其它插件（`init` 已经成功，不会因此让 App 启动失败）。
  ///
  /// 只用 `WAppPluginRunner` 时，由调用方在首帧后自行调用
  /// `WAppPluginRunner.firstFrame()`。
  Future<void> onFirstFrame() async {}

  /// 单个插件 [onInit] 的超时时间；null（默认）表示不限制。
  ///
  /// 建议对有网络 / 原生通道的插件显式设置（例如 10s）；默认不设是
  /// 为了不改变「慢但合法」的首次迁移 / 预加载行为。
  Duration? get timeout => null;

  /// 是否为关键插件（默认 true）。
  ///
  /// - true：失败 / 超时按启动失败处理，抛 `WAppPluginInitException`；
  /// - false：记录失败、继续启动；依赖它的插件仍会执行（依赖只表达顺序）。
  bool get critical => true;

  /// 额外的 NavigatorObserver
  ///
  /// 所有插件的 observers 会合并到 MaterialApp.navigatorObservers 列表
  /// （`WApp` 会按栈自动追加 WRouteObserver；同栈不重复追加）。
  ///
  /// 适用于：BotToastNavigatorObserver、自定义路由埋点等。
  /// 该钩子只由 `WApp`（GetX 启动器）消费；单独使用 `WAppPluginRunner` 时无效。
  List<NavigatorObserver>? get navigatorObservers => null;
}
