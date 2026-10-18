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
class WScreen {
  // ──── 设备信息（永远可用，和 ScreenUtil 无关） ────

  /// 设备屏幕宽度（逻辑像素）
  static double get screenWidth => _mq.size.width;

  /// 设备屏幕高度（逻辑像素）
  static double get screenHeight => _mq.size.height;

  /// 状态栏高度（刘海屏会更高）
  static double get statusBarHeight => _mq.padding.top;

  /// 底部安全区高度
  static double get bottomBarHeight => _mq.padding.bottom;

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

  // ──── 内部 ────

  static MediaQueryData get _mq => MediaQueryData.fromView(_view);

  static ui.FlutterView get _view => WidgetsBinding.instance.platformDispatcher.views.first;

  WScreen._();
}
