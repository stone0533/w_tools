import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 提示的样式与回调（不可变）。
///
/// 只描述「怎么显示」，不负责「怎么调用」——调用入口是 `WToast.showSuccess` /
/// `WToast.showError` / `WToast.showWarning` / `WToast.showLoading` /
/// `WToast.showCustom` / `WToast.showText`。
///
/// 旧版 `WToastConfig` 既当样式又当门面，已弃用；需要复用一组样式时创建一个
/// `WToastStyle` 并反复传入即可。
@immutable
class WToastStyle {
  const WToastStyle({
    this.duration = const Duration(seconds: 2),
    this.align = Alignment.center,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.toastBuilder,
    this.onClose,
    this.successBuilder,
    this.errorBuilder,
    this.warningBuilder,
    this.loadingBuilder,
    this.onError,
  });

  /// 包内默认样式
  static const WToastStyle defaults = WToastStyle();

  /// 自动关闭时长（加载提示固定不自动关闭）
  final Duration duration;

  /// 对齐方式
  final Alignment align;

  /// 全屏遮罩色（文本提示中作为气泡底色）
  ///
  /// 为 null 时：遮罩用中性半透明黑，文本气泡用 `colorScheme.inverseSurface`。
  final Color? backgroundColor;

  /// 成功 / 错误 / 警告 / 加载 / 自定义提示的动画时长
  final Duration animationDuration;

  /// 自定义提示构建器（供 [WToast.showCustom] 使用）
  final Widget Function(CancelFunc cancelFunc)? toastBuilder;

  /// 提示关闭后的回调
  final void Function()? onClose;

  /// 自定义成功提示
  final Widget Function(Object? message, CancelFunc cancelFunc)? successBuilder;

  /// 自定义错误提示
  final Widget Function(Object? message, CancelFunc cancelFunc)? errorBuilder;

  /// 自定义警告提示
  final Widget Function(Object? message, CancelFunc cancelFunc)? warningBuilder;

  /// 自定义加载提示
  final Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)? loadingBuilder;

  /// 显示失败时的回调（例如 BotToast 未初始化）
  final void Function(dynamic error)? onError;

  static const Object _unset = Object();

  /// 创建副本；传 `null` 可以清空 [backgroundColor] / builder / 回调
  WToastStyle copyWith({
    Object? duration = _unset,
    Object? align = _unset,
    Object? backgroundColor = _unset,
    Object? animationDuration = _unset,
    Object? toastBuilder = _unset,
    Object? onClose = _unset,
    Object? successBuilder = _unset,
    Object? errorBuilder = _unset,
    Object? warningBuilder = _unset,
    Object? loadingBuilder = _unset,
    Object? onError = _unset,
  }) {
    return WToastStyle(
      duration: identical(duration, _unset) ? this.duration : duration as Duration,
      align: identical(align, _unset) ? this.align : align as Alignment,
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as Color?,
      animationDuration: identical(animationDuration, _unset)
          ? this.animationDuration
          : animationDuration as Duration,
      toastBuilder: identical(toastBuilder, _unset)
          ? this.toastBuilder
          : toastBuilder as Widget Function(CancelFunc)?,
      onClose: identical(onClose, _unset) ? this.onClose : onClose as void Function()?,
      successBuilder: identical(successBuilder, _unset)
          ? this.successBuilder
          : successBuilder as Widget Function(Object?, CancelFunc)?,
      errorBuilder: identical(errorBuilder, _unset)
          ? this.errorBuilder
          : errorBuilder as Widget Function(Object?, CancelFunc)?,
      warningBuilder: identical(warningBuilder, _unset)
          ? this.warningBuilder
          : warningBuilder as Widget Function(Object?, CancelFunc)?,
      loadingBuilder: identical(loadingBuilder, _unset)
          ? this.loadingBuilder
          : loadingBuilder as Widget Function(Object?, CancelFunc, bool)?,
      onError: identical(onError, _unset)
          ? this.onError
          : onError as void Function(dynamic)?,
    );
  }
}
