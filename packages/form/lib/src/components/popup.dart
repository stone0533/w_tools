import 'dart:math';

import 'package:flutter/material.dart';

/// 弹出层默认动画持续时间
const Duration _defaultPopupAnimationDuration = Duration(milliseconds: 200);

/// 表单弹出层工具
///
/// 在锚点下方弹出内容，空间不足时自动向上翻转，常用于下拉框、多选等场景。
///
/// 弹层位置在打开时计算一次；锚点滚动后不会自动跟随。
class WFormPopup {
  WFormPopup._();

  /// 当前有弹层打开的 Navigator（防止重复 push）
  static final Set<NavigatorState> _activeNavigators = <NavigatorState>{};

  /// 显示弹出层，返回关闭时回传的结果
  ///
  /// 同一 [Navigator] 已有弹层时忽略本次调用，返回一个已完成的 null Future。
  ///
  /// - [anchorContext]：定位锚点（默认使用 [context]），用于对齐到更精确的输入区域
  /// - [rootNavigator]：是否推入根 Navigator
  /// - [width]：弹层宽度（null 时与锚点同宽）
  /// - [backgroundColor]：弹层背景色（null 时使用主题 canvas 色）
  /// - [borderRadius]：弹层圆角（设置后会裁剪内容）
  /// - [settings]：路由设置，便于观测/调试
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? elevation,
    Color? shadowColor,
    Duration animationDuration = _defaultPopupAnimationDuration,
    BuildContext? anchorContext,
    bool rootNavigator = false,
    double? width,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    RouteSettings? settings,
  }) {
    final navigator = Navigator.of(context, rootNavigator: rootNavigator);
    if (!_activeNavigators.add(navigator)) {
      // 已有弹层打开，忽略重复调用
      return Future<T?>.value();
    }

    try {
      final RenderBox anchor = _renderBoxOf(anchorContext ?? context);
      final RenderBox overlay = _renderBoxOf(
        (navigator.overlay ?? Overlay.of(context)).context,
      );

      final Offset offset = Offset(0.0, anchor.size.height);

      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          anchor.localToGlobal(offset, ancestor: overlay),
          anchor.localToGlobal(
            anchor.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );

      final Future<T?> future = navigator.push<T>(
        WFormPopupRoute<T>(
          position: position,
          builder: builder,
          elevation: elevation,
          shadowColor: shadowColor,
          animationDuration: animationDuration,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          width: width,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          settings: settings,
        ),
      );
      future.whenComplete(() => _activeNavigators.remove(navigator));
      return future;
    } catch (_) {
      _activeNavigators.remove(navigator);
      rethrow;
    }
  }

  /// 关闭当前弹层，并可回传结果
  ///
  /// 仅在弹层打开时调用；否则会弹出普通页面。
  /// [rootNavigator] 需与 [show] 时保持一致，避免弹错路由栈。
  static void hide<T>(BuildContext context, [T? result, bool rootNavigator = false]) {
    Navigator.of(context, rootNavigator: rootNavigator).pop<T>(result);
  }

  /// 获取已完成布局的 RenderBox
  static RenderBox _renderBoxOf(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw StateError('WFormPopup 的锚点尚未完成布局');
    }
    return renderObject;
  }
}

/// 表单弹出层路由
class WFormPopupRoute<T> extends PopupRoute<T> {
  /// 构建弹出层内容的回调函数
  final WidgetBuilder builder;

  /// 弹出层位置
  final RelativeRect position;

  /// 阴影高度
  final double? elevation;

  /// 阴影颜色
  final Color? shadowColor;

  /// 屏障标签
  @override
  final String? barrierLabel;

  /// 动画持续时间
  final Duration animationDuration;

  /// 弹层宽度（null 时与锚点同宽）
  final double? width;

  /// 弹层背景色
  final Color? backgroundColor;

  /// 弹层圆角
  final BorderRadius? borderRadius;

  /// 创建弹出层路由
  WFormPopupRoute({
    required this.builder,
    required this.position,
    required this.barrierLabel,
    this.elevation,
    this.shadowColor,
    this.animationDuration = _defaultPopupAnimationDuration,
    this.width,
    this.backgroundColor,
    this.borderRadius,
    super.settings,
  }) : super(
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );

  /// 屏障颜色
  @override
  Color? get barrierColor => null;

  /// 是否可通过点击屏障关闭
  @override
  bool get barrierDismissible => true;

  /// 过渡动画持续时间
  @override
  Duration get transitionDuration => animationDuration;

  /// 构建弹出层页面
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final EdgeInsets safeArea = MediaQuery.paddingOf(context);
    // 键盘弹起时底部可用空间取安全区与键盘高度的较大值
    final EdgeInsets insets = safeArea.copyWith(
      bottom: max(safeArea.bottom, MediaQuery.viewInsetsOf(context).bottom),
    );
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: CustomSingleChildLayout(
        delegate: _CustomPopupRouteLayout(position, insets, width),
        child: Material(
          elevation: elevation ?? 0,
          shadowColor: shadowColor,
          color: backgroundColor,
          borderRadius: borderRadius,
          clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
          child: SizeTransition(
            sizeFactor: animation,
            // Flutter 3.38 起 SizeTransition 不再有 alignment，改用 axisAlignment
            // （-1.0 = 顶部对齐，等价于原来的 Alignment.topCenter）
            axisAlignment: -1.0,
            // 撑满外层约束，保证「未指定 width 时与锚点同宽」
            child: SizedBox(width: double.infinity, child: builder(context)),
          ),
        ),
      ),
    );
  }
}

/// 弹出层布局代理
class _CustomPopupRouteLayout extends SingleChildLayoutDelegate {
  /// 弹出层位置
  final RelativeRect position;

  /// 安全区内边距（bottom 已合并键盘高度）
  final EdgeInsets padding;

  /// 弹层宽度（null 时与锚点同宽）
  final double? width;

  /// 创建弹出层布局代理
  _CustomPopupRouteLayout(this.position, this.padding, this.width);

  /// 计算子控件约束
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final Size anchorSize = position.toSize(constraints.biggest);
    final double resolvedWidth = max(0.0, width ?? anchorSize.width);

    // 锚点上方 / 下方可用空间（已扣除安全区，不假设存在 AppBar）
    final double spaceAbove = position.top - anchorSize.height - padding.top;
    final double spaceBelow = constraints.biggest.height - position.top - padding.bottom;

    return BoxConstraints(
      minWidth: resolvedWidth,
      maxWidth: resolvedWidth,
      maxHeight: max(0.0, max(spaceAbove, spaceBelow)),
    );
  }

  /// 计算子控件位置
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double x = position.left;
    final double anchorHeight = size.height - position.top - position.bottom;
    final double spaceAbove = position.top - anchorHeight - padding.top;
    final double spaceBelow = size.height - position.top - padding.bottom;

    // 上方空间更大时向上翻转，否则显示在锚点下方
    final double y = spaceAbove > spaceBelow
        ? position.top - childSize.height - anchorHeight
        : position.top;

    return Offset(x, y);
  }

  /// 是否需要重新布局
  @override
  bool shouldRelayout(covariant _CustomPopupRouteLayout oldDelegate) {
    return position != oldDelegate.position ||
        padding != oldDelegate.padding ||
        width != oldDelegate.width;
  }
}
