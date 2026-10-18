import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import 'toast.dart';

/// 提示配置与调用入口
///
/// 持有一组可复用的样式配置（时长、对齐、背景色、构建器等），
/// 并提供 `showSuccess` / `showError` / `showWarning` / `showLoading` /
/// `showText` / `showCustom` 六个入口；所有字段均可通过
/// [copy] / [copyWith] 生成副本。
///
/// 加载提示为全局唯一（跨实例共享）；所有入口在显示失败时（例如 BotToast
/// 未初始化）不会抛异常，而是通过 [onError] 上报，并返回一个空取消函数。
class WToastConfig {
  /// 提示显示时长
  ///
  /// 适用于成功 / 错误 / 警告 / 文本 / 自定义提示；加载提示固定不自动关闭。
  /// 调用参数与配置值都为 null 时回退到 2 秒。
  Duration? duration = const Duration(seconds: 2);

  /// 提示背景颜色
  ///
  /// 成功 / 错误 / 警告 / 加载 / 自定义提示中作为全屏遮罩色；
  /// [showText] 中没有遮罩，该值作为文本气泡底色。
  Color? backgroundColor = Colors.black38;

  /// 提示对齐方式
  Alignment? align = Alignment.center;

  /// 成功 / 错误 / 警告 / 加载 / 自定义提示的动画时长
  ///
  /// [showText] 使用 BotToast 文本提示自带的动画，不受该值影响。
  Duration? animationDuration = const Duration(milliseconds: 200);

  /// 自定义提示构建器（供 [showCustom] 使用）
  ///
  /// 未设置时调用 [showCustom] 会抛出 [ArgumentError]。
  Widget Function(CancelFunc cancelFunc)? toastBuilder;

  /// 提示关闭时的回调
  ///
  /// 每次提示关闭后触发一次；自定义 / 加载提示会延迟 1 毫秒回调，
  /// 文本提示由 BotToast 直接回调。
  void Function()? onClose;

  /// 自定义成功提示 Widget 构建回调
  ///
  /// - `message`：成功消息
  /// - `cancelFunc`：取消函数，可用于手动关闭提示
  Widget Function(Object? message, CancelFunc cancelFunc)? successBuilder;

  /// 自定义错误提示 Widget 构建回调
  ///
  /// - `message`：错误消息
  /// - `cancelFunc`：取消函数，可用于手动关闭提示
  Widget Function(Object? message, CancelFunc cancelFunc)? errorBuilder;

  /// 自定义警告提示 Widget 构建回调
  ///
  /// - `message`：警告消息
  /// - `cancelFunc`：取消函数，可用于手动关闭提示
  Widget Function(Object? message, CancelFunc cancelFunc)? warningBuilder;

  /// 自定义加载提示 Widget 构建回调
  ///
  /// - `message`：加载提示内容
  /// - `cancelFunc`：取消函数，可用于手动关闭加载提示
  /// - `dismissible`：调用 [showLoading] 时传入的「是否可点击关闭」，
  ///   仅供自定义 builder 使用；默认样式忽略该参数
  Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)? loadingBuilder;

  /// 提示显示失败时的回调（例如 BotToast 未初始化）
  void Function(dynamic error)? onError;

  /// 全局加载提示的取消函数
  ///
  /// 所有 [WToastConfig] 实例共享，同一时刻只保留一个 loading。
  static CancelFunc? _loadingCancelFunc;

  /// 创建配置
  WToastConfig();

  /// 创建当前配置的副本
  WToastConfig copy() => copyWith();

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
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
  ///
  /// [message] 为成功消息（为 null 时显示空文本）；[duration] / [align]
  /// 未传时使用配置值。未设置 [successBuilder] 时使用默认文本样式。
  ///
  /// 返回的取消函数可用于手动关闭该提示。
  CancelFunc showSuccess(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) =>
          successBuilder?.call(message, cancelFunc) ?? _defaultMessage(message),
      duration: duration,
      align: align,
    );
  }

  /// 显示错误提示
  ///
  /// [message] 为错误消息（为 null 时显示空文本）；[duration] / [align]
  /// 未传时使用配置值。未设置 [errorBuilder] 时使用默认文本样式。
  ///
  /// 返回的取消函数可用于手动关闭该提示。
  CancelFunc showError(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) => errorBuilder?.call(message, cancelFunc) ?? _defaultMessage(message),
      duration: duration,
      align: align,
    );
  }

  /// 显示警告提示
  ///
  /// [message] 为警告消息（为 null 时显示空文本）；[duration] / [align]
  /// 未传时使用配置值。未设置 [warningBuilder] 时使用默认文本样式。
  ///
  /// 返回的取消函数可用于手动关闭该提示。
  CancelFunc showWarning(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    return _show(
      builder: (cancelFunc) =>
          warningBuilder?.call(message, cancelFunc) ?? _defaultMessage(message),
      duration: duration,
      align: align,
    );
  }

  /// 显示纯文本提示
  ///
  /// [text] 为提示内容；[duration] / [align] 未传时使用配置值。
  /// [backgroundColor] 在文本提示中作为气泡底色使用（文本提示没有全屏遮罩），
  /// 其余样式沿用 BotToast 文本提示的默认值。
  ///
  /// 返回的取消函数可用于手动关闭该提示。
  CancelFunc showText(
    String text, {
    Duration? duration,
    Alignment? align,
  }) {
    return WToast.showText(
      text: text,
      align: align ?? this.align,
      contentColor: backgroundColor,
      duration: duration ?? this.duration,
      onClose: onClose,
      onError: onError,
    );
  }

  /// 显示自定义提示（使用 [toastBuilder]）
  ///
  /// [duration] / [align] 未传时使用配置值。
  ///
  /// 返回的取消函数可用于手动关闭该提示；未设置 [toastBuilder] 时抛出
  /// [ArgumentError]。
  CancelFunc showCustom({
    Duration? duration,
    Alignment? align,
  }) {
    final builder = toastBuilder;
    if (builder == null) {
      throw ArgumentError('toastBuilder 不能为空，请先设置 toastBuilder');
    }
    return _show(builder: builder, duration: duration, align: align);
  }

  /// 显示加载提示
  ///
  /// - [message]：加载提示内容，为空时默认样式只显示转圈
  /// - [dismissible]：是否可点击关闭，默认 false；仅供 [loadingBuilder] 判断，
  ///   默认样式忽略该参数
  ///
  /// 加载提示全局唯一：再次调用会先关闭上一个，且不会自动关闭。
  /// 未设置 [loadingBuilder] 时使用默认的转圈 + 文本样式。
  ///
  /// 返回的取消函数可用于手动关闭该提示。
  CancelFunc showLoading({
    Object? message,
    bool dismissible = false,
  }) {
    // 先关闭之前的加载提示
    _loadingCancelFunc?.call();

    _loadingCancelFunc = WToast.showCustomDialog(
      toastBuilder: (cancelFunc) =>
          loadingBuilder?.call(message, cancelFunc, dismissible) ?? _defaultLoading(message),
      align: align ?? Alignment.center,
      // 加载提示不自动关闭
      duration: null,
      backgroundColor: backgroundColor,
      onClose: onClose,
      animationDuration: animationDuration,
      onError: onError,
    );

    return _loadingCancelFunc!;
  }

  /// 关闭当前加载提示
  ///
  /// 加载提示为全局唯一，因此会关闭任意 [WToastConfig] 实例打开的加载提示。
  void hideLoading() {
    _loadingCancelFunc?.call();
    _loadingCancelFunc = null;
  }

  /// 立即关闭全部提示（文本 / 加载 / 自定义）
  ///
  /// 会同时清理所有 [WToastConfig] 实例共享的加载提示状态。
  void hideAll() {
    WToast.hideAll(onError: onError);
    _loadingCancelFunc = null;
  }

  /// 统一的提示展示入口
  ///
  /// [duration] 的优先级：调用参数 > [WToastConfig.duration] > 2 秒；
  /// [align] 的优先级：调用参数 > [WToastConfig.align] > 居中。
  /// 实际展示交由 [WToast.showCustomDialog]，因此 [backgroundColor]、
  /// [animationDuration]、[onClose]、[onError] 也会一并透传。
  CancelFunc _show({
    required Widget Function(CancelFunc cancelFunc) builder,
    Duration? duration,
    Alignment? align,
  }) {
    return WToast.showCustomDialog(
      toastBuilder: builder,
      align: align ?? this.align ?? Alignment.center,
      duration: duration ?? this.duration ?? const Duration(seconds: 2),
      backgroundColor: backgroundColor,
      onClose: onClose,
      animationDuration: animationDuration,
      onError: onError,
    );
  }

  /// 默认文本内容：白字 14 号
  Widget _defaultMessage(Object? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        message?.toString() ?? '',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  /// 默认加载内容：白色转圈 + 可选文本
  Widget _defaultLoading(Object? message) {
    final text = message?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
