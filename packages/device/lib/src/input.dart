import 'shell.dart';

/// 用 `cliclick` 发真实鼠标事件（`osascript click at` 点不到模拟器画面）。
class Input {
  Input({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  Future<void> tap(double x, double y) async {
    await _shell.runOrThrow('cliclick', ['c:${x.round()},${y.round()}']);
  }

  /// 拖拽（模拟滑动）。步数越多越接近真实手势。
  Future<void> drag(
    double x1,
    double y1,
    double x2,
    double y2, {
    int steps = 6,
  }) async {
    final args = <String>[
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
    await _shell.runOrThrow('cliclick', args);
  }

  /// 输入文本（需要先点中输入框）。
  Future<void> type(String text) async {
    await _shell.runOrThrow('cliclick', ['t:$text']);
  }

  /// 是否装了 cliclick。
  Future<bool> available() async {
    final r = await _shell.run('which', ['cliclick']);
    return r.exitCode == 0 && '${r.stdout}'.trim().isNotEmpty;
  }
}
