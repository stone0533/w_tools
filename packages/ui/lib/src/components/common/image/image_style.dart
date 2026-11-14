import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 不可变的图片视觉样式。
///
/// 只负责尺寸、布局、装饰与语义；加载/重试/占位/进度由
/// `WImageLoadOptions` 负责。
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
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.filterQuality = FilterQuality.low,
  });

  /// 常用预设：封面图（固定比例 + 可选圆角）
  ///
  /// 头像 / 缩略图直接用 `WImageStyle(width:, height:, borderRadius:)`，
  /// 不再提供 `avatar` / `thumbnail` 这类与项目设计稿争定义的预设。
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
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final FilterQuality filterQuality;

  /// 校验（debug assert）
  void validate() {
    assert(aspectRatio == null || aspectRatio! > 0, 'aspectRatio 必须大于 0');
    assert(width == null || width! >= 0, 'width 不能为负');
    assert(height == null || height! >= 0, 'height 不能为负');
    assert(
      !(aspectRatio != null && (width != null || height != null)),
      'aspectRatio 不能与固定 width/height 同时设置（比例会作用在图片内容上）',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WImageStyle &&
            other.width == width &&
            other.height == height &&
            other.fit == fit &&
            other.alignment == alignment &&
            other.aspectRatio == aspectRatio &&
            other.borderRadius == borderRadius &&
            other.border == border &&
            listEquals(other.boxShadow, boxShadow) &&
            other.semanticLabel == semanticLabel &&
            other.excludeFromSemantics == excludeFromSemantics &&
            other.filterQuality == filterQuality;
  }

  @override
  int get hashCode => Object.hash(
    width,
    height,
    fit,
    alignment,
    aspectRatio,
    borderRadius,
    border,
    boxShadow == null ? null : Object.hashAll(boxShadow!),
    semanticLabel,
    excludeFromSemantics,
    filterQuality,
  );

  /// 派生新样式；传 null 表示保留当前值（不能用 copyWith 清空字段）。
  ///
  /// 需要清空可空字段时用 [withoutWidth] / [withoutHeight] /
  /// [withoutAspectRatio] / [withoutBorderRadius] / [withoutBorder] /
  /// [withoutBoxShadow] / [withoutSemanticLabel]。
  ///
  /// 设置 [width] / [height] 且没有同时传 [aspectRatio] 时，会清空
  /// [aspectRatio]：固定尺寸与比例互斥，这样 `WImageStyle.cover().square(40)`
  /// 这类组合才不会触发 [validate] 断言。
  WImageStyle copyWith({
    double? width,
    double? height,
    BoxFit? fit,
    Alignment? alignment,
    double? aspectRatio,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    String? semanticLabel,
    bool? excludeFromSemantics,
    FilterQuality? filterQuality,
  }) {
    final nextAspectRatio =
        aspectRatio ?? ((width != null || height != null) ? null : this.aspectRatio);
    return _copy(
      width: width ?? this.width,
      height: height ?? this.height,
      fit: fit ?? this.fit,
      alignment: alignment ?? this.alignment,
      aspectRatio: nextAspectRatio,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
      boxShadow: boxShadow ?? this.boxShadow,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
      filterQuality: filterQuality ?? this.filterQuality,
    );
  }

  static const Object _unset = Object();

  WImageStyle _copy({
    Object? width = _unset,
    Object? height = _unset,
    Object? fit = _unset,
    Object? alignment = _unset,
    Object? aspectRatio = _unset,
    Object? borderRadius = _unset,
    Object? border = _unset,
    Object? boxShadow = _unset,
    Object? semanticLabel = _unset,
    Object? excludeFromSemantics = _unset,
    Object? filterQuality = _unset,
  }) {
    return WImageStyle(
      width: identical(width, _unset) ? this.width : (width as num?)?.toDouble(),
      height: identical(height, _unset) ? this.height : (height as num?)?.toDouble(),
      fit: identical(fit, _unset) ? this.fit : fit as BoxFit,
      alignment: identical(alignment, _unset) ? this.alignment : alignment as Alignment,
      aspectRatio: identical(aspectRatio, _unset)
          ? this.aspectRatio
          : (aspectRatio as num?)?.toDouble(),
      borderRadius: identical(borderRadius, _unset)
          ? this.borderRadius
          : borderRadius as BorderRadiusGeometry?,
      border: identical(border, _unset) ? this.border : border as BoxBorder?,
      boxShadow: identical(boxShadow, _unset) ? this.boxShadow : boxShadow as List<BoxShadow>?,
      semanticLabel: identical(semanticLabel, _unset)
          ? this.semanticLabel
          : semanticLabel as String?,
      excludeFromSemantics: identical(excludeFromSemantics, _unset)
          ? this.excludeFromSemantics
          : excludeFromSemantics as bool,
      filterQuality: identical(filterQuality, _unset)
          ? this.filterQuality
          : filterQuality as FilterQuality,
    );
  }

  WImageStyle withoutWidth() => _copy(width: null);

  WImageStyle withoutHeight() => _copy(height: null);

  WImageStyle withoutAspectRatio() => _copy(aspectRatio: null);

  WImageStyle withoutBorderRadius() => _copy(borderRadius: null);

  WImageStyle withoutBorder() => _copy(border: null);

  WImageStyle withoutBoxShadow() => _copy(boxShadow: null);

  WImageStyle withoutSemanticLabel() => _copy(semanticLabel: null);
}

/// 不可变样式的链式糖：每次返回新实例。
extension WImageStyleExtension on WImageStyle {
  WImageStyle square(double size) => copyWith(width: size, height: size);

  WImageStyle rounded(double radius) => copyWith(borderRadius: BorderRadius.circular(radius));
}
