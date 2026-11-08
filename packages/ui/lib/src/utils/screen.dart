import 'dart:ui' as ui show FlutterView;
import 'package:flutter/widgets.dart';

/// 屏幕尺寸与适配工具（零第三方依赖，可与 flutter_screenutil 共存）
///
/// 用法：
/// ```dart
/// // 1. 不使用任何屏幕适配库（WScreen.sp/w/h 返回原始值）
/// Text('标题', style: TextStyle(fontSize: WScreen.sp(14)));
///
/// // 2. 与 flutter_screenutil 共存（共享 ScreenUtil 配置）
/// // 注意：不要在 main / 顶层 final / static 初始化中调用 `.sp`，
/// // 此时 ScreenUtil 尚未 configure；应在 ScreenUtilInit.builder 或
/// // WAppPlugin.builderWrapper 的 build 期计算。
/// runApp(ScreenUtilInit(
///   designSize: const Size(375, 667),
///   builder: (context, child) {
///     WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
///     WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
///     WScreen.delegateFont  = (v) => ScreenUtil().setSp(v);
///     return child!;
///   },
/// ));
/// ```
/// 树内屏幕信息（来自最近的 [MediaQuery]）。
@immutable
class WScreenData {
  const WScreenData({required this.size, required this.padding});

  final Size size;
  final EdgeInsets padding;

  double get width => size.width;
  double get height => size.height;
  double get statusBarHeight => padding.top;
  double get bottomSafeAreaHeight => padding.bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WScreenData && other.size == size && other.padding == padding;

  @override
  int get hashCode => Object.hash(size, padding);
}

class WScreen {
  /// 读取当前子树的屏幕信息（推荐）。
  ///
  /// 与下面的静态 getter 不同，它跟随最近的 `MediaQuery`，分屏 / 桌面多窗口 /
  /// 测试里注入的尺寸都能正确反映。
  static WScreenData of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return WScreenData(size: mq.size, padding: mq.padding);
  }

  // ──── 设备信息（永远可用，和 ScreenUtil 无关） ────

  /// 设备屏幕宽度（逻辑像素）
  static double get screenWidth => _view.physicalSize.width / _view.devicePixelRatio;

  /// 设备屏幕高度（逻辑像素）
  static double get screenHeight => _view.physicalSize.height / _view.devicePixelRatio;

  /// 状态栏高度（刘海屏会更高）
  static double get statusBarHeight => _view.padding.top / _view.devicePixelRatio;

  /// 底部安全区高度
  static double get bottomSafeAreaHeight => _view.padding.bottom / _view.devicePixelRatio;

  // ──── 适配委托（用户需要屏幕适配时注入） ────
  // 同时使用 flutter_screenutil 时，把 ScreenUtil 的 setWidth/setHeight/setSp 注入进来

  /// 宽度缩放委托（对应 flutter_screenutil 的 .w）
  static double Function(double)? delegateWidth;

  /// 高度缩放委托（对应 flutter_screenutil 的 .h）
  static double Function(double)? delegateHeight;

  /// 字体缩放委托（对应 flutter_screenutil 默认 .sp 行为）
  static double Function(double)? delegateFont;

  // ──── 适配函数 ────

  /// 宽度缩放（无 delegate 时返回原始值）
  static double w(double value) => delegateWidth?.call(value) ?? value;

  /// 高度缩放（无 delegate 时返回原始值）
  static double h(double value) => delegateHeight?.call(value) ?? value;

  /// 字体缩放（无 delegate 时返回原始值）
  static double sp(double value) => delegateFont?.call(value) ?? value;

  /// 测试用：清空全部 delegate，恢复恒等行为。
  static void reset() {
    delegateWidth = null;
    delegateHeight = null;
    delegateFont = null;
  }

  // ──── 内部 ────

  static ui.FlutterView get _view => WidgetsBinding.instance.platformDispatcher.views.first;

  WScreen._();
}
