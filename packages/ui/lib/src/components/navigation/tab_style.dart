import 'package:flutter/material.dart';

/// 标签栏的视觉 / 布局样式。
@immutable
class WTabBarStyle {
  const WTabBarStyle({
    this.labelStyle,
    this.unselectedLabelStyle,
    this.dividerColor,
    this.dividerHeight,
    this.padding,
    this.isScrollable = false,
    this.indicatorSize,
    this.indicatorColor,
    this.indicator,
    this.indicatorWeight = 2.0,
    this.tabAlignment,
    this.overlayColor,
    this.splashFactory,
  });

  /// 明确关闭 overlay + 水波纹的预设；不改变默认样式。
  static const WTabBarStyle noSplash = WTabBarStyle(
    overlayColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
  );

  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? dividerColor;
  final double? dividerHeight;
  final EdgeInsetsGeometry? padding;
  final bool isScrollable;
  final TabBarIndicatorSize? indicatorSize;
  final Color? indicatorColor;
  final Decoration? indicator;
  final double indicatorWeight;
  final TabAlignment? tabAlignment;
  final Color? overlayColor;

  /// 点击 / 长按的水波纹工厂；null 时交给 TabBarTheme。
  final InteractiveInkFeatureFactory? splashFactory;

  WTabBarStyle copyWith({
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? dividerColor,
    double? dividerHeight,
    EdgeInsetsGeometry? padding,
    bool? isScrollable,
    TabBarIndicatorSize? indicatorSize,
    Color? indicatorColor,
    Decoration? indicator,
    double? indicatorWeight,
    TabAlignment? tabAlignment,
    Color? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return WTabBarStyle(
      labelStyle: labelStyle ?? this.labelStyle,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      padding: padding ?? this.padding,
      isScrollable: isScrollable ?? this.isScrollable,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicator: indicator ?? this.indicator,
      indicatorWeight: indicatorWeight ?? this.indicatorWeight,
      tabAlignment: tabAlignment ?? this.tabAlignment,
      overlayColor: overlayColor ?? this.overlayColor,
      splashFactory: splashFactory ?? this.splashFactory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WTabBarStyle &&
          other.labelStyle == labelStyle &&
          other.unselectedLabelStyle == unselectedLabelStyle &&
          other.dividerColor == dividerColor &&
          other.dividerHeight == dividerHeight &&
          other.padding == padding &&
          other.isScrollable == isScrollable &&
          other.indicatorSize == indicatorSize &&
          other.indicatorColor == indicatorColor &&
          other.indicator == indicator &&
          other.indicatorWeight == indicatorWeight &&
          other.tabAlignment == tabAlignment &&
          other.overlayColor == overlayColor &&
          other.splashFactory == splashFactory;

  @override
  int get hashCode => Object.hash(
    labelStyle,
    unselectedLabelStyle,
    dividerColor,
    dividerHeight,
    padding,
    isScrollable,
    indicatorSize,
    indicatorColor,
    indicator,
    indicatorWeight,
    tabAlignment,
    overlayColor,
    splashFactory,
  );
}
