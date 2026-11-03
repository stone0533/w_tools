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

  /// 延迟执行
  ///
  /// [duration] 必须为非负毫秒数。等待 [duration] 毫秒后调用 [function]；
  /// Future 在函数执行完成后结束。
  Future<void> delay(Function() function, {int duration = 0}) async {
    if (duration < 0) {
      throw ArgumentError.value(duration, 'duration', 'duration 必须为非负毫秒数');
    }
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

/// 防抖器：连续调用只在停止调用 [duration] 后执行最后一次。
///
/// 实例可直接调用（`debounce()`）；页面 dispose 时调用 [cancel]。
/// 替代已弃用的 `WUx().debounce(...)`。
class WDebounce {
  WDebounce(this._action, {this.duration = const Duration(milliseconds: 300)}) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'duration 必须为非负时长');
    }
  }

  final void Function() _action;

  /// 静默时长
  final Duration duration;

  Timer? _timer;

  /// 是否还有未触发的调用
  bool get isPending => _timer?.isActive ?? false;

  /// 触发一次（重置计时）
  void call() {
    _timer?.cancel();
    _timer = Timer(duration, _action);
  }

  /// 取消尚未触发的调用
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 节流器：[duration] 内只执行第一次调用。
///
/// 替代已弃用的 `WUx().throttle(...)`。
class WThrottle {
  WThrottle(this._action, {this.duration = const Duration(milliseconds: 300)}) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'duration 必须为非负时长');
    }
  }

  final void Function() _action;

  /// 节流窗口
  final Duration duration;

  bool _active = false;
  Timer? _timer;

  /// 是否处于节流窗口内
  bool get isThrottled => _active;

  /// 触发一次（窗口内忽略）
  void call() {
    if (_active) return;
    _active = true;
    try {
      _action();
    } finally {
      // 回调抛异常时也要在窗口结束后解锁，避免永久卡死
      _timer = Timer(duration, () {
        _active = false;
        _timer = null;
      });
    }
  }

  /// 提前结束当前节流窗口
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _active = false;
  }
}

/// 可取消的防抖 / 节流函数包装
///
/// 实例可直接像函数一样调用；不再需要时调用 [cancel] 取消尚未触发的回调，
/// 避免页面销毁后仍执行 `setState` 等操作。
class WCancellableAction {
  WCancellableAction._({
    required void Function() invoke,
    required void Function() cancel,
  }) : _invoke = invoke,
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
