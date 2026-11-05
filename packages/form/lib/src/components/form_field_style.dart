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
    this.hintStyle,
  });

  final double? height;
  final EdgeInsetsGeometry? containerPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  /// 读取最近的字段样式；没有 WForm 时返回 null。
  static WFormFieldStyle? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WFormFieldStyleScope>()?.style;
  }
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
