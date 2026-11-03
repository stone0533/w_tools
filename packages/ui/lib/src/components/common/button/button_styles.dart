import 'package:flutter/material.dart';

import 'button_style.dart';

/// 按钮样式：主题派生默认值 + 兼容预设。
///
/// 新代码用 `WButtonStyles.of(context)`（跟随 `ColorScheme` / `TextTheme`）；
/// 下面的静态预设是旧的硬编码 fallback，已弃用（5.0 移除）。
abstract final class WButtonStyles {
  /// 按当前主题派生的四种语义样式。
  ///
  /// - `primary`：`colorScheme.primary` / `onPrimary`
  /// - `secondary`：描边，`primary` 前景 + `outline` 边框
  /// - `text`：`primary` 前景
  /// - `danger`：`error` / `onError`
  ///
  /// 结果按 `ThemeData` 缓存，主题不变时是同一个实例。
  static ({
    WButtonStyle primary,
    WButtonStyle secondary,
    WButtonStyle text,
    WButtonStyle danger,
  })
  of(BuildContext context) {
    final theme = Theme.of(context);
    return _cache[theme] ??= _build(theme);
  }

  static final Expando<
    ({WButtonStyle primary, WButtonStyle secondary, WButtonStyle text, WButtonStyle danger})
  >
  _cache = Expando();

  static ({
    WButtonStyle primary,
    WButtonStyle secondary,
    WButtonStyle text,
    WButtonStyle danger,
  })
  _build(ThemeData theme) {
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge;
    return (
      primary: WButtonStyle.filled(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: labelStyle,
      ),
      secondary: WButtonStyle.outlined(
        foregroundColor: scheme.primary,
        borderColor: scheme.outline,
        textStyle: labelStyle,
      ),
      text: WButtonStyle.text(
        foregroundColor: scheme.primary,
        textStyle: labelStyle,
      ),
      danger: WButtonStyle.filled(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        textStyle: labelStyle,
      ),
    );
  }
}
