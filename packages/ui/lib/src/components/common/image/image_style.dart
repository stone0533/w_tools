import 'package:flutter/material.dart';

/// 不可变的图片视觉样式。
///
/// 只负责尺寸、布局、装饰与语义；加载/重试/占位/进度由
/// `WImageConfig` 负责。
@immutable
class WImageStyle {
  const WImageStyle({
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.aspectRatio,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.margin,
    this.padding,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.filterQuality = FilterQuality.low,
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

  /// 常用预设：列表缩略图（正方形视觉占位；解码尺寸由 WImageConfig 控制）
  factory WImageStyle.thumbnail(
    double width, {
    double? height,
  }) {
    return WImageStyle(
      width: width,
      height: height ?? width,
      fit: BoxFit.cover,
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
  final double? aspectRatio;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final FilterQuality filterQuality;

  /// 校验（debug assert）
  void validate() {
    assert(aspectRatio == null || aspectRatio! > 0, 'aspectRatio 必须大于 0');
    assert(width == null || width! >= 0, 'width 不能为负');
    assert(height == null || height! >= 0, 'height 不能为负');
    assert(
      !(aspectRatio != null && width != null && height != null),
      'aspectRatio 与固定 width/height 不要同时设置（约束会冲突）',
    );
  }

  static const Object _unset = Object();

  WImageStyle copyWith({
    Object? width = _unset,
    Object? height = _unset,
    Object? fit = _unset,
    Object? alignment = _unset,
    Object? aspectRatio = _unset,
    Object? borderRadius = _unset,
    Object? border = _unset,
    Object? boxShadow = _unset,
    Object? margin = _unset,
    Object? padding = _unset,
    Object? semanticLabel = _unset,
    Object? excludeFromSemantics = _unset,
    Object? filterQuality = _unset,
  }) {
    return WImageStyle(
      width: identical(width, _unset) ? this.width : (width as num?)?.toDouble(),
      height: identical(height, _unset) ? this.height : (height as num?)?.toDouble(),
      fit: identical(fit, _unset) ? this.fit : fit as BoxFit,
      alignment: identical(alignment, _unset) ? this.alignment : alignment as Alignment,
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
      filterQuality:
          identical(filterQuality, _unset) ? this.filterQuality : filterQuality as FilterQuality,
    );
  }
}

/// 不可变样式的链式糖：每次返回新实例。
extension WImageStyleX on WImageStyle {
  WImageStyle square(double size) => copyWith(width: size, height: size);

  WImageStyle rounded(double radius) => copyWith(borderRadius: BorderRadius.circular(radius));
}
