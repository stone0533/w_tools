import 'package:flutter/material.dart';

import 'image_slots.dart';
import 'image_style.dart';
import 'image_types.dart';

/// 给占位 / 错误占位加尺寸约束（配置了宽高时）。
Widget sizedImageSlot(WImageStyle style, Widget child) {
  if (style.width == null && style.height == null) return child;
  return SizedBox(width: style.width, height: style.height, child: child);
}

Widget fallbackImagePlaceholder(BuildContext context) {
  return ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest);
}

Widget fallbackImageError(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return ColoredBox(
    color: colors.errorContainer,
    child: Icon(Icons.error, color: colors.onErrorContainer),
  );
}

Widget buildImagePlaceholder({
  required BuildContext context,
  required WImageSlots slots,
  required WImageStyle style,
  required String data,
}) {
  final custom = slots.placeholderBuilder?.call(context, data);
  if (custom != null) return sizedImageSlot(style, custom);
  return sizedImageSlot(style, fallbackImagePlaceholder(context));
}

/// 错误占位：业务 builder 优先（自带 onRetry），否则内置图标。
///
/// 需要「错误文案 + 重试按钮」时在 builder 里返回 `WImageErrorView`。
Widget buildImageErrorSlot({
  required BuildContext context,
  required WImageSlots slots,
  required WImageStyle style,
  required WImageError error,
  required VoidCallback onRetry,
}) {
  final custom = slots.errorWidgetBuilder?.call(
    context,
    error.sourceValue,
    error,
    onRetry,
  );
  if (custom != null) return sizedImageSlot(style, custom);
  return sizedImageSlot(style, fallbackImageError(context));
}
