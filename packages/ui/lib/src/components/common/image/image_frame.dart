import 'package:flutter/material.dart';

import 'image_style.dart';

/// 图片装饰层：borderRadius / border / boxShadow。
///
/// 只做装饰；留白（padding / margin）交给调用方的 `Padding` / `Container`，
/// 这样 `WImageStyle.width/height` 的尺寸语义与 Flutter 一致。
class WImageFrame extends StatelessWidget {
  const WImageFrame({super.key, required this.style, required this.child});

  final WImageStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = style.borderRadius;
    final border = style.border;
    // style 的 const 构造保留 boxShadow 引用；渲染时做一次不可变快照。
    final boxShadow = style.boxShadow == null
        ? null
        : List<BoxShadow>.unmodifiable(style.boxShadow!);

    if (borderRadius == null && border == null && (boxShadow == null || boxShadow.isEmpty)) {
      return child;
    }

    Widget result = child;

    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }

    // 阴影在图片下层；边框必须在图片上层，否则会被图片完全盖住。
    final hasShadow = boxShadow != null && boxShadow.isNotEmpty;
    if (hasShadow) {
      result = DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: boxShadow),
        child: result,
      );
    }

    if (border != null) {
      result = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: borderRadius, border: border),
        child: result,
      );
    }

    return result;
  }
}
