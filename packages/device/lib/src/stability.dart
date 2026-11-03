import 'dart:async';

/// 等画面「稳定」：连续 [stableFor] 内截图不再变化。
///
/// 用一个可注入的 `grab()` 取指纹（生产里是截图 bytes 的哈希），便于单测。
class Stability {
  Stability({
    required Future<String> Function() grab,
    this.interval = const Duration(milliseconds: 300),
  }) : _grab = grab;

  final Future<String> Function() _grab;
  final Duration interval;

  /// 返回是否在 [timeout] 内稳定；超时返回 false（保留最后一次指纹）。
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final sw = Stopwatch()..start();
    String? last;
    var stableSince = Duration.zero;
    while (sw.elapsed < timeout) {
      final now = await _grab();
      if (now == last) {
        stableSince += interval;
        if (stableSince >= stableFor) return true;
      } else {
        last = now;
        stableSince = Duration.zero;
      }
      await Future<void>.delayed(interval);
    }
    return false;
  }

  /// 执行 [action] 后，看画面在 [timeout] 内是否发生变化。
  Future<bool> changedAfter(Future<void> Function() action,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final before = await _grab();
    await action();
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      final after = await _grab();
      if (after != before) return true;
      await Future<void>.delayed(interval);
    }
    return false;
  }
}
