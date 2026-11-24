import 'dart:io';

import 'shell.dart';

/// 用 `cliclick` 发真实鼠标事件（`osascript click at` 点不到模拟器画面）。
class Input {
  Input({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  /// 点击。
  ///
  /// [releaseFirst] 默认先发 `du:.`（在当前位置幂等释放）：宿主左键若被上一次中断的
  /// 拖拽留在按下状态，所有点击都会被系统当成拖拽延续而静默失效。`du:.` 不会移动光标，
  /// 并且和 `c:` 串在同一次 cliclick 调用里，没有额外进程。
  Future<void> tap(double x, double y, {bool releaseFirst = true}) async {
    await _shell.runOrThrow('cliclick', [
      if (releaseFirst) 'du:.',
      'c:${x.round()},${y.round()}',
    ]);
  }

  /// 拖拽（模拟滑动）。步数越多越接近真实手势。
  ///
  /// cliclick 把 `dd:` / `dm:` / `du:` 作为**一次**调用执行；如果它在执行中失败
  /// （非零退出，或被 [ProcessShell] 超时 kill），`du:` 就不会发生，宿主左键会留在
  /// 按下状态，之后所有 `tap` 都会被系统当成拖拽延续而静默失效。所以异常路径
  /// 必须补一次幂等释放；开始前也先释放一次，清掉上一次拖拽的残留。
  Future<void> drag(
    double x1,
    double y1,
    double x2,
    double y2, {
    int steps = 6,
    bool releaseFirst = true,
  }) async {
    final args = <String>[
      if (releaseFirst) 'du:.',
      'dd:${x1.round()},${y1.round()}',
      'w:150',
    ];
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = x1 + (x2 - x1) * t;
      final y = y1 + (y2 - y1) * t;
      args
        ..add('dm:${x.round()},${y.round()}')
        ..add('w:120');
    }
    args.add('du:${x2.round()},${y2.round()}');
    try {
      await _shell.runOrThrow('cliclick', args);
    } catch (_) {
      await release();
      rethrow;
    }
  }

  /// 诊断 / 释放类命令的短超时：`swift` 或 `cliclick` 卡住时不该拖住整条命令。
  static const Duration _probeTimeout = Duration(seconds: 5);

  /// 在当前位置释放左键（`du:.`，幂等）；返回是否成功。
  Future<bool> release() async {
    try {
      final result = await _shell.runWithTimeout('cliclick', ['du:.'], _probeTimeout);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 宿主左键是否仍处于按下状态。
  ///
  /// 通过 CoreGraphics 读 HID 状态；`swift` 不可用 / 输出异常时返回 null（调用方应跳过）。
  Future<bool?> mouseButtonDown() async {
    const script =
        'import CoreGraphics; print(CGEventSource.buttonState(.hidSystemState, button: .left))';
    final result = await _runSwiftQuietly(script);
    if (result == null || result.exitCode != 0) return null;
    final text = '${result.stdout}'.trim().toLowerCase();
    return switch (text) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  Future<ProcessResult?> _runSwiftQuietly(String script) async {
    try {
      return await _shell.runWithTimeout('swift', ['-e', script], _probeTimeout);
    } catch (_) {
      return null;
    }
  }

  /// 是否装了 cliclick。
  Future<bool> available() async {
    final r = await _shell.run('which', ['cliclick']);
    return r.exitCode == 0 && '${r.stdout}'.trim().isNotEmpty;
  }
}
