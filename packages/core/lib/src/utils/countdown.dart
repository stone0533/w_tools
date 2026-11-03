import 'dart:async';

import 'package:flutter/foundation.dart';

/// 倒计时工具
///
/// 基于 `Timer.periodic` 每秒回调一次；支持暂停 / 恢复 / 停止。
/// [dispose] 会停止并释放资源；dispose 后不可再 [start]（会抛 [StateError]）。
class WCountdown implements ValueListenable<int> {
  /// 总秒数（只读，由 [start] 设置）
  int get totalSeconds => _totalSeconds;

  int _totalSeconds = 0;

  /// 剩余秒数（响应式）
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0);

  /// 是否已 dispose
  bool _disposed = false;

  bool _isRunning = false;

  bool _isPaused = false;

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 是否已暂停
  bool get isPaused => _isPaused;

  /// 每秒回调，参数为剩余秒数（结束后回调 0）
  final WCountdownCallback? callback;

  /// 倒计时结束时的回调，参数固定为 0
  final WCountdownCallback? onComplete;

  /// 创建倒计时
  WCountdown({this.callback, this.onComplete});

  /// 定时器实例
  Timer? _timer;

  /// 剩余秒数（实现 [ValueListenable] 的 value）
  @override
  int get value => _remaining.value;

  @override
  void addListener(void Function() listener) => _remaining.addListener(listener);

  @override
  void removeListener(void Function() listener) => _remaining.removeListener(listener);

  /// 剩余秒数的响应式视图（每秒更新）
  ///
  /// `dispose()` 会释放它；之后再次 `start` 会重建。
  ValueListenable<int> get remaining => _remaining;

  /// 开始倒计时
  ///
  /// [second] 小于等于 0 时立即完成，并回调 `callback(0)` / `onComplete(0)`。
  void start({required int second}) {
    if (_disposed) {
      throw StateError('WCountdown 已 dispose，不能复用；请创建新实例');
    }
    _timer?.cancel();
    _timer = null;

    final total = second < 0 ? 0 : second;
    _totalSeconds = total;
    _remaining.value = total;
    _isRunning = total > 0;
    _isPaused = false;

    if (total == 0) {
      callback?.call(0);
      onComplete?.call(0);
      return;
    }

    _startTimer();
  }

  /// 暂停倒计时
  ///
  /// 暂停期间会取消内部定时器，不再每秒空转。
  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// 恢复倒计时
  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _startTimer();
  }

  /// 停止倒计时并重置剩余秒数
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    _remaining.value = 0;
  }

  /// 启动周期定时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  /// 每秒回调与完成处理
  void _tick(Timer timer) {
    _remaining.value = _remaining.value - 1;
    callback?.call(_remaining.value);

    if (_remaining.value > 0) return;

    _isRunning = false;
    _isPaused = false;
    timer.cancel();
    _timer = null;
    onComplete?.call(0);
  }

  /// 剩余秒数
  int get remainingSeconds => _remaining.value;

  /// 格式化剩余时间
  ///
  /// [type] 为 [WCountdownRemainingType.minutesSeconds] 时返回 `MM:SS`，
  /// 否则返回两位秒数 `SS`；剩余秒数不大于 0 时返回 `00` / `00:00`。
  String formatRemaining({WCountdownRemainingType type = WCountdownRemainingType.seconds}) {
    if (_remaining.value <= 0) {
      return type == WCountdownRemainingType.minutesSeconds ? '00:00' : '00';
    }

    final duration = Duration(seconds: _remaining.value);

    if (type == WCountdownRemainingType.minutesSeconds) {
      // 分:秒（MM:SS）
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } else {
      // 秒 格式
      return duration.inSeconds.toString().padLeft(2, '0');
    }
  }

  /// 销毁倒计时实例
  ///
  /// 停止计时并释放监听视图；**dispose 后不可再 `start`**（会抛 [StateError]），
  /// 需要继续使用请创建新实例。
  void dispose() {
    stop();
    _disposed = true;
    _remaining.dispose();
  }
}

/// 倒计时剩余时间的格式化类型
enum WCountdownRemainingType {
  /// 仅显示秒
  seconds,

  /// 显示分:秒
  minutesSeconds,
}

/// 倒计时回调函数类型，参数为秒数
typedef WCountdownCallback = void Function(int value);
