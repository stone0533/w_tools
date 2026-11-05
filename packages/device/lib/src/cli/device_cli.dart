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

var _tempSeq = 0;

/// 内部截图/指纹临时文件；避免并发命令互相覆盖。
String _tempFile(String prefix, String ext) =>
    '${Directory.systemTemp.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_tempSeq++}.$ext';

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
  --device=<udid|名称>   指定设备（默认用已启动的 / 第一台）
  --no-cache            忽略标定缓存，强制重算（仅 iOS 模拟器 tap/drag/wait/verify）
  --scale=3             设备像素密度；仅 calibrate/tap/drag/size/wait/verify
  --timeout-ms=15000    等待超时
  --stable-ms=600       画面稳定判定窗口
  --region=x,y,w,h      只看这块区域（设备坐标）；verify/wait 用
  --real                操作物理真机（仅 list / shot；点击需要 idb，本工具不支持）
  --android             走 Android（adb）：list/shot/tap/drag/type/wait/verify 都支持，
                        坐标是**截图像素**（不需要标定，也不需要 cliclick）
  --json                输出 JSON（给脚本 / CI 用）

退出码：0 成功 · 1 verify 画面没变化（坐标可能失效） · 2 参数/配置错误 · 3 外部不可用/超时 · 4 未分类执行错误

依赖：macOS + Xcode；`brew install cliclick`；给宿主 App 开「辅助功能」+「屏幕录制」。
''';

Future<void> runDeviceCli(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.write(_usage);
    exitCode = args.isEmpty ? 2 : 0;
    return;
  }

  DeviceOptions? options;
  final simctl = Simctl();
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
        _emitCalibration(o, await _calibrate(simctl, o, force: true));
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
        _requireArgs(o, 1, 'type 需要文本');
        if (o.android) {
          final serial = await _androidSerial(o);
          await Adb().text(serial, o.positional.join(' '));
        } else {
          await Input().type(o.positional.join(' '));
        }
        _emit(o, {'text': o.positional.join(' ')}, '已输入：${o.positional.join(' ')}');
      case 'size':
        if (o.android) {
          final serial = await _androidSerial(o);
          final size = await Adb().screenSize(serial);
          _emit(o, {'width': size.$1, 'height': size.$2, 'serial': serial, 'android': true},
              '${size.$1} x ${size.$2}（像素）');
        } else {
          final udid = await _resolveUdid(simctl, o, bootedOnly: true);
          final size = await simctl.screenshotSize(udid);
          final scale = o.scale ?? Simctl.guessScale(size.$1);
          final width = size.$1 ~/ scale;
          final height = size.$2 ~/ scale;
          _emit(o, {'width': width, 'height': height, 'android': false}, '$width x $height（point）');
        }
      case 'foreground':
        if (!o.android) {
          throw StateError('foreground 只支持 --android（iOS 请用 flutter run 的日志判断）');
        }
        final serial = await _androidSerial(o);
        final pkg = Adb.requirePackage(await Adb().currentPackage(serial));
        _emit(o, {'package': pkg, 'serial': serial}, pkg);
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
        throw StateError('未知命令：${o.command}\n\n$_usage');
    }
  } on ProcessException catch (e) {
    _fail(options, '命令执行失败：${e.message}', 3);
  } on FormatException catch (e) {
    _fail(options, '参数错误：${e.message}', 2);
  } on StateError catch (e) {
    _fail(options, e.message, 2);
  } on FileSystemException catch (e) {
    _fail(options, '文件操作失败：${e.message}', 3);
  } on Exception catch (e) {
    _fail(options, '执行失败：$e', 4);
  }
}

/// 输出：`--json` 打 JSON，否则打人类可读文本。
void _emit(DeviceOptions o, Map<String, Object?> data, String human) {
  if (o.json) {
    stdout.writeln(jsonEncode({'ok': true, 'command': o.command, ...data}));
  } else {
    stdout.writeln(human);
  }
}

void _fail(DeviceOptions? o, String message, int code) {
  if (o?.json ?? false) {
    stdout.writeln(jsonEncode({'ok': false, 'command': o?.command, 'error': message}));
  } else {
    stderr.writeln(message);
  }
  exitCode = code;
}

void _requireArgs(DeviceOptions o, int count, String message) {
  if (o.positional.length < count) throw StateError(message);
}
