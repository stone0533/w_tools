import 'package:flutter/material.dart';

import 'image_style.dart';

/// 图片装饰层：padding / margin / borderRadius / border / boxShadow。
///
/// 顺序与 `Container` 一致：margin 在外，padding 在内；圆角同时作用于
/// 图片本体、border 与 shadow。
class WImageFrame extends StatelessWidget {
  const WImageFrame({super.key, required this.style, required this.child});

  final WImageStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = style.borderRadius;
    final border = style.border;
    final boxShadow = style.boxShadow;
    final margin = style.margin;
    final padding = style.padding;

    if (borderRadius == null &&
        border == null &&
        (boxShadow == null || boxShadow.isEmpty) &&
        margin == null &&
        padding == null) {
      return child;
    }

    Widget result = child;

    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }

    if (border != null || (boxShadow != null && boxShadow.isNotEmpty)) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: border,
          boxShadow: boxShadow,
        ),
        child: result,
      );
    }

    if (margin != null) {
      result = Padding(padding: margin, child: result);
    }
    if (padding != null) {
      result = Padding(padding: padding, child: result);
    }

    return result;
  }
}
