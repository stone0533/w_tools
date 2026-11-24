import 'geometry.dart';

/// 平台决定坐标语义与可用命令；由 `--real` / `--android` 一次性推导，
/// 不再在 CLI 各处用两个 bool 重新拼装。
enum DevicePlatform {
  iosSimulator('ios-simulator', 'iOS 模拟器'),
  iosDevice('ios-device', 'iOS 真机'),
  android('android', 'Android');

  const DevicePlatform(this.wireName, this.label);

  /// `--json` 的 `platform` 字段。
  final String wireName;

  /// 人读文案（错误提示 / `--help`）。
  final String label;
}

/// 一条命令的契约：位置参数个数、支持的平台、允许的选项。
class _CommandSpec {
  const _CommandSpec({
    required this.arity,
    this.platforms = const {
      DevicePlatform.iosSimulator,
      DevicePlatform.iosDevice,
      DevicePlatform.android,
    },
    this.options = const {},
    this.argsHint,
  });

  final (int min, int? max) arity;
  final Set<DevicePlatform> platforms;

  /// 值选项亲和性（`--json` / `--real` / `--android` 是所有命令通用的开关）。
  final Set<String> options;

  /// 位置参数缺失时的文案；null 用通用文案。
  final String? argsHint;
}

const _simOnly = {DevicePlatform.iosSimulator};
const _androidOnly = {DevicePlatform.android};

/// 需要点击 / 截图坐标的命令：iOS 真机不支持（需要 idb / XCUITest）。
const _interactive = {DevicePlatform.iosSimulator, DevicePlatform.android};

/// 命令 → 契约。`--help` 文案与 `validate()` 都以这张表为唯一事实源。
const _commands = <String, _CommandSpec>{
  'list': _CommandSpec(arity: (0, 0)),
  'boot': _CommandSpec(arity: (0, 1), platforms: _simOnly, options: {'device'}),
  'shot': _CommandSpec(arity: (0, 1), options: {'device', 'out'}),
  'calibrate': _CommandSpec(arity: (0, 0), platforms: _simOnly, options: {'device'}),
  'tap': _CommandSpec(
    arity: (2, 2),
    platforms: _interactive,
    options: {'device', 'no-release-mouse'},
    argsHint: 'tap 需要 <x> <y>',
  ),
  'drag': _CommandSpec(
    arity: (4, 4),
    platforms: _interactive,
    options: {'device', 'no-release-mouse'},
    argsHint: 'drag 需要 <x1> <y1> <x2> <y2>',
  ),
  'size': _CommandSpec(arity: (0, 0), platforms: _interactive, options: {'device'}),
  'foreground': _CommandSpec(arity: (0, 0), platforms: _androidOnly, options: {'device'}),
  'wait': _CommandSpec(
    arity: (0, 0),
    platforms: _interactive,
    options: {'device', 'region', 'timeout-ms', 'stable-ms'},
  ),
  'verify': _CommandSpec(
    arity: (2, 2),
    platforms: _interactive,
    options: {'device', 'no-release-mouse', 'region', 'timeout-ms', 'stable-ms'},
    argsHint: 'verify 需要 <x> <y>',
  ),
};

const _universalOptions = {'json', 'real', 'android'};

const _optionLabels = {
  'device': '--device',
  'out': '--out',
  'region': '--region',
  'timeout-ms': '--timeout-ms',
  'stable-ms': '--stable-ms',
  'no-release-mouse': '--no-release-mouse',
};

/// 全部命令名（供测试与 `--help` 覆盖检查使用）。
List<String> get commandNames => _commands.keys.toList(growable: false);

/// CLI 参数（可单测；`bin/device.dart` 只负责分发）。
class DeviceOptions {
  DeviceOptions._({
    required this.command,
    required this.positional,
    required this.device,
    required this.out,
    required this.timeout,
    required this.stableFor,
    required this.region,
    required this.json,
    required this.platform,
    required this.noReleaseMouse,
    required Set<String> passed,
  }) : _passed = passed;

  final String command;
  final List<String> positional;
  final String? device;
  final String? out;

  final Duration timeout;
  final Duration stableFor;

  /// 只看这块区域；**与 tap 同坐标系**：iOS 模拟器 = 设备 point，Android = 截图像素；
  /// null = 整屏。
  final DRect? region;

  /// 输出 JSON（给脚本 / CI 用）。
  final bool json;

  final DevicePlatform platform;

  /// iOS 交互命令默认会在点击前、以及 verify 失败后自动释放宿主左键；
  /// 设 true 关闭（保留进行中的拖拽 / 完全不动鼠标时用）。
  final bool noReleaseMouse;

  /// 用户显式传入的选项名；用于拒绝「与该命令无关」的选项。
  final Set<String> _passed;

  /// 指定的设备 query（udid / serial / 名称）。
  String? get deviceQuery => device;

  bool get real => platform == DevicePlatform.iosDevice;
  bool get android => platform == DevicePlatform.android;

  static DeviceOptions parse(List<String> args) {
    String? device, out;
    var json = false;
    var real = false;
    var android = false;
    var noReleaseMouse = false;
    var timeout = const Duration(seconds: 15);
    var stableFor = const Duration(milliseconds: 600);
    DRect? region;
    final passed = <String>{};
    final rest = <String>[];

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) {
        rest.add(arg);
        continue;
      }
      final eq = arg.indexOf('=');
      final name = arg.substring(2, eq < 0 ? arg.length : eq);
      final inline = eq < 0 ? null : arg.substring(eq + 1);

      String value() {
        if (inline != null) {
          if (inline.isEmpty) throw StateError('--$name 不能为空');
          return inline;
        }
        if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
          throw StateError('--$name 需要值：--$name <value>');
        }
        return args[++i];
      }

      void flag() {
        if (inline != null) throw StateError('--$name 不接受值');
      }

      switch (name) {
        case 'json':
          flag();
          json = true;
        case 'real':
          flag();
          real = true;
        case 'android':
          flag();
          android = true;
        case 'device':
          device = value();
        case 'out':
          out = value();
        case 'region':
          region = _parseRegion(value());
        case 'timeout-ms':
          timeout = Duration(milliseconds: _positiveInt(name, value()));
        case 'stable-ms':
          stableFor = Duration(milliseconds: _positiveInt(name, value()));
        case 'no-release-mouse':
          flag();
          noReleaseMouse = true;
        default:
          throw StateError('未知选项：--$name');
      }
      passed.add(name);
    }

    if (real && android) {
      throw StateError('--real 与 --android 不能同时使用');
    }

    return DeviceOptions._(
      command: rest.isEmpty ? 'list' : rest.first,
      positional: List.unmodifiable(rest.skip(1)),
      device: device,
      out: out,
      timeout: timeout,
      stableFor: stableFor,
      region: region,
      json: json,
      platform: android
          ? DevicePlatform.android
          : real
              ? DevicePlatform.iosDevice
              : DevicePlatform.iosSimulator,
      noReleaseMouse: noReleaseMouse,
      passed: Set.unmodifiable(passed),
    );
  }

  /// 校验平台 / 命令 / 位置参数 / 选项亲和性。
  ///
  /// 未知命令不在这里报错：交给 CLI 的 default 分支带上 usage。
  void validate() {
    final spec = _commands[command];
    if (spec == null) return;

    if (!spec.platforms.contains(platform)) {
      final supported = spec.platforms.map((p) => p.label).join(' / ');
      throw StateError('$command 只支持 $supported（当前：${platform.label}）');
    }

    final (min, max) = spec.arity;
    if (positional.length < min) {
      throw StateError(spec.argsHint ?? '$command 至少需要 $min 个位置参数');
    }
    if (max != null && positional.length > max) {
      throw StateError('$command 最多接受 $max 个位置参数（多传了 ${positional.length - max} 个）');
    }
    if (command == 'shot' && positional.isNotEmpty && platform != DevicePlatform.iosDevice) {
      throw StateError('shot 的位置参数只用于 --real（真机设备名 / udid）');
    }
    if (noReleaseMouse && platform != DevicePlatform.iosSimulator) {
      throw StateError('--no-release-mouse 只用于 iOS 模拟器');
    }

    for (final name in _passed) {
      if (_universalOptions.contains(name) || spec.options.contains(name)) continue;
      if (name == 'device' && command == 'list') {
        throw StateError('list 不支持 --device；先列出设备再指定');
      }
      final allowed = [
        for (final entry in _commands.entries)
          if (entry.value.options.contains(name)) entry.key,
      ];
      throw StateError('${_optionLabels[name] ?? '--$name'} 只用于 ${allowed.join(' / ')}');
    }
  }

  static int _positiveInt(String option, String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      throw StateError('--$option 需要正整数：$value');
    }
    return parsed;
  }

  static DRect _parseRegion(String value) {
    final parts = value.split(',');
    if (parts.length != 4) {
      throw StateError('--region 需要 x,y,w,h（例如 --region=0,0,402,120）');
    }
    final v = parts.map((e) => double.tryParse(e.trim())).toList();
    if (v.any((e) => e == null || !e.isFinite)) {
      throw StateError('--region 的四个值都要是有限数字：$value');
    }
    if (v[2]! <= 0 || v[3]! <= 0) {
      throw StateError('--region 的宽高需要大于 0：$value');
    }
    return DRect(v[0]!, v[1]!, v[2]!, v[3]!);
  }
}
