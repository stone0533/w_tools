import 'package:flutter/material.dart';

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
    double? minWidth,
    double? minHeight,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    double? lineHeight,
    double? letterSpacing,
    double? iconSize,
    double? gap,
    double? tapTargetSize,
  }) {
    return WButtonSize(
      name: name ?? this.name,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      iconSize: iconSize ?? this.iconSize,
      gap: gap ?? this.gap,
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
