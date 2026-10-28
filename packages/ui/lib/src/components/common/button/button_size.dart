import 'package:flutter/material.dart';

import '../text.dart';

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
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.iconSize,
    this.gap,
  });

  final String name;
  final double? minWidth;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;
  final WTextConfig? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? iconSize;
  final double? gap;

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

  WButtonSize copyWith({
    String? name,
    double? minWidth,
    double? minHeight,
    EdgeInsetsGeometry? padding,
    WTextConfig? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    double? iconSize,
    double? gap,
  }) {
    return WButtonSize(
      name: name ?? this.name,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      iconSize: iconSize ?? this.iconSize,
      gap: gap ?? this.gap,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WButtonSize &&
      other.name == name &&
      other.minWidth == minWidth &&
      other.minHeight == minHeight &&
      other.padding == padding &&
      other.textStyle == textStyle &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.iconSize == iconSize &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(
        name,
        minWidth,
        minHeight,
        padding,
        textStyle,
        fontSize,
        fontWeight,
        iconSize,
        gap,
      );
}
