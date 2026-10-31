import 'package:flutter/material.dart';

import 'w_text_styles.dart';

/// 文本组件。
///
/// 单色 / 单样式文本优先使用 [variant] + [WTextStyles]；
/// 局部差异用 [style] / [color] 覆盖。
class WText extends StatelessWidget {
  /// 文本内容
  final String text;

  /// 语义文字样式；为 null 时不额外应用语义样式。
  final WTextVariant? variant;

  /// 一次性样式覆盖，优先级高于 variant。
  final TextStyle? style;

  /// 一次性颜色覆盖，优先级高于 variant / style。
  final Color? color;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final String? semanticsLabel;
  final Locale? locale;
  final TextWidthBasis? textWidthBasis;
  final StrutStyle? strutStyle;

  const WText({
    super.key,
    required this.text,
    this.variant,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    this.textDirection,
    this.textScaler,
    this.semanticsLabel,
    this.locale,
    this.textWidthBasis,
    this.strutStyle,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle? effectiveStyle;
    final variant = this.variant;
    if (variant != null) {
      effectiveStyle = WTextStyles.of(context).resolve(variant);
    }
    if (style != null) {
      effectiveStyle = effectiveStyle?.merge(style) ?? style;
    }
    if (color != null) {
      effectiveStyle = (effectiveStyle ?? const TextStyle()).copyWith(color: color);
    }

    return Text(
      text,
      style: effectiveStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
      locale: locale,
      textWidthBasis: textWidthBasis,
    );
  }
}
