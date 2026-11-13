import 'package:flutter/material.dart';

import 'image_slots.dart';
import 'image_error_view.dart';
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

/// 空 data 的默认占位：中性底色，和「加载失败」的 errorContainer 明确区分。
Widget fallbackImageEmpty(BuildContext context) {
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

Widget buildImageEmptySlot({
  required BuildContext context,
  required WImageSlots slots,
  required WImageStyle style,
  required String data,
}) {
  final custom = slots.emptyBuilder?.call(context, data);
  if (custom != null) return sizedImageSlot(style, custom);
  return sizedImageSlot(style, fallbackImageEmpty(context));
}

Widget buildImageErrorSlot({
  required BuildContext context,
  required WImageSlots slots,
  required WImageStyle style,
  required WImageError error,
  required VoidCallback? onRetry,
}) {
  final custom = slots.errorWidgetBuilder?.call(context, error.sourceValue, error);
  if (custom != null) return sizedImageSlot(style, custom);
  if (slots.showRetryButton ?? false) {
    final canRetry = const {
      WImageErrorKind.network,
      WImageErrorKind.provider,
      WImageErrorKind.file,
    }.contains(error.kind);
    return sizedImageSlot(
      style,
      WImageErrorView(
        error: error,
        onRetry: canRetry ? onRetry : null,
        retryLabel: slots.retryLabel ?? '',
      ),
    );
  }
  return sizedImageSlot(style, fallbackImageError(context));
}
