import 'package:flutter/material.dart';

/// 表单字段统一默认样式。
///
/// 放在 [WForm] 上，由直接字段构造读取；单个字段需要不同样式时用
/// [WFormFieldStyleScope] 包裹该字段。
/// 本类不可变，可以安全共享。
class WFormFieldStyle {
  const WFormFieldStyle({
    this.height,
    this.containerPadding,
    this.textStyle,
    this.placeholderStyle,
    // remove-in: 9.0.0
    @Deprecated('Use placeholderStyle instead. remove-in: 9.0.0') this.hintStyle,
  });

  final double? height;
  final EdgeInsetsGeometry? containerPadding;
  final TextStyle? textStyle;

  /// 占位符文字样式。
  final TextStyle? placeholderStyle;

  /// 历史占位符样式；用 [placeholderStyle]。构造参数已弃用（remove-in: 9.0.0）。
  final TextStyle? hintStyle;

  /// 兼容新旧字段的实际占位符样式。
  TextStyle? get effectiveHintStyle => placeholderStyle ?? hintStyle;

  /// 读取最近的字段样式；没有 WForm 时返回 null。
  static WFormFieldStyle? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WFormFieldStyleScope>()?.style;
  }

  @override
  bool operator ==(Object other) =>
      other is WFormFieldStyle &&
      other.height == height &&
      other.containerPadding == containerPadding &&
      other.textStyle == textStyle &&
      other.placeholderStyle == placeholderStyle &&
      other.hintStyle == hintStyle;

  @override
  int get hashCode => Object.hash(height, containerPadding, textStyle, placeholderStyle, hintStyle);
}

/// 覆盖一棵子树内直接字段的 [WFormFieldStyle]。
///
/// 常见用法是只包住一个字段：
///
/// ```dart
/// WFormFieldStyleScope(
///   style: const WFormFieldStyle(height: 72),
///   child: WFormTextField(name: 'bio', maxLines: 3),
/// )
/// ```
class WFormFieldStyleScope extends InheritedWidget {
  const WFormFieldStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  final WFormFieldStyle? style;

  @override
  bool updateShouldNotify(WFormFieldStyleScope oldWidget) {
    return style != oldWidget.style;
  }
}
