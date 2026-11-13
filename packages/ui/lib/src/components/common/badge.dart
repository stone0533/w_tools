import 'package:flutter/material.dart';

/// 角标位置。
///
/// `topEnd` 的 [end] 跟随当前 [Directionality]（LTR 是右边，RTL 是左边）。
@immutable
class WBadgePosition {
  /// 右上角（RTL 下为左上角）。
  const WBadgePosition.topEnd({this.top = 0, this.end = 0}) : _center = false;

  /// 居中覆盖 child。
  const WBadgePosition.center() : top = 0, end = 0, _center = true;

  final double top;
  final double end;
  final bool _center;

  bool get isCenter => _center;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WBadgePosition && other.top == top && other.end == end && other._center == _center;

  @override
  int get hashCode => Object.hash(top, end, _center);

  @override
  String toString() =>
      _center ? 'WBadgePosition.center()' : 'WBadgePosition.topEnd(top: $top, end: $end)';
}

/// 角标视觉样式。
///
/// 未设置的字段从 [ColorScheme] / [TextTheme] 解析：
/// 背景取 `colorScheme.error`，前景取 `colorScheme.onError`。
@immutable
class WBadgeStyle {
  const WBadgeStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.border,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  WBadgeStyle copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
  }) {
    return WBadgeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WBadgeStyle &&
          other.backgroundColor == backgroundColor &&
          other.foregroundColor == foregroundColor &&
          other.textStyle == textStyle &&
          other.padding == padding &&
          other.borderRadius == borderRadius &&
          other.border == border;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    textStyle,
    padding,
    borderRadius,
    border,
  );
}

/// 徽章组件，用于显示角标或标记。
///
/// 默认背景 / 前景来自 `ColorScheme.error` / `onError`；需要自定义时传 [style]。
class WBadge extends StatelessWidget {
  const WBadge({
    super.key,
    this.badgeContent,
    this.child,
    this.position = const WBadgePosition.topEnd(),
    this.style,
    this.showBadge = true,
    this.semanticLabel,
  });

  /// 徽章内容；为 null 时不渲染徽章。
  final Widget? badgeContent;

  /// 被标记的 child。
  final Widget? child;

  /// 徽章位置，默认右上角。
  final WBadgePosition position;

  /// 徽章视觉；null 时跟随 `ColorScheme`。
  final WBadgeStyle? style;

  /// 是否显示徽章。
  final bool showBadge;

  /// 徽章的读屏标签（如「3 条未读」）。
  ///
  /// 提供后气泡内的文字 / 图标不再单独朗读，只播报这个标签；
  /// 未提供时保持原有语义（气泡内容自行参与朗读）。
  final String? semanticLabel;

  /// 数量角标：超过 [maxCount] 时显示 `maxCount+`。
  factory WBadge.count({
    Key? key,
    required int count,
    int? maxCount,
    Widget? child,
    WBadgePosition position = const WBadgePosition.topEnd(),
    WBadgeStyle? style,
    bool showBadge = true,
    String? semanticLabel,
  }) {
    final text = maxCount != null && count > maxCount ? '$maxCount+' : '$count';
    return WBadge(
      key: key,
      badgeContent: Text(text),
      position: position,
      style: style,
      showBadge: showBadge,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  /// 圆点角标：只有存在感，不显示数字。
  factory WBadge.dot({
    Key? key,
    Widget? child,
    WBadgePosition position = const WBadgePosition.topEnd(),
    WBadgeStyle? style,
    bool showBadge = true,
    String? semanticLabel,
  }) {
    final effectiveStyle = (style ?? const WBadgeStyle()).copyWith(
      padding: EdgeInsets.zero,
    );
    return WBadge(
      key: key,
      badgeContent: const SizedBox.square(dimension: 8),
      position: position,
      style: effectiveStyle,
      showBadge: showBadge,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = badgeContent;
    if (!showBadge || content == null) {
      return child ?? const SizedBox.shrink();
    }

    final bubble = _WBadgeBubble(style: style, child: content);
    final semantic = semanticLabel;
    final paintedBubble = semantic == null
        ? bubble
        : Semantics(
            label: semantic,
            container: true,
            child: ExcludeSemantics(child: bubble),
          );
    final anchor = child;
    if (anchor == null) return paintedBubble;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        anchor,
        if (position.isCenter)
          Positioned.fill(child: Center(child: paintedBubble))
        else
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: position.top,
            end: position.end,
            child: paintedBubble,
          ),
      ],
    );
  }
}

class _WBadgeBubble extends StatelessWidget {
  const _WBadgeBubble({required this.style, required this.child});

  final WBadgeStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = style?.backgroundColor ?? scheme.error;
    final foreground = style?.foregroundColor ?? scheme.onError;
    final baseTextStyle = style?.textStyle ?? theme.textTheme.labelSmall;
    final padding = style?.padding ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 2);
    final borderRadius = style?.borderRadius ?? const BorderRadius.all(Radius.circular(999));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: style?.border,
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: (baseTextStyle ?? const TextStyle()).copyWith(
            color: foreground,
            fontSize: (baseTextStyle?.fontSize ?? 11),
            height: baseTextStyle?.height ?? 1.2,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: baseTextStyle?.fontSize ?? 11),
            child: child,
          ),
        ),
      ),
    );
  }
}
