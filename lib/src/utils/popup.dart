import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 显示弹出层
///
/// @param context 上下文
/// @param builder 构建弹出层内容的回调函数
/// @param elevation 阴影高度
/// @param shadowColor 阴影颜色
/// @param animationDuration 动画持续时间
void showPopup({
  required BuildContext context,
  required WidgetBuilder builder,
  double? elevation,
  Color? shadowColor,
  Duration animationDuration = const Duration(milliseconds: 200),
}) {
  final RenderBox button = context.findRenderObject()! as RenderBox;
  final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

  Offset offset = Offset(0.0, button.size.height);

  RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(offset, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero) + offset,
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );

  Navigator.of(context).push(
    CustomPopupRoute(
      position: position,
      builder: builder,
      elevation: elevation,
      shadowColor: shadowColor,
      animationDuration: animationDuration,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

/// 自定义弹出层路由类
class CustomPopupRoute<T> extends PopupRoute<T> {
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

  /// 构造函数
  ///
  /// @param builder 构建弹出层内容的回调函数
  /// @param position 弹出层位置
  /// @param barrierLabel 屏障标签
  /// @param elevation 阴影高度
  /// @param shadowColor 阴影颜色
  /// @param animationDuration 动画持续时间
  CustomPopupRoute({
    required this.builder,
    required this.position,
    required this.barrierLabel,
    this.elevation,
    this.shadowColor,
    Duration? animationDuration,
  }) : animationDuration = animationDuration ?? const Duration(milliseconds: 200),
       super(
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

  /// 构建页面
  ///
  /// @param context 上下文
  /// @param animation 动画
  /// @param secondaryAnimation 次级动画
  /// @return 构建的页面
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    EdgeInsets padding = MediaQuery.paddingOf(context);
    final CurveTween heightFactorTween = CurveTween(
      curve: const Interval(0.0, 1.0),
    );
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: CustomSingleChildLayout(
        delegate: _CustomPopupRouteLayout(position, padding),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: elevation ?? 0,
              shadowColor: shadowColor,
              child: _HeightFactorBox(
                heightFactor: heightFactorTween.evaluate(animation),
                child: child,
              ),
            );
          },
          child: builder(context),
        ),
      ),
    );
  }
}

/// 自定义弹出层布局代理
class _CustomPopupRouteLayout extends SingleChildLayoutDelegate {
  /// 弹出层位置
  final RelativeRect position;

  /// 内边距
  EdgeInsets padding;

  /// 子控件最大高度
  double childHeightMax = 0;

  /// 构造函数
  ///
  /// @param position 弹出层位置
  /// @param padding 内边距
  _CustomPopupRouteLayout(this.position, this.padding);

  /// 获取子控件的约束
  ///
  /// @param constraints 约束
  /// @return 子控件的约束
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    Size buttonSize = position.toSize(constraints.biggest);

    double constraintsWidth = buttonSize.width;
    double constraintsHeight = max(
      position.top - buttonSize.height - padding.top - kToolbarHeight,
      constraints.biggest.height - position.top - padding.bottom,
    );

    return BoxConstraints.loose(Size(constraintsWidth, constraintsHeight));
  }

  /// 获取子控件的位置
  ///
  /// @param size 父控件大小
  /// @param childSize 子控件大小
  /// @return 子控件的位置
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position.left;
    double y = position.top;
    final double buttonHeight = size.height - position.top - position.bottom;
    double constraintsHeight = max(
      position.top - buttonHeight - padding.top - kToolbarHeight,
      size.height - position.top - padding.bottom,
    );
    if (position.top + constraintsHeight > size.height - padding.bottom) {
      y = position.top - childSize.height - buttonHeight;
    }

    return Offset(x, y);
  }

  /// 是否需要重新布局
  ///
  /// @param oldDelegate 旧代理
  /// @return 是否需要重新布局
  @override
  bool shouldRelayout(covariant _CustomPopupRouteLayout oldDelegate) {
    return position != oldDelegate.position || padding != oldDelegate.padding;
  }
}

/// 高度因子渲染框
class _RenderHeightFactorBox extends RenderShiftedBox {
  /// 高度因子
  double _heightFactor;

  /// 构造函数
  ///
  /// @param child 子控件
  /// @param heightFactor 高度因子
  _RenderHeightFactorBox({
    RenderBox? child,
    double? heightFactor,
  }) : _heightFactor = heightFactor ?? 1.0,
       super(child);

  /// 获取高度因子
  double get heightFactor => _heightFactor;

  /// 设置高度因子
  set heightFactor(double value) {
    if (_heightFactor == value) {
      return;
    }
    _heightFactor = value;
    markNeedsLayout();
  }

  /// 执行布局
  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    child!.layout(constraints, parentUsesSize: true);

    size = constraints.constrain(
      Size(
        child!.size.width,
        child!.size.height,
      ),
    );

    child!.layout(
      constraints.copyWith(
        maxWidth: size.width,
        maxHeight: size.height * heightFactor,
      ),
      parentUsesSize: true,
    );

    size = constraints.constrain(
      Size(
        child!.size.width,
        child!.size.height,
      ),
    );
  }
}

/// 高度因子盒 widget
class _HeightFactorBox extends SingleChildRenderObjectWidget {
  /// 高度因子
  final double? heightFactor;

  /// 构造函数
  ///
  /// @param heightFactor 高度因子
  /// @param child 子控件
  const _HeightFactorBox({
    this.heightFactor,
    super.child,
  });

  /// 创建渲染对象
  ///
  /// @param context 上下文
  /// @return 渲染对象
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightFactorBox(heightFactor: heightFactor);

  /// 更新渲染对象
  ///
  /// @param context 上下文
  /// @param renderObject 渲染对象
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightFactorBox renderObject,
  ) {
    renderObject.heightFactor = heightFactor ?? 1.0;
  }
}
