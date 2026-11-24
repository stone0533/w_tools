import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../android.dart';
import '../calibration.dart';
import '../device_hub.dart';
import '../geometry.dart';
import '../input.dart';
import '../options.dart';
import '../real_device.dart';
import '../simctl.dart';
import '../stability.dart';
import '../temp.dart';

part 'device_android_commands.dart';
part 'device_ios_commands.dart';

/// 与 pubspec 版本保持一致；`test/docs_test.dart` 会守住。
const String deviceCliVersion = '0.4.0';

/// `--json` 的 schema 版本。2：删掉 `real` / drag 的 legacy `from`/`to`，
/// 错误 JSON 也带 `platform`。
const int deviceJsonSchemaVersion = 2;

/// 已按退出码分类的 CLI 错误；人类可读消息 + 可选 usage。
class DeviceCliException implements Exception {
  const DeviceCliException(this.message, this.exitCode, {this.showUsage = false});

  final String message;
  final int exitCode;
  final bool showUsage;

  @override
  String toString() => message;
}

/// CLI 依赖：显式传入实例（测试直接注入）。
///
/// 没有全局可变状态，也没有「工厂闭包」这层间接 —— 需要替换哪个外部命令，
/// 就给那个类传一个假 [Shell]。
class DeviceRuntime {
  DeviceRuntime({
    Simctl? simctl,
    Adb? adb,
    Devicectl? devicectl,
    DeviceHub? deviceHub,
    Input? input,
    void Function(String)? write,
    void Function(String)? writeError,
  })  : simctl = simctl ?? Simctl(),
        adb = adb ?? Adb(),
        devicectl = devicectl ?? Devicectl(),
        deviceHub = deviceHub ?? DeviceHub(),
        input = input ?? Input(),
        _write = write ?? stdout.write,
        _writeError = writeError ?? stderr.write;

  final Simctl simctl;
  final Adb adb;
  final Devicectl devicectl;
  final DeviceHub deviceHub;
  final Input input;
  final void Function(String) _write;
  final void Function(String) _writeError;

  void write(String text) => _write(text);
  void writeError(String text) => _writeError(text);
}

const _usage = '''
w_tools_device —— iOS 模拟器 / Android（模拟器 + 真机）可交互；iOS 真机 list/shot

用法：
  dart run w_tools_device:device list                 # 列出模拟器（udid / 名称 / 状态）
  dart run w_tools_device:device list --real          # 列出物理真机（devicectl）
  dart run w_tools_device:device list --android       # 列出 Android 设备（adb）
  dart run w_tools_device:device boot <名称|udid>      # 启动并等待可用（省略时用唯一匹配的模拟器）
  dart run w_tools_device:device shot --out=<path>    # 截设备屏（--real 走 devicectl）
  dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标（每次现算）
  dart run w_tools_device:device tap <x> <y>          # 用设备坐标点（自动换算成屏幕坐标）
  dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
  dart run w_tools_device:device size                 # 分辨率（iOS=point + 截图 px；Android=像素）
  dart run w_tools_device:device foreground --android # 前台 App 包名（仅 Android）
  dart run w_tools_device:device wait                 # 等画面稳定
  dart run w_tools_device:device verify <x> <y>       # 点一下并确认画面真的变了（坐标自检）

可选：
  --device=<udid|名称>   指定设备（默认用唯一已启动的；多台命中会报错，不会静默取第一台）
  --timeout-ms=15000    等待超时；wait 一次，verify 为点击前+后的总预算
  --stable-ms=600       画面稳定判定窗口；仅 wait / verify
  --region=x,y,w,h      只看这块区域（与 tap 同坐标系：iOS=设备 point，Android=截图像素）；
                        verify/wait 用
  --no-release-mouse    iOS 交互命令默认先释放宿主左键（du:.）再点，verify 失败时也会
                        自动释放；需要保留进行中的拖拽 / 完全不动鼠标时关闭
                        （tap / drag / verify）
  --real                操作物理真机（仅 list / shot；点击需要 idb，本工具不支持）
  --android             走 Android（adb）：list/shot/tap/drag/size/wait/verify/foreground，
                        坐标是**截图像素**（不需要标定，也不需要 cliclick）
  --json                输出 JSON（schemaVersion=$deviceJsonSchemaVersion，给脚本 / CI 用）
  --version             打印版本
  --help                打印本帮助

退出码：0 成功 · 1 verify 画面没变化（坐标可能失效） · 2 参数/配置错误 · 3 外部不可用/超时 · 4 未分类执行错误

依赖：macOS + Xcode；`brew install cliclick`；给宿主 App 开「辅助功能」+「屏幕录制」。
''';

Future<void> runDeviceCli(List<String> args, {DeviceRuntime? runtime}) async {
  final rt = runtime ?? DeviceRuntime();
  final wantsJson = args.contains('--json');
  final fallbackPlatform = _platformFromArgs(args);
  if (args.isEmpty) {
    rt.write(_usage);
    exitCode = 2;
    return;
  }
  if (args.first == '-h' || args.first == '--help') {
    rt.write(_usage);
    exitCode = 0;
    return;
  }
  if (args.length == 1 && args.first == '--version') {
    rt.write('w_tools_device $deviceCliVersion\n');
    return;
  }

  DeviceOptions? options;
  try {
    options = DeviceOptions.parse(args);
    options.validate();
    final o = options;
    switch (o.command) {
      case 'list':
        await _list(rt, o);
      case 'boot':
        await _boot(rt, o);
      case 'shot':
        await _shot(rt, o);
      case 'calibrate':
        final target = await _resolveSim(rt, o, bootedOnly: true);
        final cal = await _calibrate(rt, target);
        _emit(rt, o, {...cal.toJson(), 'deviceId': target.udid}, _calibrationText(cal));
      case 'tap':
        switch (o.platform) {
          case DevicePlatform.android:
            await _androidTap(rt, o);
          case DevicePlatform.iosSimulator:
            await _tap(rt, o);
          case DevicePlatform.iosDevice:
            throw _unsupportedOnReal('tap');
        }
      case 'drag':
        switch (o.platform) {
          case DevicePlatform.android:
            await _androidDrag(rt, o);
          case DevicePlatform.iosSimulator:
            await _drag(rt, o);
          case DevicePlatform.iosDevice:
            throw _unsupportedOnReal('drag');
        }
      case 'size':
        switch (o.platform) {
          case DevicePlatform.android:
            await _androidSize(rt, o);
          case DevicePlatform.iosSimulator:
            await _simSize(rt, o);
          case DevicePlatform.iosDevice:
            throw _unsupportedOnReal('size');
        }
      case 'foreground':
        await _androidForeground(rt, o);
      case 'wait':
        switch (o.platform) {
          case DevicePlatform.android:
            await _androidWait(rt, o);
          case DevicePlatform.iosSimulator:
            await _wait(rt, o);
          case DevicePlatform.iosDevice:
            throw _unsupportedOnReal('wait');
        }
      case 'verify':
        switch (o.platform) {
          case DevicePlatform.android:
            await _androidVerify(rt, o);
          case DevicePlatform.iosSimulator:
            await _verify(rt, o);
          case DevicePlatform.iosDevice:
            throw _unsupportedOnReal('verify');
        }
      default:
        throw DeviceCliException(
          '未知命令：${o.command}',
          2,
          showUsage: true,
        );
    }
  } on DeviceCliException catch (e) {
    _fail(
      rt,
      options,
      e.message,
      e.exitCode,
      jsonRequested: wantsJson,
      platform: options?.platform ?? fallbackPlatform,
      usage: e.showUsage,
    );
  } on VerificationTimeout catch (e) {
    _fail(rt, options, e.message, 3, jsonRequested: wantsJson, platform: fallbackPlatform);
  } on ProcessException catch (e) {
    _fail(rt, options, '命令执行失败：${e.message}', 3,
        jsonRequested: wantsJson, platform: fallbackPlatform);
  } on FormatException catch (e) {
    _fail(rt, options, '参数错误：${e.message}', 2,
        jsonRequested: wantsJson, platform: fallbackPlatform);
  } on StateError catch (e) {
    _fail(rt, options, e.message, 2, jsonRequested: wantsJson, platform: fallbackPlatform);
  } on FileSystemException catch (e) {
    _fail(rt, options, '文件操作失败：${e.message}', 3,
        jsonRequested: wantsJson, platform: fallbackPlatform);
  } on Exception catch (e) {
    _fail(rt, options, '执行失败：$e', 4, jsonRequested: wantsJson, platform: fallbackPlatform);
  }
}

/// 该命令在平台表里已排除 iOS 真机；这里只是把错误变成明确文案。
DeviceCliException _unsupportedOnReal(String command) =>
    DeviceCliException('$command 只支持 iOS 模拟器 / Android（不支持 iOS 真机）', 2);

/// 参数解析失败时 `DeviceOptions` 还不存在，用原始参数推断平台，保证错误 JSON 也有 `platform`。
DevicePlatform _platformFromArgs(List<String> args) {
  if (args.contains('--android')) return DevicePlatform.android;
  if (args.contains('--real')) return DevicePlatform.iosDevice;
  return DevicePlatform.iosSimulator;
}

/// `--region` 的 JSON 视图（null = 整屏）。
Map<String, Object?>? regionJson(DRect? region) => region == null
    ? null
    : {
        'x': region.left,
        'y': region.top,
        'w': region.width,
        'h': region.height,
      };

/// 输出：`--json` 打 JSON，否则打人类可读文本。
///
/// [ok] 只表示「命令是否按预期完成」：`verify` 没变化仍算完成（findings，退出码 1），
/// `wait` 超时算未完成（退出码 3，`ok:false`）。
void _emit(
  DeviceRuntime rt,
  DeviceOptions o,
  Map<String, Object?> data,
  String human, {
  bool ok = true,
}) {
  if (o.json) {
    rt.write(
      '${jsonEncode(<String, Object?>{
            'schemaVersion': deviceJsonSchemaVersion,
            'ok': ok,
            'command': o.command,
            'platform': o.platform.wireName,
            ...data,
          })}\n',
    );
  } else {
    rt.write('$human\n');
  }
}

void _fail(
  DeviceRuntime rt,
  DeviceOptions? o,
  String message,
  int code, {
  required bool jsonRequested,
  required DevicePlatform platform,
  bool usage = false,
}) {
  final asJson = o?.json ?? jsonRequested;
  if (asJson) {
    rt.write(
      '${jsonEncode(<String, Object?>{
            'schemaVersion': deviceJsonSchemaVersion,
            'ok': false,
            'command': o?.command,
            'platform': (o?.platform ?? platform).wireName,
            'error': message,
          })}\n',
    );
  } else {
    rt.writeError(usage ? '$message\n\n$_usage' : '$message\n');
  }
  exitCode = code;
}
