// 示例：Tab 型 App 的 iOS 模拟器冒烟（不是通用脚本，按自己的 App 调整）。
//
// 前置：宿主 App 有「辅助功能 + 屏幕录制」、装了 cliclick、模拟器已启动且 App 在
// 已登录的 tab 页前台。
// 依赖：在目标项目 `dev_dependencies` 加 w_tools_device；本脚本通过
// `dart run w_tools_device:device` 调用。
//
// 位置：packages/device/example/tool/device_smoke.dart；复制到消费方后按实际
// tab 数 / tab bar 高度 / 标题区调整。
//
// 用法：
//   dart run tool/device_smoke.dart [--json] [--tabs=5] [--device=<udid>]
// 退出码：0 全通过 · 1 有步骤失败

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final opts = _Opts.parse(args);
  final runner = _Runner(json: opts.json);
  try {
    await runner.run(opts);
  } on _SmokeFailure catch (e) {
    runner.fail(e.message);
  }
  exitCode = runner.exitCode;
}

class _SmokeFailure implements Exception {
  _SmokeFailure(this.message);
  final String message;
}

class _Opts {
  const _Opts({required this.device, required this.tabs, required this.json});

  final String? device;
  final int tabs;
  final bool json;

  static _Opts parse(List<String> args) {
    String? device;
    var tabs = 5;
    var json = false;
    for (final a in args) {
      if (a == '--help' || a == '-h') {
        stdout.write('dart run tool/device_smoke.dart [--device=<udid>] [--tabs=5] [--json]\n');
        exit(0);
      } else if (a == '--json') {
        json = true;
      } else if (a.startsWith('--device=')) {
        device = a.substring('--device='.length);
      } else if (a.startsWith('--tabs=')) {
        final raw = a.substring('--tabs='.length);
        final parsed = int.tryParse(raw);
        if (parsed == null) throw _SmokeFailure('--tabs 需要整数：$raw');
        tabs = parsed;
      } else {
        throw _SmokeFailure('未知参数：$a');
      }
    }
    if (tabs < 2) throw _SmokeFailure('--tabs 至少为 2');
    return _Opts(device: device, tabs: tabs, json: json);
  }
}

class _Runner {
  _Runner({required this.json});

  final bool json;
  int exitCode = 0;
  final _steps = <Map<String, Object?>>[];

  Future<void> run(_Opts o) async {
    // 1) 有已启动的模拟器
    final list = await _device(['list'], 'list');
    final devices = (list['devices'] as List).cast<Map<String, Object?>>();
    final booted = devices.where((d) => d['booted'] == true).toList();
    if (booted.isEmpty) {
      throw _SmokeFailure('没有已启动的模拟器：先 `dart run w_tools_device:device boot "<名称>"`');
    }
    final deviceLabel = o.device ?? '${booted.first['name']}';
    _ok('list', {'booted': booted.length, 'device': deviceLabel});

    // 2) 标定（坐标链路可用）
    final cal =
        await _device(['calibrate', if (o.device != null) '--device=${o.device}'], 'calibrate');
    final dev = cal['device'] as Map<String, Object?>;
    final w = (dev['width'] as num).toDouble();
    final h = (dev['height'] as num).toDouble();
    _ok('calibrate', {'device': '$w x $h'});

    // 3) 逐个 tab 点：位置按 tab 数等分，只看顶部标题区
    final region = '0,${(h * 0.04).round()},${w.round()},${(h * 0.08).round()}';
    final y = (h * 0.94).round();
    for (var i = 0; i < o.tabs; i++) {
      final x = ((i + 0.5) / o.tabs * w).round();
      // 点击偶尔会被动画/焦点打断，允许一次重试，避免 CI 抖动
      final r = await _tryVerify(
        o,
        x,
        y,
        region,
        label: 'tab $i',
        expectExit: <int>[0],
      );
      _ok('tab $i', {'x': x, 'y': y, 'changed': r['changed']});
    }

    // 4) 再点当前 tab：应当没变化（验证 verify 不是永远返回 true）
    final lastX = ((o.tabs - 1 + 0.5) / o.tabs * w).round();
    final same = await _tryVerify(
      o,
      lastX,
      y,
      region,
      label: 'same tab',
      expectExit: <int>[1],
    );
    _ok('same tab', {'changed': same['changed']});

    _finish(ok: true);
  }

  /// verify 的重试包装：失败（退出码不符合预期）就稍等再试一次。
  Future<Map<String, Object?>> _tryVerify(
    _Opts o,
    int x,
    int y,
    String region, {
    required String label,
    required List<int> expectExit,
  }) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await _device(
          ['verify', '$x', '$y', '--region=$region', if (o.device != null) '--device=${o.device}'],
          label,
          expectExit: expectExit,
        );
      } on _SmokeFailure {
        if (attempt >= 1) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  Future<Map<String, Object?>> _device(
    List<String> args,
    String label, {
    List<int> expectExit = const [0],
  }) async {
    final r = await Process.run('dart', ['run', 'w_tools_device:device', ...args, '--json']);
    final out =
        '${r.stdout}'.trim().split('\n').lastWhere((l) => l.startsWith('{'), orElse: () => '');
    Map<String, Object?> body;
    try {
      body = out.isEmpty ? {} : (jsonDecode(out) as Map).cast<String, Object?>();
    } on FormatException {
      body = {};
    }
    if (!expectExit.contains(r.exitCode)) {
      _steps.add({
        'step': label,
        'ok': false,
        'exit': r.exitCode,
        'error': body['error'] ?? '${r.stderr}'.trim()
      });
      throw _SmokeFailure('$label 失败（exit=${r.exitCode}）：${body['error'] ?? '${r.stderr}'.trim()}');
    }
    if (body['ok'] != true && r.exitCode == 0) {
      throw _SmokeFailure('$label 输出不是 ok=true');
    }
    return body;
  }

  void _ok(String step, Map<String, Object?> detail) {
    _steps.add({'step': step, 'ok': true, ...detail});
    if (!json) stdout.writeln('✔ $step ${detail.isEmpty ? '' : detail}');
  }

  void fail(String message) {
    exitCode = 1;
    _steps.add({'step': 'failed', 'ok': false, 'error': message});
    if (!json) stderr.writeln('✘ $message');
    _finish(ok: false, error: message);
  }

  void _finish({required bool ok, String? error}) {
    if (json) {
      stdout.writeln(jsonEncode({'ok': ok, if (error != null) 'error': error, 'steps': _steps}));
    } else {
      stdout.writeln(ok ? '\n设备冒烟通过 ✅' : '\n设备冒烟失败 ❌');
    }
  }
}
