import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 用户体验工具类（单例）
///
/// 提供防抖、节流、延迟执行、下一帧执行与平滑滚动等常用能力。
class WUx {
  /// 单例实例
  static final WUx _instance = WUx._internal();

  /// 获取单例
  factory WUx() {
    return _instance;
  }

  /// 私有构造函数
  WUx._internal();

  /// 防抖函数
  ///
  /// 连续调用时只在停止调用 [duration] 毫秒后执行最后一次；返回值可通过
  /// [WCancellableAction.cancel] 取消尚未触发的回调（例如页面 dispose 时）。
  WCancellableAction debounce(Function() function, {int duration = 300}) {
    Timer? timer;
    return WCancellableAction._(
      invoke: () {
        timer?.cancel();
        timer = Timer(Duration(milliseconds: duration), function);
      },
      cancel: () {
        timer?.cancel();
        timer = null;
      },
    );
  }

  /// 节流函数
  ///
  /// [duration] 毫秒内只执行第一次调用；返回值可通过
  /// [WCancellableAction.cancel] 提前结束当前节流窗口。
  WCancellableAction throttle(Function() function, {int duration = 300}) {
    bool isExecuting = false;
    Timer? timer;
    return WCancellableAction._(
      invoke: () {
        if (isExecuting) return;
        isExecuting = true;
        function();
        timer = Timer(Duration(milliseconds: duration), () {
          isExecuting = false;
          timer = null;
        });
      },
      cancel: () {
        timer?.cancel();
        timer = null;
        isExecuting = false;
      },
    );
  }

  /// 延迟执行
  ///
  /// 等待 [duration] 毫秒后调用 [function]；Future 在函数执行完成后结束。
  Future<void> delay(Function() function, {int duration = 0}) async {
    await Future.delayed(Duration(milliseconds: duration));
    function();
  }

  /// 在下一帧执行 [function]
  void nextFrame(Function() function) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      function();
    });
  }

  /// 平滑滚动到指定偏移
  ///
  /// [scrollController] 需要已挂载；未挂载时会抛出异常，请先用
  /// `hasClients` 判断或使用 [smoothScrollToTop] / [smoothScrollToBottom]。
  Future<void> smoothScrollTo(
    ScrollController scrollController,
    double offset, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await scrollController.animateTo(
      offset,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  /// 平滑滚动到顶部
  ///
  /// [scrollController] 未挂载时直接返回。
  Future<void> smoothScrollToTop(
    ScrollController scrollController, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (!scrollController.hasClients) return;
    await smoothScrollTo(scrollController, 0, duration: duration);
  }

  /// 平滑滚动到底部
  ///
  /// [scrollController] 未挂载时直接返回。
  Future<void> smoothScrollToBottom(
    ScrollController scrollController, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (!scrollController.hasClients) return;
    await smoothScrollTo(
      scrollController,
      scrollController.position.maxScrollExtent,
      duration: duration,
    );
  }

  /// 常用动画曲线（供调用方复用）
  static const Curve defaultCurve = Curves.easeInOut;

  /// 常用动画时长（供调用方复用）
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// 常用快速动画时长（供调用方复用）
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// 常用慢速动画时长（供调用方复用）
  static const Duration slowDuration = Duration(milliseconds: 500);
}

/// 可取消的防抖 / 节流函数包装
///
/// 实例可直接像函数一样调用；不再需要时调用 [cancel] 取消尚未触发的回调，
/// 避免页面销毁后仍执行 `setState` 等操作。
class WCancellableAction {
  WCancellableAction._({
    required void Function() invoke,
    required void Function() cancel,
  })  : _invoke = invoke,
        _cancel = cancel;

  final void Function() _invoke;
  final void Function() _cancel;

  /// 执行包装后的函数
  void call() {
    _invoke();
  }

  /// 取消尚未触发的回调并恢复初始状态
  void cancel() {
    _cancel();
  }
}
