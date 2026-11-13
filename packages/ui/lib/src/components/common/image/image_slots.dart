import 'package:flutter/widgets.dart';

import 'image_types.dart';

/// 图片加载 UI 的单图 / 作用域默认值集合。
///
/// [WImage] 可以传一份单图 slots；`WImageTheme` 提供 App 级默认值。
/// 单图未给出的字段会按字段回退到主题，再回退到内置兜底。
@immutable
class WImageSlots {
  const WImageSlots({
    this.placeholderBuilder,
    this.emptyBuilder,
    this.errorWidgetBuilder,
    this.progressBuilder,
    this.showRetryButton,
    this.retryLabel,
  });

  final Widget? Function(BuildContext context, String data)? placeholderBuilder;

  /// 空 data（`''` / 纯空白）的占位 UI；默认与加载中占位一样是中性底色。
  ///
  /// 「没有配图」不是错误，不会触发 [errorWidgetBuilder]。
  final Widget? Function(BuildContext context, String data)? emptyBuilder;
  final Widget? Function(BuildContext context, String data, WImageError error)? errorWidgetBuilder;
  final Widget? Function(BuildContext context, String data, WImageProgress progress)?
  progressBuilder;

  /// 是否显示内置“错误 + 重试”视图；null 表示继承主题
  final bool? showRetryButton;

  /// 内置重试按钮文案；null 表示继承主题，空字符串表示按当前 `Locale` 使用内置文案
  /// （zh：重试；其他：Retry）。
  final String? retryLabel;

  @override
  bool operator ==(Object other) =>
      other is WImageSlots &&
      other.placeholderBuilder == placeholderBuilder &&
      other.emptyBuilder == emptyBuilder &&
      other.errorWidgetBuilder == errorWidgetBuilder &&
      other.progressBuilder == progressBuilder &&
      other.showRetryButton == showRetryButton &&
      other.retryLabel == retryLabel;

  @override
  int get hashCode => Object.hash(
    placeholderBuilder,
    emptyBuilder,
    errorWidgetBuilder,
    progressBuilder,
    showRetryButton,
    retryLabel,
  );
}
