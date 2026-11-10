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
    this.placeholder,
    this.emptyWidget,
    this.errorWidget,
    this.showRetryButton,
    this.retryLabel,
  });

  final Widget? Function(BuildContext context, String data)? placeholderBuilder;

  /// 空 data（`''` / 纯空白）的占位 UI；默认与加载中占位一样是中性底色。
  ///
  /// 「没有配图」不是错误，不会触发 [errorWidgetBuilder] / [errorWidget]。
  final Widget? Function(BuildContext context, String data)? emptyBuilder;
  final Widget? Function(BuildContext context, String data, WImageError error)? errorWidgetBuilder;
  final Widget? Function(BuildContext context, String data, WImageProgress progress)?
  progressBuilder;

  /// 固定占位符（与 [placeholderBuilder] 二选一）
  final Widget? placeholder;

  /// 固定空占位（与 [emptyBuilder] 二选一）
  final Widget? emptyWidget;

  /// 固定错误占位（与 [errorWidgetBuilder] 二选一）
  final Widget? errorWidget;

  /// 是否显示内置“错误 + 重试”视图；null 表示继承主题
  final bool? showRetryButton;

  /// 内置重试按钮文案；null 表示继承主题 / 使用「重试」
  final String? retryLabel;

  void validate() {
    assert(
      !(placeholder != null && placeholderBuilder != null),
      'placeholder 与 placeholderBuilder 只能选一个（builder 优先）',
    );
    assert(
      !(emptyWidget != null && emptyBuilder != null),
      'emptyWidget 与 emptyBuilder 只能选一个（builder 优先）',
    );
    assert(
      !(errorWidget != null && errorWidgetBuilder != null),
      'errorWidget 与 errorWidgetBuilder 只能选一个（builder 优先）',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WImageSlots &&
      other.placeholderBuilder == placeholderBuilder &&
      other.emptyBuilder == emptyBuilder &&
      other.errorWidgetBuilder == errorWidgetBuilder &&
      other.progressBuilder == progressBuilder &&
      other.placeholder == placeholder &&
      other.emptyWidget == emptyWidget &&
      other.errorWidget == errorWidget &&
      other.showRetryButton == showRetryButton &&
      other.retryLabel == retryLabel;

  @override
  int get hashCode => Object.hash(
    placeholderBuilder,
    emptyBuilder,
    errorWidgetBuilder,
    progressBuilder,
    placeholder,
    emptyWidget,
    errorWidget,
    showRetryButton,
    retryLabel,
  );
}
