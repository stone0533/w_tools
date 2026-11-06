import 'package:flutter/material.dart';

/// debug 下提示 WImage 在无界轴上的 0 尺寸占位。
void debugCheckWImageSizeHint(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return;
  final constraints = renderObject.constraints;
  final size = renderObject.size;
  final unboundedWidth = constraints.maxWidth.isInfinite;
  final unboundedHeight = constraints.maxHeight.isInfinite;
  if (!unboundedWidth && !unboundedHeight) return;
  final zeroWidth = unboundedWidth && size.width <= 0;
  final zeroHeight = unboundedHeight && size.height <= 0;
  if (!zeroWidth && !zeroHeight) return;
  final axis = zeroWidth && zeroHeight ? '宽高' : (zeroWidth ? '宽度' : '高度');
  debugPrint(
    '[w_tools_ui] WImage 在$axis轴上没有确定尺寸（加载前占位为 0，会表现为空白）。'
    '请给 WImageStyle 设置 width / height / aspectRatio，'
    '或让父级在$axis轴上有界（SizedBox / Expanded / AspectRatio）。',
  );
}
