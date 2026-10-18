import 'package:flutter/material.dart';

/// WApp 插件接口 — 让第三方能力以声明式注入应用生命周期
///
/// 生命周期顺序：
///   WidgetsFlutterBinding.ensureInitialized()
///   → 系统设置（状态栏、屏幕方向）
///   → plugin.onInit()：按 [dependsOn] 分层执行（同层并行、跨层串行）
///   → customTasks（并行）
///   → 首帧后 onLazyInit()
///   → runApp(...)
///
/// run 阶段两个包裹钩子的位置（以两个插件 P₁、P₂ 为例，自外向内）：
/// ```
/// runApp(
///   P₂.wrapApp(                     // 插件 wrapApp：后注册者更靠外
///     P₁.wrapApp(
///       appWrapper(                 // `WApp.appWrapper` 字段（位于插件之内）
///         GetMaterialApp(
///           builder: (ctx, nav) =>  // `WApp.builder` 字段（位于插件之外）
///             P₂.builderWrapper(
///               P₁.builderWrapper(nav),
///             ),
///         ),
///       ),
///     ),
///   ),
/// );
/// ```
///
/// `WApp.builder` / `WApp.appWrapper` 是上述两个位置的**单例字段版**入口；
/// 注意二者的叠加次序**相反**：builder 应用在插件链**之后**（更靠外），
/// appWrapper 应用在插件链**之前**（更靠内）。
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
  /// 同一层的插件并行执行，下一层等待上一层全部完成。
  /// 引用未注册的插件名或存在循环依赖时，`WApp.init` 会抛出 [StateError]。
  ///
  /// **有执行顺序要求的插件必须显式声明本列表** —— 同层插件并行执行，
  /// 未声明则无先后保证（共享资源时可能产生竞态）。
  List<String> get dependsOn => const [];

  // ──── init 阶段钩子 ────

  /// 应用初始化钩子（在 ensureInitialized 之后、runApp 之前执行）
  ///
  /// 适用于：dotenv 加载、日志配置、SharedPreferences 预加载等异步准备工作
  ///
  /// **注意**：任一插件的 `onInit` 抛错都会中断整个启动（fail-fast）。
  Future<void> onInit() async {}

  // ──── run 阶段钩子 ────

  /// 包裹 GetMaterialApp 的 `builder` 参数
  ///
  /// **位置**：MaterialApp 内部、Navigator 之上 —— Theme / Localizations /
  /// MediaQuery / ScaffoldMessenger / Overlay 均可用。
  ///
  /// **何时用**：需要这些上下文才能工作的中间件，例如需要 Navigator/Overlay 的
  /// BotToast、需要 Localizations 的 easy_localization。
  ///
  /// 返回的 TransitionBuilder 按插件注册顺序串联（后注册者更靠外），
  /// 最后再叠加 `WApp.builder`。
  ///
  /// **注意**：返回的 widget 必须把入参 `child` 纳入其 widget 树，
  /// 否则会丢弃整个 app（黑屏）。
  TransitionBuilder? get builderWrapper => null;

  /// 包裹整个 app Widget（最外层包装）
  ///
  /// **位置**：MaterialApp **之外** —— 此处 **没有** Theme / Localizations /
  /// MediaQuery / Directionality（除非外层自备）。
  ///
  /// **何时用**：需要覆盖 MaterialApp 之外的 `MediaQuery`、包最外层手势，
  /// 或做全局尺寸适配（如 ScreenUtilInit）时。
  ///
  /// 多个插件时**最外层**插件的返回值即 runApp 的 child；`WApp.appWrapper`
  /// 会先于本钩子执行，因而位于插件 wrapApp 链的**更内层**。
  ///
  /// **注意**：返回的 widget 必须把入参 `child` 纳入其 widget 树，
  /// 否则会丢弃整个 app（黑屏）。
  Widget wrapApp(Widget child) => child;

  /// 额外的 NavigatorObserver
  ///
  /// 所有插件的 observers 会合并到 GetMaterialApp.navigatorObservers 列表
  /// （WRouteObserver 会在最后追加，保证路由观测完整性）
  ///
  /// 适用于：BotToastNavigatorObserver、自定义路由埋点等
  List<NavigatorObserver>? get navigatorObservers => null;
}
