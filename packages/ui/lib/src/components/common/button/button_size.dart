import 'package:flutter/material.dart';

const Object _unset = Object();

/// 不可变的按钮尺寸令牌。
///
/// 3 个默认值只是约定，不是限制；项目可以自定义任意 [WButtonSize]。
@immutable
class WButtonSize {
  const WButtonSize({
    required this.name,
    this.minWidth,
    this.minHeight,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.lineHeight,
    this.letterSpacing,
    this.iconSize,
    this.gap,
    this.tapTargetSize = 48,
  });

  final String name;
  final double? minWidth;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? lineHeight;
  final double? letterSpacing;
  final double? iconSize;
  final double? gap;

  /// 实际 hit area 下限；视觉尺寸可以更小。
  final double tapTargetSize;

  static const small = WButtonSize(
    name: 'small',
    minHeight: 32,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    fontSize: 13,
    iconSize: 16,
    gap: 6,
  );

  static const medium = WButtonSize(
    name: 'medium',
    minHeight: 40,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    fontSize: 14,
    iconSize: 18,
    gap: 8,
  );

  static const large = WButtonSize(
    name: 'large',
    minHeight: 48,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    fontSize: 15,
    iconSize: 20,
    gap: 10,
  );

  void validate() {
    assert(minWidth == null || (minWidth! >= 0 && minWidth!.isFinite));
    assert(minHeight == null || (minHeight! >= 0 && minHeight!.isFinite));
    assert(fontSize == null || (fontSize! > 0 && fontSize!.isFinite));
    assert(lineHeight == null || (lineHeight! > 0 && lineHeight!.isFinite));
    assert(letterSpacing == null || letterSpacing!.isFinite);
    assert(iconSize == null || (iconSize! >= 0 && iconSize!.isFinite));
    assert(gap == null || (gap! >= 0 && gap!.isFinite));
    assert(tapTargetSize >= 0 && tapTargetSize.isFinite);
  }

  WButtonSize copyWith({
    String? name,
    Object? minWidth = _unset,
    Object? minHeight = _unset,
    Object? padding = _unset,
    Object? fontSize = _unset,
    Object? fontWeight = _unset,
    Object? lineHeight = _unset,
    Object? letterSpacing = _unset,
    Object? iconSize = _unset,
    Object? gap = _unset,
    double? tapTargetSize,
  }) {
    return WButtonSize(
      name: name ?? this.name,
      minWidth: identical(minWidth, _unset) ? this.minWidth : (minWidth as num?)?.toDouble(),
      minHeight: identical(minHeight, _unset) ? this.minHeight : (minHeight as num?)?.toDouble(),
      padding: identical(padding, _unset) ? this.padding : padding as EdgeInsetsGeometry?,
      fontSize: identical(fontSize, _unset) ? this.fontSize : (fontSize as num?)?.toDouble(),
      fontWeight: identical(fontWeight, _unset) ? this.fontWeight : fontWeight as FontWeight?,
      lineHeight: identical(lineHeight, _unset)
          ? this.lineHeight
          : (lineHeight as num?)?.toDouble(),
      letterSpacing: identical(letterSpacing, _unset)
          ? this.letterSpacing
          : (letterSpacing as num?)?.toDouble(),
      iconSize: identical(iconSize, _unset) ? this.iconSize : (iconSize as num?)?.toDouble(),
      gap: identical(gap, _unset) ? this.gap : (gap as num?)?.toDouble(),
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WButtonSize &&
      other.name == name &&
      other.minWidth == minWidth &&
      other.minHeight == minHeight &&
      other.padding == padding &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.lineHeight == lineHeight &&
      other.letterSpacing == letterSpacing &&
      other.iconSize == iconSize &&
      other.gap == gap &&
      other.tapTargetSize == tapTargetSize;

  @override
  int get hashCode => Object.hash(
    name,
    minWidth,
    minHeight,
    padding,
    fontSize,
    fontWeight,
    lineHeight,
    letterSpacing,
    iconSize,
    gap,
    tapTargetSize,
  );
}
