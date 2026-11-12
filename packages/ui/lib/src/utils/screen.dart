import 'dart:ui' as ui show FlutterView;

import 'package:flutter/widgets.dart';

double _identityScaler(double value) => value;

/// 屏幕尺寸与适配工具（零第三方依赖，可与 flutter_screenutil 共存）
///
/// 推荐在 App 根节点用 [WScreenScope] 注入缩放，再在 build 期用
/// [WScreen.of] 读取：
/// ```dart
/// WScreenScope(
///   widthScaler: (v) => ScreenUtil().setWidth(v),
///   heightScaler: (v) => ScreenUtil().setHeight(v),
///   fontScaler: (v) => ScreenUtil().setSp(v),
///   child: app,
/// );
///
/// final screen = WScreen.of(context);
/// Text('标题', style: TextStyle(fontSize: screen.sp(14)));
/// ```
///
/// 注意：不要在 main / 顶层 final / static 初始化中调用 `.sp`；
/// 此时 ScreenUtil 尚未 configure，应在 `ScreenUtilInit.builder` 或
/// `WAppPlugin.builderWrapper` 的 build 期计算。
///
/// 9.0 起静态 `WScreen.w/h/sp` 与全局 delegate 已弃用；10.0 已删除。
/// 新代码统一用 [WScreenScope] + [WScreen.of]。
@immutable
class WScreenData {
  const WScreenData({
    required this.size,
    required this.padding,
    this.widthScaler = _identityScaler,
    this.heightScaler = _identityScaler,
    this.fontScaler = _identityScaler,
  });

  final Size size;
  final EdgeInsets padding;

  /// 宽度缩放函数；无 scope 时是恒等函数。
  final double Function(double) widthScaler;

  /// 高度缩放函数；无 scope 时是恒等函数。
  final double Function(double) heightScaler;

  /// 字体缩放函数；无 scope 时是恒等函数。
  final double Function(double) fontScaler;

  double get width => size.width;
  double get height => size.height;
  double get statusBarHeight => padding.top;
  double get bottomSafeAreaHeight => padding.bottom;

  /// 宽度缩放（跟随当前 [WScreenScope]）
  double w(double value) => widthScaler(value);

  /// 高度缩放（跟随当前 [WScreenScope]）
  double h(double value) => heightScaler(value);

  /// 字体缩放（跟随当前 [WScreenScope]）
  double sp(double value) => fontScaler(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WScreenData &&
          other.size == size &&
          other.padding == padding &&
          identical(other.widthScaler, widthScaler) &&
          identical(other.heightScaler, heightScaler) &&
          identical(other.fontScaler, fontScaler);

  @override
  int get hashCode => Object.hash(
    size,
    padding,
    identityHashCode(widthScaler),
    identityHashCode(heightScaler),
    identityHashCode(fontScaler),
  );
}

/// 在子树内注入屏幕 / 字体缩放，替代 9.x 的全局 delegate。
///
/// 放在 App 根节点；[WScreen.of] 会优先读取最近 scope；读不到时使用恒等缩放。
class WScreenScope extends InheritedWidget {
  const WScreenScope({
    super.key,
    this.widthScaler = _identityScaler,
    this.heightScaler = _identityScaler,
    this.fontScaler = _identityScaler,
    required super.child,
  });

  final double Function(double) widthScaler;
  final double Function(double) heightScaler;
  final double Function(double) fontScaler;

  static WScreenScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WScreenScope>();

  @override
  bool updateShouldNotify(WScreenScope oldWidget) =>
      widthScaler != oldWidget.widthScaler ||
      heightScaler != oldWidget.heightScaler ||
      fontScaler != oldWidget.fontScaler;
}

class WScreen {
  /// 读取当前子树的屏幕信息与缩放函数（推荐）。
  ///
  /// 尺寸跟随最近的 `MediaQuery`，分屏 / 桌面多窗口 / 测试里注入的尺寸都能正确反映；
  /// 缩放优先取最近 [WScreenScope]，没有 scope 时使用恒等函数。
  static WScreenData of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scope = WScreenScope.maybeOf(context);
    return WScreenData(
      size: mq.size,
      padding: mq.padding,
      widthScaler: scope?.widthScaler ?? _identityScaler,
      heightScaler: scope?.heightScaler ?? _identityScaler,
      fontScaler: scope?.fontScaler ?? _identityScaler,
    );
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

  // ──── 内部 ────

  static ui.FlutterView get _view => WidgetsBinding.instance.platformDispatcher.views.first;

  WScreen._();
}
