import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import 'toast_style.dart';

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
  /// 文本提示的默认布局（颜色不写死，全部从当前主题取）
  ///
  /// 注意：`backgroundColor` 是提示层背景，`contentColor` 才是气泡底色。
  static const Alignment _textAlign = Alignment(0, 0.8);
  static const BorderRadius _textBorderRadius = BorderRadius.all(Radius.circular(8));
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
        backgroundColor: backgroundColor ?? Colors.black38, // style-literal-ok: 中性遮罩，Material modal barrier 同为黑色
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
  /// - [contentColor]：文本气泡底色，默认取 `colorScheme.inverseSurface`
  /// - [textStyle]：文字样式，默认取 `textTheme.bodyMedium` + `onInverseSurface`
  /// - [borderRadius] / [contentPadding]：气泡圆角与内边距
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
      // 用 customText 而不是原生 showText：原生入口不接受 Builder，
      // 拿不到 Overlay 里的 Theme，颜色只能写死。
      return BotToast.showCustomText(
        align: align ?? _textAlign,
        backgroundColor: backgroundColor ?? Colors.transparent,
        duration: duration ?? _textDuration,
        onClose: onClose,
        clickClose: clickClose,
        crossPage: crossPage,
        onlyOne: onlyOne,
        // 与 BotToast 原生 showText 一致：内容点击不额外拦截
        ignoreContentClick: true,
        toastBuilder: (_) => Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final resolved = (textStyle ?? theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: textStyle?.color ?? scheme.onInverseSurface);
            return Container(
              padding: contentPadding ?? _textPadding,
              decoration: BoxDecoration(
                color: contentColor ?? scheme.inverseSurface,
                borderRadius: borderRadius ?? _textBorderRadius,
              ),
              child: Text(text, style: resolved),
            );
          },
        ),
      );
    } catch (e) {
      onError?.call(e);
      return () {};
    }
  }

  /// 显示成功提示
  ///
  /// 未设置 [WToastStyle.successBuilder] 时使用默认文本样式（跟随主题）。
  static CancelFunc showSuccess(
    Object? message, {
    WToastStyle style = WToastStyle.defaults,
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) => Builder(
        builder: (context) =>
            style.successBuilder?.call(message, cancelFunc) ??
            _defaultMessage(context, message),
      ),
      style: style,
      duration: duration,
      align: align,
    );
  }

  /// 显示错误提示
  static CancelFunc showError(
    Object? message, {
    WToastStyle style = WToastStyle.defaults,
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) => Builder(
        builder: (context) =>
            style.errorBuilder?.call(message, cancelFunc) ??
            _defaultMessage(context, message),
      ),
      style: style,
      duration: duration,
      align: align,
    );
  }

  /// 显示警告提示
  static CancelFunc showWarning(
    Object? message, {
    WToastStyle style = WToastStyle.defaults,
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) => Builder(
        builder: (context) =>
            style.warningBuilder?.call(message, cancelFunc) ??
            _defaultMessage(context, message),
      ),
      style: style,
      duration: duration,
      align: align,
    );
  }

  /// 显示自定义提示（使用 [WToastStyle.toastBuilder] 或显式 [toastBuilder]）
  ///
  /// 两者都为空时抛出 [ArgumentError]。
  static CancelFunc showCustom({
    WToastStyle style = WToastStyle.defaults,
    Duration? duration,
    Alignment? align,
    Widget Function(CancelFunc cancelFunc)? toastBuilder,
  }) {
    final builder = toastBuilder ?? style.toastBuilder;
    if (builder == null) {
      throw ArgumentError('toastBuilder 不能为空，请先设置 toastBuilder');
    }
    return _show(builder: builder, style: style, duration: duration, align: align);
  }

  /// 显示加载提示（全局唯一，不会自动关闭）
  ///
  /// 再次调用会先关闭上一个；[dismissible] 仅供自定义 loadingBuilder 使用。
  static CancelFunc showLoading({
    Object? message,
    bool dismissible = false,
    WToastStyle style = WToastStyle.defaults,
  }) {
    _loadingCancelFunc?.call();

    _loadingCancelFunc = showCustomDialog(
      toastBuilder: (cancelFunc) => Builder(
        builder: (context) =>
            style.loadingBuilder?.call(message, cancelFunc, dismissible) ??
            _defaultLoading(context, message),
      ),
      align: style.align,
      // 加载提示不自动关闭
      duration: null,
      backgroundColor: style.backgroundColor,
      onClose: style.onClose,
      animationDuration: style.animationDuration,
      onError: style.onError,
    );

    return _loadingCancelFunc!;
  }

  /// 关闭当前加载提示（全局唯一）
  static void hideLoading() {
    _loadingCancelFunc?.call();
    _loadingCancelFunc = null;
  }

  /// 全局加载提示的取消函数（跨调用共享）
  static CancelFunc? _loadingCancelFunc;

  /// 统一的提示展示入口
  static CancelFunc _show({
    required Widget Function(CancelFunc cancelFunc) builder,
    required WToastStyle style,
    Duration? duration,
    Alignment? align,
  }) {
    return showCustomDialog(
      toastBuilder: builder,
      align: align ?? style.align,
      duration: duration ?? style.duration,
      backgroundColor: style.backgroundColor,
      onClose: style.onClose,
      animationDuration: style.animationDuration,
      onError: style.onError,
    );
  }

  /// 默认文本内容：跟随主题的正文样式 + 反色
  static Widget _defaultMessage(BuildContext context, Object? message) {
    final theme = Theme.of(context);
    final style = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: theme.colorScheme.onInverseSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(message?.toString() ?? '', style: style),
    );
  }

  /// 默认加载内容：转圈 + 可选文本，颜色跟随主题
  static Widget _defaultLoading(BuildContext context, Object? message) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onInverseSurface;
    final style = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(color: color);
    final text = message?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(text, style: style),
          ],
        ],
      ),
    );
  }

  /// 立即关闭并清理所有提示（文本 / 加载 / 自定义）
  ///
  /// 与单个提示返回的取消函数不同，本方法会移除全部提示分组，
  /// 且不播放关闭动画。
  static void hideAll({void Function(dynamic error)? onError}) {
    _loadingCancelFunc = null;
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
