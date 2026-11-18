import 'package:flutter/material.dart';

/// 项目按钮样式：定义一次，页面直接传 style（Material ButtonStyle）。
///
/// AppButtons 只提供样式，不改变按钮类型；调用点必须使用匹配的构造器：
/// - primary / danger → `WButton.filled(style: ...)`
/// - secondary       → `WButton.outlined(style: ...)`
/// - text            → `WButton.text(style: ...)`
abstract final class AppButtons {
  /// 主按钮；配合 `WButton.filled` 使用。
  static ButtonStyle primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  /// 描边按钮；配合 `WButton.outlined` 使用。
  static ButtonStyle secondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: scheme.primary,
      side: BorderSide(color: scheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 文字按钮；配合 `WButton.text` 使用。
  static ButtonStyle text(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.styleFrom(foregroundColor: scheme.primary);
  }

  /// 危险按钮；配合 `WButton.filled` 使用。
  static ButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
