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
///
/// SVG / 资源图 / 品牌图标用 [WIconText.custom] 传任意 [Widget]，不强制引入
/// `flutter_svg`；详见 ADR-0009。
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

  /// 自定义图标：接受任意 [Widget]（`SvgPicture.asset` / `Image.asset` / 品牌图标等）。
  ///
  /// 与主构造器保持相同的行盒对齐、间距、语义与文字样式；不引入 `flutter_svg`
  /// 依赖，SVG 项目自行传 `SvgPicture`。
  ///
  /// [iconSize] / [iconColor] 通过 `IconTheme` 传给图标；不读取 `IconTheme` 的
  /// Widget（如部分 SVG 配置）需要自行控制尺寸 / 颜色。
  static Widget custom({
    Key? key,
    required Widget icon,
    required String text,
    WTextVariant? variant,
    TextStyle? style,
    Color? color,
    double? iconSize,
    Color? iconColor,
    double gap = 6,
    Offset iconOffset = Offset.zero,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
    TextDirection? textDirection,
    TextScaler? textScaler,
    bool? softWrap,
    String? semanticsLabel,
  }) {
    assert(gap >= 0, 'WIconText.gap 不能为负');
    return _WIconTextCustom(
      key: key,
      icon: icon,
      text: text,
      variant: variant,
      style: style,
      color: color,
      iconSize: iconSize,
      iconColor: iconColor,
      gap: gap,
      iconOffset: iconOffset,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WIconTextLayout(
      iconData: icon,
      text: text,
      variant: variant,
      style: style,
      color: color,
      iconSize: iconSize,
      iconColor: iconColor,
      gap: gap,
      iconOffset: iconOffset,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}

class _WIconTextCustom extends StatelessWidget {
  const _WIconTextCustom({
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
  });

  final Widget icon;
  final String text;
  final WTextVariant? variant;
  final TextStyle? style;
  final Color? color;
  final double? iconSize;
  final Color? iconColor;
  final double gap;
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
    return _WIconTextLayout(
      iconWidget: icon,
      text: text,
      variant: variant,
      style: style,
      color: color,
      iconSize: iconSize,
      iconColor: iconColor,
      gap: gap,
      iconOffset: iconOffset,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}

class _WIconTextLayout extends StatelessWidget {
  const _WIconTextLayout({
    this.iconData,
    this.iconWidget,
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
  }) : assert(
         (iconData == null) != (iconWidget == null),
         'WIconText 图标只能二选一',
       );

  final IconData? iconData;
  final Widget? iconWidget;
  final String text;
  final WTextVariant? variant;
  final TextStyle? style;
  final Color? color;
  final double? iconSize;
  final Color? iconColor;
  final double gap;
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
    final Widget iconChild;
    if (iconData != null) {
      iconChild = Icon(iconData, size: resolvedIconSize, color: resolvedIconColor);
    } else {
      iconChild = IconTheme(
        data: IconThemeData(size: resolvedIconSize, color: resolvedIconColor),
        child: iconWidget!,
      );
    }
    final iconBox = Directionality(
      textDirection: effectiveDirection,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: gap),
        child: Transform.translate(
          offset: iconOffset,
          child: ExcludeSemantics(child: iconChild),
        ),
      ),
    );

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: iconBox,
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
