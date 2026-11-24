import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:w_tools_device/src/android.dart';
import 'package:w_tools_device/src/shell.dart';

class _RecordingShell extends Shell {
  _RecordingShell();

  final calls = <String>[];

  @override
  Future<ProcessResult> run(String exe, List<String> args) async {
    calls.add('$exe ${args.join(' ')}');
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async {
    calls.add('$exe ${args.join(' ')}');
    return Uint8List.fromList(<int>[1, 2, 3]);
  }
}

void main() {
  group('Adb.parseDevices', () {
    test('解析 adb devices -l', () {
      const text = '''List of devices attached
0B241FDD4008T1         device usb:1179648X product:redfin model:Pixel_5 device:redfin transport_id:7
emulator-5554          offline transport_id:3

''';
      final list = Adb.parseDevices(text);
      expect(list.length, 2);
      expect(list.first.serial, '0B241FDD4008T1');
      expect(list.first.model, 'Pixel_5');
      expect(list.first.isReady, isTrue);
      expect(list.last.isReady, isFalse);
    });
  });

  group('Adb.readyMatches（不静默取第一台）', () {
    const text = 'List of devices attached\n'
        'AAA offline\n'
        'BBB device model:Pixel_5\n'
        'CCC device model:Pixel_5\n';

    test('只挑就绪设备；offline 不作目标', () {
      final list = Adb.parseDevices(text);
      expect(Adb.readyMatches(list, null).length, 2);
      expect(Adb.readyMatches(list, 'AAA'), isEmpty);
    });

    test('serial 精确优先；型号子串命中多台返回全部', () {
      final list = Adb.parseDevices(text);
      expect(Adb.readyMatches(list, 'BBB').single.serial, 'BBB');
      expect(Adb.readyMatches(list, 'pixel').length, 2);
      expect(Adb.readyMatches(list, 'nope'), isEmpty);
      expect(Adb.readyMatches(const [], null), isEmpty);
    });
  });

  test('parseCurrentPackage：优先 mCurrentFocus，回落 topResumedActivity', () {
    const withFocus = '''
  mCurrentFocus=Window{46d41f6 u0 com.android.settings/com.android.settings.SubSettings}
  mFocusedApp=ActivityRecord{5700d8b u0 com.android.settings/.SubSettings t2099}
''';
    expect(Adb.parseCurrentPackage(withFocus), 'com.android.settings');

    const onlyResumed = '''
  topResumedActivity=ActivityRecord{5700d8b u0 hk.ureward.app/.MainActivity t1}
''';
    expect(Adb.parseCurrentPackage(onlyResumed), 'hk.ureward.app');
    expect(Adb.parseCurrentPackage(''), isEmpty);
  });

  test('screenshotBytes 走 runBytes（PNG 不能被 UTF-8 解码）', () async {
    final shell = _RecordingShell();
    final bytes = await Adb(shell: shell).screenshotBytes('SERIAL-1');
    expect(bytes, <int>[1, 2, 3]);
    expect(shell.calls.single, contains('-s SERIAL-1 exec-out screencap -p'));
  });
}
