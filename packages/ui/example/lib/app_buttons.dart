import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 项目按钮样式：定义一次，页面直接传 style。
abstract final class AppButtons {
  static WButtonStyle primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.filled(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      borderRadius: BorderRadius.circular(8),
    );
  }

  static WButtonStyle secondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.outlined(
      foregroundColor: scheme.primary,
      borderColor: scheme.primary,
    );
  }

  static WButtonStyle text(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.text(foregroundColor: scheme.primary);
  }

  static WButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.filled(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
