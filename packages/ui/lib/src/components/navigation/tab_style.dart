import 'package:flutter/material.dart';

/// 标签栏的视觉 / 布局样式。
@immutable
class WTabBarStyle {
  const WTabBarStyle({
    this.labelStyle,
    this.unselectedLabelStyle,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelPadding,
    this.indicatorPadding,
    this.textScaler,
    this.dividerColor,
    this.dividerHeight,
    this.padding,
    this.isScrollable = false,
    this.indicatorSize,
    this.indicatorColor,
    this.indicator,
    this.indicatorWeight = 2.0,
    this.indicatorAnimation,
    this.tabAlignment,
    this.overlayColor,
    this.splashFactory,
    this.mouseCursor,
    this.enableFeedback,
    this.splashBorderRadius,
  });

  /// 明确关闭 overlay + 水波纹的预设；不改变默认样式。
  static const WTabBarStyle noSplash = WTabBarStyle(
    overlayColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
  );

  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final EdgeInsetsGeometry? labelPadding;
  final EdgeInsetsGeometry? indicatorPadding;
  final TextScaler? textScaler;
  final Color? dividerColor;
  final double? dividerHeight;
  final EdgeInsetsGeometry? padding;
  final bool isScrollable;
  final TabBarIndicatorSize? indicatorSize;
  final Color? indicatorColor;
  final Decoration? indicator;
  final double indicatorWeight;
  final TabIndicatorAnimation? indicatorAnimation;
  final TabAlignment? tabAlignment;
  final Color? overlayColor;

  /// 点击 / 长按的水波纹工厂；null 时交给 TabBarTheme。
  final InteractiveInkFeatureFactory? splashFactory;

  /// 鼠标指针；null 时交给 TabBarTheme。
  final MouseCursor? mouseCursor;

  /// 点击 / 长按是否触发反馈；null 时交给 TabBarTheme。
  final bool? enableFeedback;

  /// 水波纹裁剪圆角；null 时交给 TabBarTheme。
  final BorderRadius? splashBorderRadius;

  WTabBarStyle copyWith({
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? labelColor,
    Color? unselectedLabelColor,
    EdgeInsetsGeometry? labelPadding,
    EdgeInsetsGeometry? indicatorPadding,
    TextScaler? textScaler,
    Color? dividerColor,
    double? dividerHeight,
    EdgeInsetsGeometry? padding,
    bool? isScrollable,
    TabBarIndicatorSize? indicatorSize,
    Color? indicatorColor,
    Decoration? indicator,
    double? indicatorWeight,
    TabIndicatorAnimation? indicatorAnimation,
    TabAlignment? tabAlignment,
    Color? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
    MouseCursor? mouseCursor,
    bool? enableFeedback,
    BorderRadius? splashBorderRadius,
  }) {
    return WTabBarStyle(
      labelStyle: labelStyle ?? this.labelStyle,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      labelColor: labelColor ?? this.labelColor,
      unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
      labelPadding: labelPadding ?? this.labelPadding,
      indicatorPadding: indicatorPadding ?? this.indicatorPadding,
      textScaler: textScaler ?? this.textScaler,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      padding: padding ?? this.padding,
      isScrollable: isScrollable ?? this.isScrollable,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicator: indicator ?? this.indicator,
      indicatorWeight: indicatorWeight ?? this.indicatorWeight,
      indicatorAnimation: indicatorAnimation ?? this.indicatorAnimation,
      tabAlignment: tabAlignment ?? this.tabAlignment,
      overlayColor: overlayColor ?? this.overlayColor,
      splashFactory: splashFactory ?? this.splashFactory,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      splashBorderRadius: splashBorderRadius ?? this.splashBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WTabBarStyle &&
          other.labelStyle == labelStyle &&
          other.unselectedLabelStyle == unselectedLabelStyle &&
          other.labelColor == labelColor &&
          other.unselectedLabelColor == unselectedLabelColor &&
          other.labelPadding == labelPadding &&
          other.indicatorPadding == indicatorPadding &&
          other.textScaler == textScaler &&
          other.dividerColor == dividerColor &&
          other.dividerHeight == dividerHeight &&
          other.padding == padding &&
          other.isScrollable == isScrollable &&
          other.indicatorSize == indicatorSize &&
          other.indicatorColor == indicatorColor &&
          other.indicator == indicator &&
          other.indicatorWeight == indicatorWeight &&
          other.indicatorAnimation == indicatorAnimation &&
          other.tabAlignment == tabAlignment &&
          other.overlayColor == overlayColor &&
          other.splashFactory == splashFactory &&
          other.mouseCursor == mouseCursor &&
          other.enableFeedback == enableFeedback &&
          other.splashBorderRadius == splashBorderRadius;

  @override
  int get hashCode => Object.hashAll([
    labelStyle,
    unselectedLabelStyle,
    labelColor,
    unselectedLabelColor,
    labelPadding,
    indicatorPadding,
    textScaler,
    dividerColor,
    dividerHeight,
    padding,
    isScrollable,
    indicatorSize,
    indicatorColor,
    indicator,
    indicatorWeight,
    indicatorAnimation,
    tabAlignment,
    overlayColor,
    splashFactory,
    mouseCursor,
    enableFeedback,
    splashBorderRadius,
  ]);
}
