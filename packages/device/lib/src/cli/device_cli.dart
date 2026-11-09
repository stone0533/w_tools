import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../android.dart';
import '../calibration.dart';
import '../calibration_store.dart';
import '../device_hub.dart';
import '../geometry.dart';
import '../input.dart';
import '../options.dart';
import '../real_device.dart';
import '../simctl.dart';
import '../stability.dart';

part 'device_ios_commands.dart';
part 'device_android_commands.dart';

/// 与 pubspec 版本保持一致；`test/docs_test.dart` 会守住。
const String deviceCliVersion = '0.3.0';

var _tempSeq = 0;

/// 内部截图/指纹临时文件；避免并发命令互相覆盖。
String _tempFile(String prefix, String ext) =>
    '${Directory.systemTemp.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_tempSeq++}.$ext';

/// 已按退出码分类的 CLI 错误；人类可读消息 + 可选 usage。
class DeviceCliException implements Exception {
  const DeviceCliException(this.message, this.exitCode, {this.showUsage = false});

  final String message;
  final int exitCode;
  final bool showUsage;

  @override
  String toString() => message;
}

/// 可注入的 CLI 依赖：测试可在进程内替换设备/输出，不依赖 PATH 假命令。
class DeviceCliDeps {
  DeviceCliDeps({
    Simctl Function()? simctl,
    Adb Function()? adb,
    Devicectl Function()? devicectl,
    DeviceHub Function()? deviceHub,
    Input Function()? input,
    CalibrationStore Function()? calibrationStore,
    void Function(String)? write,
    void Function(String)? writeError,
  })  : _simctl = simctl ?? (() => Simctl()),
        _adb = adb ?? (() => Adb()),
        _devicectl = devicectl ?? (() => Devicectl()),
        _deviceHub = deviceHub ?? (() => DeviceHub()),
        _input = input ?? (() => Input()),
        _calibrationStore = calibrationStore ?? (() => CalibrationStore()),
        _write = write ?? stdout.write,
        _writeError = writeError ?? stderr.write;

  final Simctl Function() _simctl;
  final Adb Function() _adb;
  final Devicectl Function() _devicectl;
  final DeviceHub Function() _deviceHub;
  final Input Function() _input;
  final CalibrationStore Function() _calibrationStore;
  final void Function(String) _write;
  final void Function(String) _writeError;

  Simctl simctl() => _simctl();
  Adb adb() => _adb();
  Devicectl devicectl() => _devicectl();
  DeviceHub deviceHub() => _deviceHub();
  Input input() => _input();
  CalibrationStore calibrationStore() => _calibrationStore();
  void write(String text) => _write(text);
  void writeError(String text) => _writeError(text);
}

DeviceCliDeps _deps = DeviceCliDeps();

const _usage = '''
w_tools_device —— iOS/Android 模拟器；Android 真机 adb；iOS 真机 list/shot

用法：
  dart run w_tools_device:device list                 # 列出模拟器（udid / 名称 / 状态）
  dart run w_tools_device:device list --real          # 列出物理真机（devicectl）
  dart run w_tools_device:device list --android       # 列出 Android 设备（adb）
  dart run w_tools_device:device boot <名称|udid>      # 启动并等待可用（省略时用第一台/已启动）
  dart run w_tools_device:device shot --out=<path>    # 截设备屏（也支持 --out <path>；--real 走 devicectl）
  dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
  dart run w_tools_device:device tap <x> <y>          # 用设备坐标点（自动换算成屏幕坐标）
  dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
  dart run w_tools_device:device type <text>          # 实验：输入文本（先点中输入框）
  dart run w_tools_device:device size                 # 设备分辨率（iOS=point，Android=像素）
  dart run w_tools_device:device foreground --android # 前台 App 包名（仅 Android）
  dart run w_tools_device:device wait                 # 等画面稳定
  dart run w_tools_device:device verify <x> <y>       # 点一下并确认画面有变化（坐标自检）

可选：
  --device=<udid|名称>   指定设备（默认用已启动的 / 第一台；也支持 --device <值>）
  --no-cache            忽略标定缓存，强制重算（仅 iOS 模拟器 tap/drag/verify）
  --scale=3             设备像素密度；仅 iOS 模拟器 calibrate/tap/drag/size/wait/verify
  --timeout-ms=15000    等待超时；wait 一次，verify 为点击前+后的总预算
  --stable-ms=600       画面稳定判定窗口；仅 wait / verify
  --region=x,y,w,h      只看这块区域；iOS 模拟器=设备坐标(point)，Android=截图像素；verify/wait 用
  --real                操作物理真机（仅 list / shot；点击需要 idb，本工具不支持）
  --android             走 Android（adb）：list/shot/tap/drag/type/size/wait/verify/foreground 都支持，
                        坐标是**截图像素**（不需要标定，也不需要 cliclick）
  --json                输出 JSON（schemaVersion=1，给脚本 / CI 用）
  --version             打印版本
  --help                打印本帮助

退出码：0 成功 · 1 verify 画面没变化（坐标可能失效） · 2 参数/配置错误 · 3 外部不可用/超时 · 4 未分类执行错误

依赖：macOS + Xcode；`brew install cliclick`；给宿主 App 开「辅助功能」+「屏幕录制」。
''';

Future<void> runDeviceCli(List<String> args, {DeviceCliDeps? deps}) async {
  final previous = _deps;
  if (deps != null) _deps = deps;
  try {
    await _runDeviceCli(args);
  } finally {
    _deps = previous;
  }
}

Future<void> _runDeviceCli(List<String> args) async {
  final wantsJson = args.contains('--json');
  if (args.isEmpty) {
    _deps.write(_usage);
    exitCode = 2;
    return;
  }
  if (args.first == '-h' || args.first == '--help') {
    _deps.write(_usage);
    exitCode = 0;
    return;
  }
  if (args.length == 1 && args.first == '--version') {
    _deps.write('w_tools_device $deviceCliVersion\n');
    return;
  }

  DeviceOptions? options;
  final simctl = _deps.simctl();
  try {
    options = DeviceOptions.parse(args);
    options.validate();
    final o = options;
    switch (o.command) {
      case 'list':
        if (o.android) {
          await _androidList(o);
        } else {
          await _list(o, simctl);
        }
      case 'boot':
        await _boot(simctl, o);
      case 'shot':
        if (o.android) {
          await _androidShot(o);
        } else {
          await _shot(simctl, o);
        }
      case 'calibrate':
        final udid = await _resolveUdid(simctl, o, bootedOnly: true);
        _emitCalibration(o, await _calibrate(simctl, o, udid, force: true), deviceId: udid);
      case 'tap':
        if (o.android) {
          await _androidTap(o);
        } else {
          await _tap(simctl, o);
        }
      case 'drag':
        if (o.android) {
          await _androidDrag(o);
        } else {
          await _drag(simctl, o);
        }
      case 'type':
        if (o.android) {
          final serial = await _androidSerial(o);
          await _deps.adb().text(serial, o.positional.join(' '));
        } else {
          await _requireCliclick();
          await _deps.input().type(o.positional.join(' '));
        }
        _emit(o, {'text': o.positional.join(' ')}, '已输入：${o.positional.join(' ')}');
      case 'size':
        if (o.android) {
          final serial = await _androidSerial(o);
          final size = await _deps.adb().screenSize(serial);
          _emit(
            o,
            {
              'width': size.$1,
              'height': size.$2,
              'serial': serial,
              'deviceId': serial,
              'android': true,
            },
            '${size.$1} x ${size.$2}（像素）',
          );
        } else {
          final udid = await _resolveUdid(simctl, o, bootedOnly: true);
          final size = await simctl.screenshotSize(udid);
          final scale = o.scale ?? Simctl.guessScale(size.$1);
          final width = size.$1 ~/ scale;
          final height = size.$2 ~/ scale;
          _emit(
            o,
            {
              'width': width,
              'height': height,
              'deviceId': udid,
              'android': false,
            },
            '$width x $height（point）',
          );
        }
      case 'foreground':
        if (!o.android) {
          throw const DeviceCliException('foreground 只支持 --android（iOS 请用 flutter run 的日志判断）', 2);
        }
        final serial = await _androidSerial(o);
        final pkg = await _deps.adb().currentPackage(serial);
        if (pkg.isEmpty) {
          throw const DeviceCliException(
            '取不到 Android 前台包名（设备可能锁屏 / 无 Activity）',
            3,
          );
        }
        _emit(o, {'package': pkg, 'serial': serial, 'deviceId': serial}, pkg);
      case 'wait':
        if (o.android) {
          await _androidWait(o);
        } else {
          await _wait(simctl, o);
        }
      case 'verify':
        if (o.android) {
          await _androidVerify(o);
        } else {
          await _verify(simctl, o);
        }
      default:
        throw DeviceCliException(
          '未知命令：${o.command}',
          2,
          showUsage: true,
        );
    }
  } on DeviceCliException catch (e) {
    _fail(options, e.message, e.exitCode, jsonRequested: wantsJson, usage: e.showUsage);
  } on VerificationTimeout catch (e) {
    _fail(options, e.message, 3, jsonRequested: wantsJson);
  } on ProcessException catch (e) {
    _fail(options, '命令执行失败：${e.message}', 3, jsonRequested: wantsJson);
  } on FormatException catch (e) {
    _fail(options, '参数错误：${e.message}', 2, jsonRequested: wantsJson);
  } on StateError catch (e) {
    _fail(options, e.message, 2, jsonRequested: wantsJson);
  } on FileSystemException catch (e) {
    _fail(options, '文件操作失败：${e.message}', 3, jsonRequested: wantsJson);
  } on Exception catch (e) {
    _fail(options, '执行失败：$e', 4, jsonRequested: wantsJson);
  }
}

/// iOS 模拟器点击依赖 cliclick；提前给出可执行的安装提示，而不是让 ProcessException 裸奔。
Future<void> _requireCliclick() async {
  if (!await _deps.input().available()) {
    throw const DeviceCliException('找不到 cliclick；先 brew install cliclick（iOS 模拟器点击依赖它）', 3);
  }
}

String _platformOf(DeviceOptions o) {
  if (o.android) return 'android';
  if (o.real) return 'ios-device';
  return 'ios-simulator';
}

/// 输出：`--json` 打 JSON，否则打人类可读文本。
void _emit(DeviceOptions o, Map<String, Object?> data, String human) {
  if (o.json) {
    _deps.write(
      '${jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'ok': true,
            'command': o.command,
            'platform': _platformOf(o),
            ...data,
          })}\n',
    );
  } else {
    _deps.write('$human\n');
  }
}

void _fail(
  DeviceOptions? o,
  String message,
  int code, {
  bool jsonRequested = false,
  bool usage = false,
}) {
  final asJson = o?.json ?? jsonRequested;
  if (asJson) {
    _deps.write(
      '${jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'ok': false,
            'command': o?.command,
            'error': message,
          })}\n',
    );
  } else {
    _deps.writeError(usage ? '$message\n\n$_usage' : '$message\n');
  }
  exitCode = code;
}
