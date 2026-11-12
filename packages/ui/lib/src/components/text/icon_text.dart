import 'package:flutter/material.dart';

import 'w_text_styles.dart';

/// 图标 + 文字一行，按行盒中点垂直对齐。
///
/// 设计规格（正文 14–15px）：
/// - `gap = 6`：图标与文字之间的视觉间距；比 `WButton` 的 8 略紧，因为这里没有按钮内边距；
/// - `iconSize = (fontSize + 2) * textScaler`：14 → 16、15 → 17，覆盖常见 16/18 图标；
///   默认跟随系统字号缩放，显式传 [iconSize] 时由调用方负责；
/// - 用 [WidgetSpan] + [PlaceholderAlignment.middle] 对齐行盒中点，避免
///   `Row + Icon + Text` 用整行高度居中时，中文字形让图标看起来偏高 1.5~2.5px；
/// - [iconOffset] 默认 [Offset.zero]：不同字体视觉重心不同，需要按品牌字体微调时再传。
///
/// 文本样式走 [variant] / [WTextStyles]，局部差异用 [style] / [color]；
/// 纯图标或需要按钮语义时用 `WButton(icon: ...)`。
class WIconText extends StatelessWidget {
  const WIconText({
    super.key,
    required this.icon,
    required this.text,
    this.variant,
    this.style,
    this.color,
    this.iconSize,
    this.iconColor,
    this.gap = 6,
    this.iconOffset = Offset.zero,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textDirection,
    this.textScaler,
    this.softWrap,
    this.semanticsLabel,
  }) : assert(gap >= 0, 'WIconText.gap 不能为负');

  /// 图标
  final IconData icon;

  /// 文字内容
  final String text;

  /// 语义文字样式；为 null 时不额外应用语义样式。
  final WTextVariant? variant;

  /// 一次性样式覆盖，优先级高于 variant。
  final TextStyle? style;

  /// 一次性颜色覆盖，优先级高于 variant / style。
  final Color? color;

  /// 图标尺寸；null 时取 `fontSize + 2`。
  final double? iconSize;

  /// 图标颜色；null 时跟随文字颜色，再回退到 `IconTheme`。
  final Color? iconColor;

  /// 图标与文字之间的间距
  final double gap;

  /// 图标的微调位移；默认零，品牌字体视觉重心不同时使用。
  ///
  /// 正值向下 / 向右；只影响绘制，不影响布局占位。
  final Offset iconOffset;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final fallbackStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = _resolveStyle(context);
    final fontSize = effectiveStyle?.fontSize ?? fallbackStyle.fontSize ?? 14;
    // 显式 iconSize 由调用方负责；默认尺寸跟随 textScaler，和文字一起放大。
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
    final resolvedIconSize = iconSize ?? scaler.scale(fontSize + 2);
    final resolvedIconColor = iconColor ?? effectiveStyle?.color ?? fallbackStyle.color;

    final effectiveDirection = textDirection ?? Directionality.of(context);
    final iconWidget = Directionality(
      textDirection: effectiveDirection,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: gap),
        child: Transform.translate(
          offset: iconOffset,
          child: ExcludeSemantics(
            child: Icon(
              icon,
              size: resolvedIconSize,
              color: resolvedIconColor,
            ),
          ),
        ),
      ),
    );

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: iconWidget,
          ),
          TextSpan(text: text),
        ],
      ),
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }

  TextStyle? _resolveStyle(BuildContext context) {
    var effective = variant == null ? null : WTextStyles.of(context).resolve(variant!);
    if (style != null) {
      effective = effective?.merge(style) ?? style;
    }
    if (color != null) {
      effective = (effective ?? const TextStyle()).copyWith(color: color);
    }
    return effective;
  }
}
