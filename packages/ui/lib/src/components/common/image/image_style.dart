import 'package:flutter/material.dart';

import 'image_types.dart';

/// 不可变的图片样式。
@immutable
class WImageStyle {
  const WImageStyle({
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.aspectRatio,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.margin,
    this.padding,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    this.retryCount = 0,
    this.retryDelay = 1000,
    this.placeholderBuilder,
    this.errorWidgetBuilder,
    this.progressBuilder,
    this.placeholder,
    this.errorWidget,
    this.showRetryButton = false,
    this.retryLabel = '重试',
  });

  /// 常用预设：头像（正方形 + 全圆角）
  factory WImageStyle.avatar(
    double size, {
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return WImageStyle(
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      border: border,
      boxShadow: boxShadow,
    );
  }

  /// 常用预设：列表缩略图（正方形 + 解码尺寸上限）
  factory WImageStyle.thumbnail(
    double width, {
    double? height,
    int? cacheSize,
  }) {
    final side = height ?? width;
    final cache = cacheSize ?? (width * 3).round();
    return WImageStyle(
      width: width,
      height: side,
      fit: BoxFit.cover,
      memCacheWidth: cache,
      memCacheHeight: cache,
    );
  }

  /// 常用预设：封面图（固定比例 + 可选圆角）
  factory WImageStyle.cover({
    double? aspectRatio = 16 / 9,
    double? radius,
  }) {
    return WImageStyle(
      aspectRatio: aspectRatio,
      fit: BoxFit.cover,
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
    );
  }

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? aspectRatio;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final int retryCount;
  final int retryDelay;
  final Widget? Function(BuildContext, String)? placeholderBuilder;
  final Widget? Function(BuildContext, String, WImageError)? errorWidgetBuilder;
  final Widget? Function(BuildContext, String, WImageProgress)? progressBuilder;

  /// 固定占位符（与 builder 二选一）
  final Widget? placeholder;

  /// 固定错误占位（与 builder 二选一）
  final Widget? errorWidget;

  /// 没有自定义错误占位时，是否显示内置的“错误 + 重试”视图
  final bool showRetryButton;

  /// 内置重试按钮文案
  final String retryLabel;

  /// 校验（debug assert）
  void validate() {
    assert(retryCount >= 0, 'retryCount 不能为负');
    assert(retryDelay >= 0, 'retryDelay 不能为负');
    assert(memCacheWidth == null || memCacheWidth! > 0, 'memCacheWidth 必须大于 0');
    assert(memCacheHeight == null || memCacheHeight! > 0, 'memCacheHeight 必须大于 0');
    assert(aspectRatio == null || aspectRatio! > 0, 'aspectRatio 必须大于 0');
    assert(width == null || width! >= 0, 'width 不能为负');
    assert(height == null || height! >= 0, 'height 不能为负');
    assert(
      !(aspectRatio != null && width != null && height != null),
      'aspectRatio 与固定 width/height 不要同时设置（约束会冲突）',
    );
    assert(
      !(placeholder != null && placeholderBuilder != null),
      'placeholder 与 placeholderBuilder 只能选一个（builder 优先）',
    );
    assert(
      !(errorWidget != null && errorWidgetBuilder != null),
      'errorWidget 与 errorWidgetBuilder 只能选一个（builder 优先）',
    );
  }

  static const Object _unset = Object();

  WImageStyle copyWith({
    Object? width = _unset,
    Object? height = _unset,
    Object? fit = _unset,
    Object? alignment = _unset,
    Object? memCacheWidth = _unset,
    Object? memCacheHeight = _unset,
    Object? aspectRatio = _unset,
    Object? borderRadius = _unset,
    Object? border = _unset,
    Object? boxShadow = _unset,
    Object? margin = _unset,
    Object? padding = _unset,
    Object? semanticLabel = _unset,
    Object? excludeFromSemantics = _unset,
    Object? gaplessPlayback = _unset,
    Object? filterQuality = _unset,
    Object? retryCount = _unset,
    Object? retryDelay = _unset,
    Object? placeholderBuilder = _unset,
    Object? errorWidgetBuilder = _unset,
    Object? progressBuilder = _unset,
    Object? placeholder = _unset,
    Object? errorWidget = _unset,
    Object? showRetryButton = _unset,
    Object? retryLabel = _unset,
  }) {
    return WImageStyle(
      width: identical(width, _unset) ? this.width : (width as num?)?.toDouble(),
      height: identical(height, _unset) ? this.height : (height as num?)?.toDouble(),
      fit: identical(fit, _unset) ? this.fit : fit as BoxFit,
      alignment: identical(alignment, _unset) ? this.alignment : alignment as Alignment,
      memCacheWidth: identical(memCacheWidth, _unset) ? this.memCacheWidth : memCacheWidth as int?,
      memCacheHeight:
          identical(memCacheHeight, _unset) ? this.memCacheHeight : memCacheHeight as int?,
      aspectRatio:
          identical(aspectRatio, _unset) ? this.aspectRatio : (aspectRatio as num?)?.toDouble(),
      borderRadius:
          identical(borderRadius, _unset) ? this.borderRadius : borderRadius as BorderRadius?,
      border: identical(border, _unset) ? this.border : border as BoxBorder?,
      boxShadow: identical(boxShadow, _unset) ? this.boxShadow : boxShadow as List<BoxShadow>?,
      margin: identical(margin, _unset) ? this.margin : margin as EdgeInsets?,
      padding: identical(padding, _unset) ? this.padding : padding as EdgeInsets?,
      semanticLabel:
          identical(semanticLabel, _unset) ? this.semanticLabel : semanticLabel as String?,
      excludeFromSemantics: identical(excludeFromSemantics, _unset)
          ? this.excludeFromSemantics
          : excludeFromSemantics as bool,
      gaplessPlayback:
          identical(gaplessPlayback, _unset) ? this.gaplessPlayback : gaplessPlayback as bool,
      filterQuality:
          identical(filterQuality, _unset) ? this.filterQuality : filterQuality as FilterQuality,
      retryCount: identical(retryCount, _unset) ? this.retryCount : retryCount as int,
      retryDelay: identical(retryDelay, _unset) ? this.retryDelay : retryDelay as int,
      placeholderBuilder: identical(placeholderBuilder, _unset)
          ? this.placeholderBuilder
          : placeholderBuilder as Widget? Function(BuildContext, String)?,
      errorWidgetBuilder: identical(errorWidgetBuilder, _unset)
          ? this.errorWidgetBuilder
          : errorWidgetBuilder as Widget? Function(BuildContext, String, WImageError)?,
      progressBuilder: identical(progressBuilder, _unset)
          ? this.progressBuilder
          : progressBuilder as Widget? Function(BuildContext, String, WImageProgress)?,
      placeholder: identical(placeholder, _unset) ? this.placeholder : placeholder as Widget?,
      errorWidget: identical(errorWidget, _unset) ? this.errorWidget : errorWidget as Widget?,
      showRetryButton:
          identical(showRetryButton, _unset) ? this.showRetryButton : showRetryButton as bool,
      retryLabel: identical(retryLabel, _unset) ? this.retryLabel : retryLabel as String,
    );
  }
}

/// 不可变样式的链式糖：每次返回新实例。
extension WImageStyleX on WImageStyle {
  WImageStyle square(double size) => copyWith(width: size, height: size);

  WImageStyle rounded(double radius) => copyWith(borderRadius: BorderRadius.circular(radius));

  WImageStyle memCached(int size) => copyWith(memCacheWidth: size, memCacheHeight: size);
}
