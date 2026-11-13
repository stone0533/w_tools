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

  final ownShowRetry = own.showRetryButton;
  final showRetry = ownShowRetry ?? theme.showRetryButton;
  final ownHasError = own.errorWidgetBuilder != null || own.errorWidget != null;
  final inheritThemeError = !ownHasError && showRetry != true;

  final placeholderBuilder =
      own.placeholderBuilder ?? (own.placeholder == null ? theme.placeholderBuilder : null);
  final placeholder =
      own.placeholder ??
      (own.placeholderBuilder == null && placeholderBuilder == null ? theme.placeholder : null);
  final emptyBuilder = own.emptyBuilder ?? (own.emptyWidget == null ? theme.emptyBuilder : null);
  final emptyWidget =
      own.emptyWidget ??
      (own.emptyBuilder == null && emptyBuilder == null ? theme.emptyWidget : null);
  final errorWidgetBuilder =
      own.errorWidgetBuilder ??
      (own.errorWidget == null && inheritThemeError ? theme.errorWidgetBuilder : null);
  final errorWidget =
      own.errorWidget ??
      (own.errorWidgetBuilder == null && errorWidgetBuilder == null && inheritThemeError
          ? theme.errorWidget
          : null);

  return WImageSlots(
    placeholderBuilder: placeholderBuilder,
    placeholder: placeholder,
    emptyBuilder: emptyBuilder,
    emptyWidget: emptyWidget,
    errorWidgetBuilder: errorWidgetBuilder,
    errorWidget: errorWidget,
    progressBuilder: own.progressBuilder ?? theme.progressBuilder,
    showRetryButton: showRetry,
    retryLabel: own.retryLabel ?? theme.retryLabel,
  );
}
