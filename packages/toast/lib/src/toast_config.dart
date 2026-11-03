import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import 'toast.dart';
import 'toast_style.dart';

/// 旧的「样式 + 门面」混合入口。
///
/// 1.2 起拆成两半：
/// - 样式用 [WToastStyle]（不可变、可 `copyWith`）；
/// - 调用用 [WToast] 的静态方法（`showSuccess` / `showError` / ...）。
///
/// 本类保留为兼容门面：字段仍可变，`showXxx` 内部转成 [WToastStyle] 后调用
/// [WToast]。2.0 移除。
@Deprecated('1.2 起用 WToastStyle + WToast.showXxx；2.0 移除')
class WToastConfig {
  WToastConfig();

  /// 提示显示时长（加载提示固定不自动关闭）
  Duration? duration = const Duration(seconds: 2);

  /// 全屏遮罩色；文本提示中作为气泡底色
  ///
  /// 为 null 时：遮罩用中性半透明黑，文本气泡用 `colorScheme.inverseSurface`。
  Color? backgroundColor;

  /// 对齐方式
  Alignment? align = Alignment.center;

  /// 成功 / 错误 / 警告 / 加载 / 自定义提示的动画时长
  Duration? animationDuration = const Duration(milliseconds: 200);

  /// 自定义提示构建器（供 [showCustom] 使用）
  Widget Function(CancelFunc cancelFunc)? toastBuilder;

  /// 提示关闭后的回调
  void Function()? onClose;

  /// 自定义成功提示
  Widget Function(Object? message, CancelFunc cancelFunc)? successBuilder;

  /// 自定义错误提示
  Widget Function(Object? message, CancelFunc cancelFunc)? errorBuilder;

  /// 自定义警告提示
  Widget Function(Object? message, CancelFunc cancelFunc)? warningBuilder;

  /// 自定义加载提示
  Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)? loadingBuilder;

  /// 显示失败时的回调
  void Function(dynamic error)? onError;

  /// 转成不可变样式
  WToastStyle get style => WToastStyle(
    duration: duration ?? const Duration(seconds: 2),
    align: align ?? Alignment.center,
    backgroundColor: backgroundColor,
    animationDuration: animationDuration ?? const Duration(milliseconds: 200),
    toastBuilder: toastBuilder,
    onClose: onClose,
    successBuilder: successBuilder,
    errorBuilder: errorBuilder,
    warningBuilder: warningBuilder,
    loadingBuilder: loadingBuilder,
    onError: onError,
  );

  /// 创建副本
  WToastConfig copy() => copyWith();

  /// 创建副本；参数为 null 表示沿用原值
  WToastConfig copyWith({
    Duration? duration,
    Color? backgroundColor,
    Alignment? align,
    Duration? animationDuration,
    Widget Function(CancelFunc cancelFunc)? toastBuilder,
    void Function()? onClose,
    Widget Function(Object? message, CancelFunc cancelFunc)? successBuilder,
    Widget Function(Object? message, CancelFunc cancelFunc)? errorBuilder,
    Widget Function(Object? message, CancelFunc cancelFunc)? warningBuilder,
    Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)? loadingBuilder,
    void Function(dynamic error)? onError,
  }) {
    return WToastConfig()
      ..duration = duration ?? this.duration
      ..backgroundColor = backgroundColor ?? this.backgroundColor
      ..align = align ?? this.align
      ..animationDuration = animationDuration ?? this.animationDuration
      ..toastBuilder = toastBuilder ?? this.toastBuilder
      ..onClose = onClose ?? this.onClose
      ..successBuilder = successBuilder ?? this.successBuilder
      ..errorBuilder = errorBuilder ?? this.errorBuilder
      ..warningBuilder = warningBuilder ?? this.warningBuilder
      ..loadingBuilder = loadingBuilder ?? this.loadingBuilder
      ..onError = onError ?? this.onError;
  }

  /// 显示成功提示
  CancelFunc showSuccess(Object? message, {Duration? duration, Alignment? align}) {
    return WToast.showSuccess(message, style: style, duration: duration, align: align);
  }

  /// 显示错误提示
  CancelFunc showError(Object? message, {Duration? duration, Alignment? align}) {
    return WToast.showError(message, style: style, duration: duration, align: align);
  }

  /// 显示警告提示
  CancelFunc showWarning(Object? message, {Duration? duration, Alignment? align}) {
    return WToast.showWarning(message, style: style, duration: duration, align: align);
  }

  /// 显示纯文本提示（[backgroundColor] 作为气泡底色）
  CancelFunc showText(String text, {Duration? duration, Alignment? align}) {
    return WToast.showText(
      text: text,
      align: align ?? this.align,
      contentColor: backgroundColor,
      duration: duration ?? this.duration,
      onClose: onClose,
      onError: onError,
    );
  }

  /// 显示自定义提示
  CancelFunc showCustom({Duration? duration, Alignment? align}) {
    return WToast.showCustom(
      style: style,
      duration: duration,
      align: align,
      toastBuilder: toastBuilder,
    );
  }

  /// 显示加载提示（全局唯一）
  CancelFunc showLoading({Object? message, bool dismissible = false}) {
    return WToast.showLoading(message: message, dismissible: dismissible, style: style);
  }

  /// 关闭当前加载提示
  void hideLoading() => WToast.hideLoading();

  /// 立即关闭全部提示
  void hideAll() => WToast.hideAll(onError: onError);
}
