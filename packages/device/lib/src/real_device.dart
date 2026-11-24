import 'dart:convert';
import 'dart:io';

import 'shell.dart';

/// 一台物理设备（真机）。
class RealDevice {
  const RealDevice({
    required this.udid,
    required this.name,
    required this.osVersion,
    required this.state,
    required this.transport,
    required this.paired,
  });

  final String udid;
  final String name;
  final String osVersion;

  /// devicectl 能给到的最佳状态：`deviceProperties.bootState` →
  /// `connectionProperties.tunnelState` → `unknown`。
  ///
  /// 设备 unavailable 时 devicectl 常常不给 `bootState`，只给
  /// `tunnelState: unavailable`；这里统一成一句能看懂的 state，避免空串。
  final String state;

  /// `wired` / `localNetwork`；devicectl 没给时为 null（JSON 里省略）。
  final String? transport;

  final bool paired;

  /// 能尝试截图：`booted`，或 devicectl 只给了 `tunnelState=connected`。
  bool get isUsable {
    final normalized = state.toLowerCase();
    return normalized == 'booted' || normalized == 'connected';
  }

  /// 人读状态标签（只用于终端表格；`--json` 里保留 raw state）。
  static String stateLabel(String state) => switch (state.toLowerCase()) {
        'booted' => '已启动',
        'connected' => '已连接',
        'unavailable' => '不可用',
        'disconnected' => '已断开',
        'shutdown' => '已关机',
        _ => state,
      };

  Map<String, Object?> toJson() => {
        'udid': udid,
        'name': name,
        'osVersion': osVersion,
        'state': state,
        if (transport != null) 'transport': transport,
        'paired': paired,
      };
}

/// `xcrun devicectl`：管真机（模拟器走 [Simctl]）。
class Devicectl {
  Devicectl({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  Future<List<RealDevice>> devices() async {
    final out = File(
      '${Directory.systemTemp.path}/w_tools_device_devicectl_${DateTime.now().microsecondsSinceEpoch}.json',
    );
    try {
      await _shell.runOrThrow('xcrun', [
        'devicectl',
        'list',
        'devices',
        '--json-output',
        out.path,
      ]);
      return parseDevices(out.readAsStringSync());
    } finally {
      if (out.existsSync()) out.deleteSync();
    }
  }

  /// 只保留物理设备。
  ///
  /// devicectl 同时会列出模拟器（transportType=sameMachine、platform=simulator），
  /// 这里两者都过滤掉；真机是 wired（数据线）或 localNetwork（Wi-Fi）。
  /// 注意：模拟器的 platform 也常报 iOS，所以 **transport 才是可靠判据**。
  static List<RealDevice> parseDevices(String jsonText) {
    final Object? root;
    try {
      root = jsonDecode(jsonText);
    } on FormatException {
      return const [];
    }
    if (root is! Map) return const [];
    final result = root['result'];
    if (result is! Map) return const [];
    final list = result['devices'];
    if (list is! List) return const [];
    final out = <RealDevice>[];
    for (final d in list) {
      if (d is! Map) continue;
      final hw = d['hardwareProperties'];
      final props = d['deviceProperties'];
      final conn = d['connectionProperties'];
      if (hw is! Map || props is! Map) continue;
      final transport = conn is Map ? _string(conn['transportType']) : null;
      if ('${hw['platform']}' == 'simulator' || transport == 'sameMachine') continue;
      final udid = '${hw['udid'] ?? d['identifier'] ?? ''}';
      if (udid.isEmpty) continue;
      final state = _string(props['bootState']) ??
          (conn is Map ? _string(conn['tunnelState']) : null) ??
          'unknown';
      out.add(
        RealDevice(
          udid: udid,
          name: '${props['name'] ?? ''}',
          osVersion: '${props['osVersionNumber'] ?? ''}',
          state: state,
          transport: transport,
          paired: conn is Map && '${conn['pairingState']}' == 'paired',
        ),
      );
    }
    return out;
  }

  /// devicectl 的字段可能缺失；`'$value'` 拼出来会是字符串 `"null"`，这里统一成 null。
  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  /// 按 udid / 名称精确匹配，其次按名称子串；返回**全部**命中项。
  ///
  /// 调用方必须在命中多台时报歧义（exit 2），不能静默取第一台。
  static List<RealDevice> matches(List<RealDevice> all, String? query) {
    if (query == null || query.isEmpty) return all;
    final exact = all.where((d) => d.udid == query || d.name == query).toList();
    if (exact.isNotEmpty) return exact;
    final lower = query.toLowerCase();
    return all.where((d) => d.name.toLowerCase().contains(lower)).toList();
  }

  /// 真机截图（需要设备已解锁并信任）。
  Future<String> screenshot(String device, String out) async {
    File(out).parent.createSync(recursive: true);
    await _shell.runOrThrow('xcrun', [
      'devicectl',
      'device',
      'capture',
      'screenshot',
      '--device',
      device,
      '--destination',
      out,
    ]);
    return out;
  }
}
