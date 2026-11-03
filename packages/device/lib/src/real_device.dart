import 'dart:convert';
import 'dart:io';

import 'shell.dart';

/// 一台物理设备（真机）。
class RealDevice {
  const RealDevice({
    required this.udid,
    required this.name,
    required this.osVersion,
    required this.bootState,
    required this.transport,
    required this.paired,
  });

  final String udid;
  final String name;
  final String osVersion;
  final String bootState;
  final String transport;
  final bool paired;

  bool get isBooted => bootState.toLowerCase() == 'booted';

  Map<String, Object?> toJson() => {
        'udid': udid,
        'name': name,
        'osVersion': osVersion,
        'bootState': bootState,
        'transport': transport,
        'paired': paired,
      };
}

/// `xcrun devicectl`：管真机（模拟器走 [Simctl]）。
class Devicectl {
  Devicectl({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  Future<List<RealDevice>> devices() async {
    final out = '${Directory.systemTemp.path}/w_tools_device_devicectl.json';
    await _shell.runOrThrow('xcrun', [
      'devicectl',
      'list',
      'devices',
      '--json-output',
      out,
    ]);
    return parseDevices(File(out).readAsStringSync());
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
      final transport = conn is Map ? '${conn['transportType']}' : '';
      if ('${hw['platform']}' == 'simulator' || transport == 'sameMachine') continue;
      final udid = '${hw['udid'] ?? d['identifier'] ?? ''}';
      if (udid.isEmpty) continue;
      out.add(
        RealDevice(
          udid: udid,
          name: '${props['name'] ?? ''}',
          osVersion: '${props['osVersionNumber'] ?? ''}',
          bootState: '${props['bootState'] ?? ''}',
          transport: transport,
          paired: conn is Map && '${conn['pairingState']}' == 'paired',
        ),
      );
    }
    return out;
  }

  /// 按 udid / 名称 / 名称子串挑设备。
  static RealDevice? resolve(List<RealDevice> all, String? query) {
    if (query == null || query.isEmpty) return all.firstOrNull;
    return all.where((d) => d.udid == query).firstOrNull ??
        all.where((d) => d.name == query).firstOrNull ??
        all.where((d) => d.name.toLowerCase().contains(query.toLowerCase())).firstOrNull;
  }

  /// 真机截图（需要设备已解锁并信任）。
  Future<String> screenshot(String device, String out) async {
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
