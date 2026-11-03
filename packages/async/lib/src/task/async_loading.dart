/// 并发操作的加载状态合并器（显式 opt-in）。
///
/// 把同一个实例传给多个 [WAsync] 调用，活动数 `0→1` 时回调 [onStart]，
/// `1→0` 时回调 [onEnd]。不传就完全不跟踪加载状态——不像旧版配置对象
/// 那样“共享即隐式合并”，合并必须是显式的。
class WAsyncLoading {
  /// [onStart] / [onEnd] 只会被调用一次一对，自身抛错会被忽略。
  WAsyncLoading({this.onStart, this.onEnd});

  /// 活动数从 0 变 1 时调用
  final void Function()? onStart;

  /// 活动数从 1 变 0 时调用
  final void Function()? onEnd;

  int _active = 0;

  /// 当前是否有操作在执行
  bool get isLoading => _active > 0;

  void begin() {
    if (_active == 0) {
      _active = 1;
      _safe(onStart);
    } else {
      _active++;
    }
  }

  void end() {
    if (_active == 0) return;
    _active--;
    if (_active == 0) _safe(onEnd);
  }

  static void _safe(void Function()? callback) {
    try {
      callback?.call();
    } catch (_) {
      // 加载回调异常不影响业务操作
    }
  }
}
