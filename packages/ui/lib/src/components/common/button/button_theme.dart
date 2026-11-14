import 'package:flutter/material.dart';

import 'button_variant.dart';

/// 按钮四态样式（Material [ButtonStyle]）。
///
/// 装到 `ThemeData.extensions` 后，全站 `WButton` 跟随它；未安装时按
/// `ColorScheme` / `TextTheme` 派生（按 `ThemeData` 缓存）。
/// 单个按钮仍可传 `WButton(style: ButtonStyle(...))` 覆盖。
@immutable
class WButtonTheme extends ThemeExtension<WButtonTheme> {
  const WButtonTheme({
    this.filled,
    this.outlined,
    this.text,
    this.danger,
  });

  /// 主按钮；null 时用内置派生值。
  final ButtonStyle? filled;

  /// 描边按钮；null 时用内置派生值。
  final ButtonStyle? outlined;

  /// 文字按钮；null 时用内置派生值。
  final ButtonStyle? text;

  /// 危险按钮；null 时用内置派生值。
  final ButtonStyle? danger;

  /// 取某个变体的样式；缺省字段回退到内置派生值。
  static WButtonTheme of(BuildContext context) {
    final themeData = Theme.of(context);
    final fallback = _fallbacks[themeData] ??= _build(themeData);
    final custom = themeData.extension<WButtonTheme>();
    if (custom == null) return fallback;
    return WButtonTheme(
      filled: custom.filled ?? fallback.filled,
      outlined: custom.outlined ?? fallback.outlined,
      text: custom.text ?? fallback.text,
      danger: custom.danger ?? fallback.danger,
    );
  }

  static final Expando<WButtonTheme> _fallbacks = Expando<WButtonTheme>('WButtonTheme.fallback');

  /// 当前变体对应的 [ButtonStyle]。
  ButtonStyle styleFor(WButtonVariant variant) {
    return switch (variant) {
      WButtonVariant.filled => filled!,
      WButtonVariant.outlined => outlined!,
      WButtonVariant.text => text!,
      WButtonVariant.danger => danger!,
    };
  }

  static WButtonTheme _build(ThemeData theme) {
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final disabledForeground = scheme.onSurface.withValues(alpha: 0.38);
    final disabledBackground = scheme.onSurface.withValues(alpha: 0.12);

    return WButtonTheme(
      filled: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: disabledBackground,
        disabledForegroundColor: disabledForeground,
        textStyle: labelStyle,
        shape: shape,
      ),
      outlined: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        disabledForegroundColor: disabledForeground,
        side: BorderSide(color: scheme.outline),
        textStyle: labelStyle,
        shape: shape,
      ),
      text: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        disabledForegroundColor: disabledForeground,
        textStyle: labelStyle,
        shape: shape,
      ),
      danger: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        disabledBackgroundColor: disabledBackground,
        disabledForegroundColor: disabledForeground,
        textStyle: labelStyle,
        shape: shape,
      ),
    );
  }

  @override
  WButtonTheme copyWith({
    ButtonStyle? filled,
    ButtonStyle? outlined,
    ButtonStyle? text,
    ButtonStyle? danger,
  }) {
    return WButtonTheme(
      filled: filled ?? this.filled,
      outlined: outlined ?? this.outlined,
      text: text ?? this.text,
      danger: danger ?? this.danger,
    );
  }

  @override
  WButtonTheme lerp(ThemeExtension<WButtonTheme>? other, double t) {
    if (other is! WButtonTheme) return this;
    return WButtonTheme(
      filled: ButtonStyle.lerp(filled, other.filled, t),
      outlined: ButtonStyle.lerp(outlined, other.outlined, t),
      text: ButtonStyle.lerp(text, other.text, t),
      danger: ButtonStyle.lerp(danger, other.danger, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonTheme &&
          other.filled == filled &&
          other.outlined == outlined &&
          other.text == text &&
          other.danger == danger;

  @override
  int get hashCode => Object.hash(filled, outlined, text, danger);
}
