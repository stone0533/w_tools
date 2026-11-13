import 'package:flutter/material.dart';

import 'button_style.dart';

/// 四种语义按钮样式的命名集合。
///
/// 用 [WButtonStyleSet.of] 获取；结果按 `ThemeData` 缓存，主题不变时是同一个实例。
@immutable
class WButtonStyleSet {
  const WButtonStyleSet({
    required this.primary,
    required this.secondary,
    required this.text,
    required this.danger,
  });

  /// 主按钮：`colorScheme.primary` / `onPrimary`
  final WButtonStyle primary;

  /// 次按钮：描边，`primary` 前景 + `outline` 边框
  final WButtonStyle secondary;

  /// 文字按钮：`primary` 前景
  final WButtonStyle text;

  /// 危险按钮：`error` / `onError`
  final WButtonStyle danger;

  /// 按当前主题派生四种语义样式。
  ///
  /// - `primary`：`colorScheme.primary` / `onPrimary`
  /// - `secondary`：描边，`primary` 前景 + `outline` 边框
  /// - `text`：`primary` 前景
  /// - `danger`：`error` / `onError`
  ///
  /// 结果按 `ThemeData` 缓存，主题不变时是同一个实例。
  static WButtonStyleSet of(BuildContext context) {
    final theme = Theme.of(context);
    return _cache[theme] ??= _build(theme);
  }

  static final Expando<WButtonStyleSet> _cache = Expando();

  static WButtonStyleSet _build(ThemeData theme) {
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge;
    return WButtonStyleSet(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonStyleSet &&
          other.primary == primary &&
          other.secondary == secondary &&
          other.text == text &&
          other.danger == danger;

  @override
  int get hashCode => Object.hash(primary, secondary, text, danger);
}
