import 'image_slots.dart';

/// 合并单图 slots 与主题 slots：单图非空字段优先。
///
/// `showRetryButton == true` 时不再继承主题的错误 builder，避免主题的
/// 自定义错误 UI 覆盖内置重试视图。
WImageSlots mergeImageSlots({
  required WImageSlots? own,
  required WImageSlots theme,
}) {
  if (own == null) return theme;

  final showRetry = own.showRetryButton ?? theme.showRetryButton;
  final inheritThemeError = own.errorWidgetBuilder == null && showRetry != true;

  return WImageSlots(
    placeholderBuilder: own.placeholderBuilder ?? theme.placeholderBuilder,
    emptyBuilder: own.emptyBuilder ?? theme.emptyBuilder,
    errorWidgetBuilder:
        own.errorWidgetBuilder ?? (inheritThemeError ? theme.errorWidgetBuilder : null),
    progressBuilder: own.progressBuilder ?? theme.progressBuilder,
    showRetryButton: showRetry,
    retryLabel: own.retryLabel ?? theme.retryLabel,
  );
}
