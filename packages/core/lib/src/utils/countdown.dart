import 'dart:async';

/// 倒计时工具
///
/// 基于 `Timer.periodic` 每秒回调一次；支持暂停 / 恢复 / 停止。
/// [dispose] 等同于 [stop]，实例仍可再次 [start] 复用。
class WCountdown {
  /// 总秒数（只读，由 [start] 设置）
  int get totalSeconds => _totalSeconds;

  int _totalSeconds = 0;

  /// 剩余秒数
  int _remainingSeconds = 0;

  /// 是否正在运行
  bool isRunning = false;

  /// 是否已暂停
  bool isPaused = false;

  /// 每秒回调，参数为剩余秒数（结束后回调 0）
  final WCountdownCallback? callback;

  /// 倒计时结束时的回调，参数固定为 0
  final WCountdownCallback? onComplete;

  /// 创建倒计时
  WCountdown({this.callback, this.onComplete});

  /// 定时器实例
  Timer? _timer;

  /// 开始倒计时
  ///
  /// [second] 小于等于 0 时立即完成，并回调 `callback(0)` / `onComplete(0)`。
  void start({required int second}) {
    _timer?.cancel();
    _timer = null;

    final total = second < 0 ? 0 : second;
    _totalSeconds = total;
    _remainingSeconds = total;
    isRunning = total > 0;
    isPaused = false;

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
    if (!isRunning || isPaused) return;
    isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// 恢复倒计时
  void resume() {
    if (!isRunning || !isPaused) return;
    isPaused = false;
    _startTimer();
  }

  /// 停止倒计时并重置剩余秒数
  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    isPaused = false;
    _remainingSeconds = 0;
  }

  /// 启动周期定时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  /// 每秒回调与完成处理
  void _tick(Timer timer) {
    _remainingSeconds--;
    callback?.call(_remainingSeconds);

    if (_remainingSeconds > 0) return;

    isRunning = false;
    isPaused = false;
    timer.cancel();
    _timer = null;
    onComplete?.call(0);
  }

  /// 剩余秒数
  int get remainingSeconds => _remainingSeconds;

  /// 格式化剩余时间
  ///
  /// [type] 为 [WCountdownRemainingType.minutesSeconds] 时返回 `MM:SS`，
  /// 否则返回两位秒数 `SS`；剩余秒数不大于 0 时返回 `00` / `00:00`。
  String formatRemaining({WCountdownRemainingType type = WCountdownRemainingType.seconds}) {
    if (_remainingSeconds <= 0) {
      return type == WCountdownRemainingType.minutesSeconds ? '00:00' : '00';
    }

    final duration = Duration(seconds: _remainingSeconds);

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
  /// 等同于 [stop]；实例仍可再次 [start] 复用。
  void dispose() {
    stop();
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
