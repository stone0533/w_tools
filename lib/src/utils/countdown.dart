import 'dart:async';

/// 倒计时工具类，用于管理倒计时功能
class WCountdown {
  /// 总秒数
  int countdown = 0;

  /// 剩余秒数
  int _remainingSeconds = 0;

  /// 是否已开始
  bool isRun = false;

  /// 是否已暂停
  bool isPaused = false;

  /// 回调函数，每秒调用一次
  final WCountdownCallback? callback;

  /// 完成回调，倒计时结束时调用
  final WCountdownCallback? onComplete;

  /// 构造函数
  ///
  /// @param callback 每秒调用的回调函数
  /// @param onComplete 倒计时结束时的回调函数
  WCountdown({this.callback, this.onComplete});

  /// 定时器实例
  Timer? _timer;

  /// 开始倒计时
  ///
  /// @param second 倒计时总秒数
  void start({required int second}) {
    const period = Duration(seconds: 1);
    countdown = second;
    _remainingSeconds = second;
    isRun = true;
    isPaused = false;
    _timer?.cancel();
    _timer = Timer.periodic(period, (timer) {
      if (isPaused) return;

      _remainingSeconds--;
      if (callback != null) {
        callback!(_remainingSeconds);
      }

      if (_remainingSeconds <= 0) {
        isRun = false;
        isPaused = false;
        timer.cancel();
        _timer = null;
        if (onComplete != null) {
          onComplete!(0);
        }
      }
    });
  }

  /// 暂停倒计时
  void pause() {
    isPaused = true;
  }

  /// 恢复倒计时
  void resume() {
    if (isRun && isPaused) {
      isPaused = false;
    }
  }

  /// 停止倒计时
  void stop() {
    _timer?.cancel();
    _timer = null;
    isRun = false;
    isPaused = false;
    _remainingSeconds = 0;
  }

  /// 获取剩余时间（秒）
  int get remainingSeconds => _remainingSeconds;

  /// 剩余时间格式化
  ///
  /// @param type 格式化类型，默认仅显示秒
  /// @return 格式化后的时间字符串
  String remaining({WCountdownRemainingType type = WCountdownRemainingType.s}) {
    if (_remainingSeconds <= 0) {
      return type == WCountdownRemainingType.ms ? '00:00' : '00';
    }

    final duration = Duration(seconds: _remainingSeconds);

    if (type == WCountdownRemainingType.ms) {
      // 分:秒 格式
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } else {
      // 秒 格式
      return duration.inSeconds.toString().padLeft(2, '0');
    }
  }

  /// 销毁倒计时实例
  void dispose() {
    stop();
  }
}

/// 倒计时剩余时间格式化类型枚举
enum WCountdownRemainingType {
  s, // 仅显示秒
  ms, // 显示分:秒格式
}

/// 倒计时回调函数类型
typedef WCountdownCallback = void Function(int value);
