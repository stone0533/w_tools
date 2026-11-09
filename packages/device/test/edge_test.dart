import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/w_tools_device.dart';

/// 针对实际使用中踩过的坑补的边界测试。
void main() {
  group('DeviceHub.parseWindow（真实踩坑）', () {
    test('Retina / 小数 / 负坐标都能解析', () {
      final w = DeviceHub.parseWindow('-1512.5, 53, 872.5, 1084')!;
      expect(w.x, -1512.5);
      expect(w.y, 53);
      expect(w.width, 872.5);
      expect(w.height, 1084);
    });

    test('窗口被移到副屏（x 很大）也能解析', () {
      final w = DeviceHub.parseWindow('4198, 101, 872, 1084')!;
      expect(w.x, 4198);
      expect(w.width, 872);
    });
  });

  group('Simctl 边界', () {
    test('空 / 坏 JSON 返回空列表，不抛', () {
      expect(Simctl.parseDevices('{}'), isEmpty);
      expect(Simctl.parseDevices('{"devices":{}}'), isEmpty);
      expect(Simctl.parseDevices('not json'), isEmpty);
    });

    test('跳过没有 udid 的条目', () {
      final list = Simctl.parseDevices(
        '{"devices":{"x":[{"name":"A"},{"udid":"U","name":"B","state":"Booted"}]}}',
      );
      expect(list.length, 1);
      expect(list.single.udid, 'U');
    });

    test('guessScale：分辨率宽度决定 3x / 2x', () {
      expect(Simctl.guessScale(1206), 3);
      expect(Simctl.guessScale(1170), 3);
      expect(Simctl.guessScale(750), 2);
      expect(Simctl.guessScale(1620), 2);
      expect(Simctl.guessScale(2048), 2);
    });

    test('resolve 找不到时返回 null（而不是抛）', () {
      expect(Simctl.resolve(const [], 'nope'), isNull);
      const d = SimDevice(udid: 'U', name: 'iPhone', state: 'Shutdown', runtime: 'x');
      expect(Simctl.resolve(const [d], null, bootedOnly: true), isNull);
    });
  });

  group('标定遮挡（被活动监视器盖住的那次）', () {
    img.Image frame({required int bezelTop, required int bezelHeight}) {
      final image = img.Image(width: 872, height: 1084);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(
        image,
        x1: 340,
        y1: bezelTop,
        x2: 780,
        y2: bezelTop + bezelHeight,
        color: img.ColorRgb8(10, 10, 10),
      );
      return image;
    }

    test('设备预览只露出半截 → 报错并提示前置窗口', () {
      // 机身 400 高，窗口 1084：< 45%
      final image = frame(bezelTop: 60, bezelHeight: 400);
      expect(
        () => const CalibrationDetector().detect(
          image: image,
          window: const HubWindow(0, 0, 872, 1084),
          scale: 1,
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('遮挡'),
          ),
        ),
      );
    });

    test('完整设备 → 正常返回，且宽高比贴近设备', () {
      final image = frame(bezelTop: 60, bezelHeight: 960);
      final cal = const CalibrationDetector().detect(
        image: image,
        window: const HubWindow(0, 0, 872, 1084),
        scale: 1,
        deviceWidth: 402,
        deviceHeight: 874,
      );
      expect(cal.deviceRect.width / cal.deviceRect.height, closeTo(402 / 874, 0.02));
    });

    test('横屏预览但设备截图竖屏 → 明确报“横屏不支持”', () {
      final image = img.Image(width: 1084, height: 872);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(
        image,
        x1: 40,
        y1: 186,
        x2: 1040,
        y2: 686,
        color: img.ColorRgb8(8, 8, 8),
      );
      img.fillRect(
        image,
        x1: 60,
        y1: 200,
        x2: 1020,
        y2: 672,
        color: img.ColorRgb8(235, 235, 235),
      );
      expect(
        () => const CalibrationDetector().detect(
          image: image,
          window: const HubWindow(0, 0, 1084, 872),
          scale: 1,
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('横屏'), contains('Portrait')),
          ),
        ),
      );
    });

    test('深色画面（屏幕内容也接近黑色）仍按机身外框标定', () {
      final image = img.Image(width: 872, height: 1084);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(
        image,
        x1: 340,
        y1: 60,
        x2: 780,
        y2: 1030,
        color: img.ColorRgb8(8, 8, 8),
      );
      // 暗色主题的屏幕内容仍比机身亮，但都低于 160 的黑判定阈值。
      img.fillRect(
        image,
        x1: 350,
        y1: 70,
        x2: 770,
        y2: 1020,
        color: img.ColorRgb8(30, 30, 30),
      );
      final cal = const CalibrationDetector().detect(
        image: image,
        window: const HubWindow(0, 0, 872, 1084),
        scale: 1,
        deviceWidth: 402,
        deviceHeight: 874,
      );
      expect(cal.deviceRect.width / cal.deviceRect.height, closeTo(402 / 874, 0.02));
      expect(cal.deviceRect.left, closeTo(340, 25));
    });
  });

  group('标定缓存（窗口移动后必须失效）', () {
    late Directory home;
    setUp(() => home = Directory.systemTemp.createTempSync('w_tools_device_'));
    tearDown(() => home.deleteSync(recursive: true));

    Calibration sample(HubWindow w) => Calibration(
          window: w,
          deviceRect: const DRect(350, 95, 418, 908),
          deviceWidth: 402,
          deviceHeight: 874,
        );

    test('保存后能读回，字段一致', () {
      final store = CalibrationStore(home: home.path);
      final c = sample(const HubWindow(100, 50, 872, 1084));
      store.save('UDID1', c);
      final back = store.load('UDID1')!;
      expect(back.deviceWidth, 402);
      expect(back.deviceRect.left, 350);
      expect(back.window.x, 100);
    });

    test('窗口没变 → 缓存新鲜；窗口移动 → 失效', () {
      final store = CalibrationStore(home: home.path);
      store.save('UDID1', sample(const HubWindow(100, 50, 872, 1084)));
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('UDID1'),
          const HubWindow(100, 50, 872, 1084),
        ),
        isTrue,
      );
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('UDID1'),
          const HubWindow(300, 50, 872, 1084),
        ),
        isFalse,
      );
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('UDID1'),
          const HubWindow(100, 50, 900, 1084),
        ),
        isFalse,
      );
    });

    test('设备尺寸变化 → 缓存失效', () {
      final store = CalibrationStore(home: home.path);
      store.save('UDID1', sample(const HubWindow(100, 50, 872, 1084)));
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('UDID1'),
          const HubWindow(100, 50, 872, 1084),
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        isTrue,
      );
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('UDID1'),
          const HubWindow(100, 50, 872, 1084),
          deviceWidth: 874,
          deviceHeight: 402,
        ),
        isFalse,
      );
    });

    test('缓存文件损坏 → 当作没有缓存', () {
      final store = CalibrationStore(home: home.path);
      store.dir.createSync(recursive: true);
      store.fileFor('BAD').writeAsStringSync('{not json');
      expect(store.load('BAD'), isNull);
      expect(
        CalibrationStore.isFreshCalibration(
          store.load('BAD'),
          const HubWindow(0, 0, 1, 1),
        ),
        isFalse,
      );
    });
  });

  group('Input（cliclick 是否可用）', () {
    test('找不到 cliclick 时 available() 为 false', () async {
      final input = Input(
        shell: _FakeShell({'cliclick': (exit: 1, out: '')}),
      );
      expect(await input.available(), isFalse);
    });

    test('装了 cliclick 时 available() 为 true', () async {
      final input = Input(
        shell: _FakeShell({'cliclick': (exit: 0, out: '/opt/homebrew/bin/cliclick\n')}),
      );
      expect(await input.available(), isTrue);
    });
  });

  group('ScreenFingerprint.ofRegion（只看局部）', () {
    // 造一张 PNG：左半黑、右半白；[paintLeft] 决定左边是否被改
    Uint8List png({required bool paintLeft, required bool paintRight}) {
      final image = img.Image(width: 100, height: 100);
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 49,
        y2: 99,
        color: paintLeft ? img.ColorRgb8(255, 0, 0) : img.ColorRgb8(0, 0, 0),
      );
      img.fillRect(
        image,
        x1: 50,
        y1: 0,
        x2: 99,
        y2: 99,
        color: paintRight ? img.ColorRgb8(255, 0, 0) : img.ColorRgb8(255, 255, 255),
      );
      return Uint8List.fromList(img.encodePng(image));
    }

    test('区域外变化不影响该区域指纹', () {
      final a = png(paintLeft: false, paintRight: false);
      final b = png(paintLeft: false, paintRight: true); // 只改右半
      const leftRegion = DRect(0, 0, 50, 100);
      expect(
        ScreenFingerprint.ofRegion(a, region: leftRegion),
        ScreenFingerprint.ofRegion(b, region: leftRegion),
      );
      expect(ScreenFingerprint.of(a), isNot(ScreenFingerprint.of(b)));
    });

    test('区域内的变化能被识别', () {
      final a = png(paintLeft: false, paintRight: false);
      final b = png(paintLeft: true, paintRight: false); // 只改左半
      const leftRegion = DRect(0, 0, 50, 100);
      expect(
        ScreenFingerprint.ofRegion(a, region: leftRegion),
        isNot(ScreenFingerprint.ofRegion(b, region: leftRegion)),
      );
    });

    test('区域越界时自动裁剪，不抛', () {
      final a = png(paintLeft: false, paintRight: false);
      expect(
        () => ScreenFingerprint.ofRegion(a, region: const DRect(-50, -50, 500, 500)),
        returnsNormally,
      );
      expect(
        ScreenFingerprint.ofRegion(a, region: const DRect(90, 90, 100, 100)),
        ScreenFingerprint.ofRegion(a, region: const DRect(90, 90, 100, 100)),
      );
    });
  });

  group('TapVerifier（点按自检）', () {
    test('画面变了 → true；没变 → false', () async {
      Future<bool> run(List<String> frames) {
        final f = _Frames(frames);
        return TapVerifier.verify(
          // 稳定等待由 stability_test 单独覆盖；这里只验证前后指纹比较。
          stability: _NoWaitStability(),
          fingerprint: () async => f.next(),
          tap: () async {},
          stableFor: const Duration(milliseconds: 10),
          timeout: const Duration(milliseconds: 50),
        );
      }

      expect(await run(['BEFORE', 'AFTER']), isTrue);
      expect(await run(['SAME', 'SAME']), isFalse);
    });
  });

  group('ScreenFingerprint（判断“画面有没有变”）', () {
    test('同一帧 → 同指纹；改一个采样字节 → 变指纹', () {
      final a = Uint8List.fromList(List<int>.generate(10000, (i) => i % 256));
      final b = Uint8List.fromList(a);
      expect(ScreenFingerprint.of(a), ScreenFingerprint.of(b));
      b[0] ^= 0xFF;
      expect(ScreenFingerprint.of(a), isNot(ScreenFingerprint.of(b)));
    });

    test('长度不同 → 指纹不同', () {
      expect(
        ScreenFingerprint.of(Uint8List.fromList([1, 2, 3])),
        isNot(ScreenFingerprint.of(Uint8List.fromList([1, 2, 3, 4]))),
      );
    });
  });
  group('Adb.requirePackage', () {
    test('空包名抛错，正常包名返回', () {
      expect(() => Adb.requirePackage(''), throwsStateError);
      expect(Adb.requirePackage('com.example.app'), 'com.example.app');
    });
  });

  group('Adb.escapeTextArgument', () {
    test('空格转 %s，单引号安全，换行拒绝', () {
      expect(Adb.escapeTextArgument('hello world'), "'hello%sworld'");
      expect(Adb.escapeTextArgument("it's"), "'it'\\''s'");
      expect(() => Adb.escapeTextArgument('a\nb'), throwsStateError);
    });
  });
}

class _FakeShell implements Shell {
  _FakeShell(this._results);
  final Map<String, ({int exit, String out})> _results;

  @override
  Future<ProcessResult> run(String exe, List<String> args) async {
    final r = _results[args.first];
    return ProcessResult(0, r?.exit ?? 1, r?.out ?? '', '');
  }

  @override
  Future<ProcessResult> runOrThrow(String exe, List<String> args) async {
    final r = await run(exe, args);
    if (r.exitCode != 0) throw ProcessException(exe, args, 'fake', r.exitCode);
    return r;
  }

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async {
    final r = await run(exe, args);
    if (r.exitCode != 0) throw ProcessException(exe, args, 'fake', r.exitCode);
    return Uint8List.fromList(r.stdout.codeUnits);
  }
}

class _NoWaitStability extends Stability {
  _NoWaitStability() : super(grab: () async => '');

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      true;
}

class _Frames {
  _Frames(this._values);
  final List<String> _values;
  int _i = 0;
  String next() => _values[_i < _values.length ? _i++ : _values.length - 1];
}
