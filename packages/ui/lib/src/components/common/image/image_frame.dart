import 'package:flutter/material.dart';

import 'image_style.dart';

/// 图片装饰层：padding / margin / borderRadius / border / boxShadow。
///
/// 顺序与 `Container` 一致（margin 在外、padding 在内）；但尺寸语义不同：
/// `WImageStyle.width/height` 只约束图片内容，padding / margin 会额外加在总尺寸上
/// （`width: 10` + `padding: 5` 的最终尺寸是 20，而不是 Container 的 10）。
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

    // padding 在装饰层内（内容与边框之间的留白），margin 在最外
    if (padding != null) {
      result = Padding(padding: padding, child: result);
    }

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

    if (margin != null) {
      result = Padding(padding: margin, child: result);
    }

    return result;
  }
}
