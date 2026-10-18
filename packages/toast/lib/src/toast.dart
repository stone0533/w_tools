import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// BotToast 的轻量封装
///
/// 提供三类入口：
/// - [showCustomDialog]：自定义内容提示，成功 / 错误 / 警告 / 加载均基于此
/// - [showText]：BotToast 原生文本提示
/// - [hideAll]：一次性清理全部提示
///
/// 所有入口在显示失败时（例如 BotToast 未初始化）不会抛异常：显示类入口
/// 通过 `onError` 上报并返回一个空取消函数，调用方无需判空；[hideAll]
/// 同样通过 `onError` 上报。
class WToast {
  /// 文本提示的默认样式（与 BotToast `TextOption` 的默认值保持一致）
  ///
  /// 注意：`backgroundColor` 是提示层背景，`contentColor` 才是气泡底色。
  static const Alignment _textAlign = Alignment(0, 0.8);
  static const Color _textBackgroundColor = Colors.transparent;
  static const Color _textContentColor = Colors.black54;
  static const BorderRadius _textBorderRadius = BorderRadius.all(Radius.circular(8));
  static const TextStyle _textStyle = TextStyle(fontSize: 17, color: Colors.white);
  static const EdgeInsets _textPadding = EdgeInsets.only(left: 14, right: 14, top: 5, bottom: 7);
  static const Duration _textDuration = Duration(seconds: 2);

  /// 显示自定义对话框（直接使用 BotToast 原生方法）
  ///
  /// - [toastBuilder]：构建对话框内容的回调函数
  /// - [align]：对话框对齐方式，默认居中
  /// - [onClose]：对话框关闭时的回调函数
  /// - [duration]：对话框显示时长；为 null 时不自动关闭
  /// - [backgroundColor]：全屏遮罩背景色，默认半透明黑色
  /// - [animationDuration]：进出场动画时长，默认 200 毫秒
  /// - [onError]：显示失败或内容构建失败时的回调函数
  ///
  /// [toastBuilder] 在后续 build 阶段执行，其抛出的异常同样会交给 [onError]。
  /// 返回值用于关闭对话框；即使显示失败也会返回一个空函数。
  static CancelFunc showCustomDialog({
    required Widget Function(CancelFunc cancelFunc) toastBuilder,
    Alignment? align,
    void Function()? onClose,
    Duration? duration,
    Color? backgroundColor,
    Duration? animationDuration = const Duration(milliseconds: 200),
    void Function(dynamic error)? onError,
  }) {
    try {
      return BotToast.showCustomLoading(
        toastBuilder: _guardBuilder(toastBuilder, onError),
        align: align ?? Alignment.center,
        onClose: () {
          // BotToast 在移除提示的过程中同步触发 onClose，此时组件树仍处于
          // 销毁流程中。延后 1 毫秒再回调，避免用户在回调里执行 setState /
          // 导航等操作时触发框架断言。
          Future<void>.delayed(const Duration(milliseconds: 1), () {
            onClose?.call();
          });
        },
        backgroundColor: backgroundColor ?? Colors.black38,
        duration: duration,
        animationDuration: animationDuration,
      );
    } catch (e) {
      onError?.call(e);
      return () {};
    }
  }

  /// 显示纯文本提示
  ///
  /// - [text]：提示内容
  /// - [align]：提示位置，默认位于屏幕下方（`Alignment(0, 0.8)`）
  /// - [backgroundColor]：提示层背景色，默认透明
  /// - [contentColor]：文本气泡底色，默认 `Colors.black54`
  /// - [borderRadius] / [textStyle] / [contentPadding]：气泡圆角、文字样式、
  ///   内边距，未指定时沿用 BotToast 默认值
  /// - [duration]：显示时长，默认 2 秒
  /// - [onClose]：提示关闭后的回调
  /// - [clickClose]：为 true 时点击提示区域即可关闭，默认 false
  /// - [crossPage]：为 true 时切换页面后提示仍然保留，默认 true
  /// - [onlyOne]：为 true 时同一时刻只显示一条文本提示，默认 true
  /// - [onError]：显示失败时的回调
  ///
  /// 返回值用于关闭提示；即使显示失败也会返回一个空函数。
  static CancelFunc showText({
    required String text,
    AlignmentGeometry? align,
    Color? backgroundColor,
    Color? contentColor,
    BorderRadiusGeometry? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? contentPadding,
    Duration? duration,
    void Function()? onClose,
    bool clickClose = false,
    bool crossPage = true,
    bool onlyOne = true,
    void Function(dynamic error)? onError,
  }) {
    try {
      return BotToast.showText(
        text: text,
        align: align ?? _textAlign,
        backgroundColor: backgroundColor ?? _textBackgroundColor,
        contentColor: contentColor ?? _textContentColor,
        borderRadius: borderRadius ?? _textBorderRadius,
        textStyle: textStyle ?? _textStyle,
        contentPadding: contentPadding ?? _textPadding,
        duration: duration ?? _textDuration,
        onClose: onClose,
        clickClose: clickClose,
        crossPage: crossPage,
        onlyOne: onlyOne,
      );
    } catch (e) {
      onError?.call(e);
      return () {};
    }
  }

  /// 立即关闭并清理所有提示（文本 / 加载 / 自定义）
  ///
  /// 与单个提示返回的取消函数不同，本方法会移除全部提示分组，
  /// 且不播放关闭动画。
  static void hideAll({void Function(dynamic error)? onError}) {
    try {
      BotToast.cleanAll();
    } catch (e) {
      onError?.call(e);
    }
  }

  /// 包装 builder：BotToast 在后续 build 阶段才执行 [toastBuilder]，
  /// 其抛出的异常不会被 showCustomDialog 的 try-catch 捕获，这里单独兜底；
  /// 构建失败时上报 [onError] 并返回空 Widget。
  static Widget Function(CancelFunc cancelFunc) _guardBuilder(
    Widget Function(CancelFunc cancelFunc) toastBuilder,
    void Function(dynamic error)? onError,
  ) {
    return (cancelFunc) {
      try {
        return toastBuilder(cancelFunc);
      } catch (e) {
        onError?.call(e);
        return const SizedBox.shrink();
      }
    };
  }
}
