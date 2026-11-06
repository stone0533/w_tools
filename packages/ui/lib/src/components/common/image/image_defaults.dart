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
    this.errorWidgetBuilder,
    this.progressBuilder,
    this.placeholder,
    this.errorWidget,
    this.showRetryButton,
    this.retryLabel,
  });

  final Widget? Function(BuildContext context, String data)? placeholderBuilder;
  final Widget? Function(BuildContext context, String data, WImageError error)? errorWidgetBuilder;
  final Widget? Function(BuildContext context, String data, WImageProgress progress)?
  progressBuilder;

  /// 固定占位符（与 [placeholderBuilder] 二选一）
  final Widget? placeholder;

  /// 固定错误占位（与 [errorWidgetBuilder] 二选一）
  final Widget? errorWidget;

  /// 是否显示内置“错误 + 重试”视图；null 表示继承主题
  final bool? showRetryButton;

  /// 内置重试按钮文案；null 表示继承主题 / 使用「重试」
  final String? retryLabel;

  bool get isEmpty =>
      placeholderBuilder == null &&
      errorWidgetBuilder == null &&
      progressBuilder == null &&
      placeholder == null &&
      errorWidget == null &&
      showRetryButton == null &&
      retryLabel == null;

  void validate() {
    assert(
      !(placeholder != null && placeholderBuilder != null),
      'placeholder 与 placeholderBuilder 只能选一个（builder 优先）',
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
      other.errorWidgetBuilder == errorWidgetBuilder &&
      other.progressBuilder == progressBuilder &&
      other.placeholder == placeholder &&
      other.errorWidget == errorWidget &&
      other.showRetryButton == showRetryButton &&
      other.retryLabel == retryLabel;

  @override
  int get hashCode => Object.hash(
    placeholderBuilder,
    errorWidgetBuilder,
    progressBuilder,
    placeholder,
    errorWidget,
    showRetryButton,
    retryLabel,
  );
}

/// 图片默认加载 UI 作用域。
///
/// 只有 [WImageSlots] 会被继承；图片颜色/圆角/边框等视觉样式仍由
/// `WImageStyle` 决定，加载行为由单张图的 `WImageLoadOptions` 决定。
///
/// 优先级：单图 `WImage.slots` 的非空字段 > 本作用域 > 内置兜底。
@immutable
class WImageTheme extends InheritedWidget {
  const WImageTheme({
    super.key,
    required this.slots,
    required super.child,
  });

  final WImageSlots slots;

  static WImageSlots? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageTheme>()?.slots;

  static WImageSlots of(BuildContext context) => maybeOf(context) ?? const WImageSlots();

  @override
  bool updateShouldNotify(WImageTheme oldWidget) => slots != oldWidget.slots;
}
