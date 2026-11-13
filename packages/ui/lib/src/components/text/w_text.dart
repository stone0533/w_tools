import 'package:flutter/material.dart';

import 'w_text_styles.dart';

/// 文本组件。
///
/// 单色 / 单样式文本优先使用 [variant] + [WTextStyles]；
/// 局部差异用 [style] / [color] 覆盖。
/// 保留旧 WTextConfig 对 strut 的处理：有字体信息时避免大字号 / 字体回退裁切。
StrutStyle? _resolveStrutStyle(TextStyle? style, StrutStyle? override) {
  if (override != null) return override;
  if (style == null ||
      (style.fontFamily == null && style.fontSize == null && style.height == null)) {
    return null;
  }
  return StrutStyle(
    fontFamily: style.fontFamily,
    fontSize: style.fontSize,
    height: style.height,
    forceStrutHeight: true,
  );
}

class WText extends StatelessWidget {
  /// 文本内容
  final String text;

  /// 富文本内容；仅 [WText.rich] 使用，普通构造下为 null。
  final TextSpan? textSpan;

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
  }) : textSpan = null;

  /// 富文本入口：混合样式的段落仍然套用 [variant] 的根样式。
  ///
  /// 子 [TextSpan] 只写差异（颜色、字重等），不要重复 root 样式；
  /// 与普通构造一样支持 maxLines / overflow / textScaler 等排版参数。
  const WText.rich({
    super.key,
    required this.textSpan,
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
  }) : text = '';

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

    final autoStrutStyle = _resolveStrutStyle(effectiveStyle, strutStyle);
    final span = textSpan;

    if (span != null) {
      return Text.rich(
        span,
        style: effectiveStyle,
        strutStyle: autoStrutStyle,
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

    return Text(
      text,
      style: effectiveStyle,
      strutStyle: autoStrutStyle,
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
