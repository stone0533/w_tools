import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/src/geometry.dart';
import 'package:w_tools_device/src/stability.dart';

void main() {
  group('ScreenFingerprint（判断“画面有没有变”）', () {
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

    test('同一画面 → 同指纹；像素变化 → 指纹变化', () {
      final a = png(paintLeft: false, paintRight: false);
      final b = png(paintLeft: true, paintRight: false);
      expect(ScreenFingerprint.of(a), ScreenFingerprint.of(a));
      expect(ScreenFingerprint.of(a), isNot(ScreenFingerprint.of(b)));
    });

    test('非 PNG（异常输出）退化为字节哈希，长度不同也不同', () {
      final a = Uint8List.fromList(List<int>.generate(10000, (i) => i % 256));
      final b = Uint8List.fromList(a);
      expect(ScreenFingerprint.of(a), ScreenFingerprint.of(b));
      b[0] ^= 0xFF;
      expect(ScreenFingerprint.of(a), isNot(ScreenFingerprint.of(b)));
      expect(
        ScreenFingerprint.of(Uint8List.fromList([1, 2, 3])),
        isNot(ScreenFingerprint.of(Uint8List.fromList([1, 2, 3, 4]))),
      );
    });

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

  group('Stability（等画面稳定）', () {
    test('画面连续不变 → 超时前返回 true', () async {
      final stability = Stability(
        grab: () async => 'same',
        interval: const Duration(milliseconds: 10),
      );
      expect(
        await stability.waitStable(
          stableFor: const Duration(milliseconds: 20),
          timeout: const Duration(milliseconds: 500),
        ),
        isTrue,
      );
    });

    test('画面一直在变 → 超时返回 false', () async {
      var frame = 0;
      final stability = Stability(
        grab: () async => '${frame++}',
        interval: const Duration(milliseconds: 5),
      );
      expect(
        await stability.waitStable(
          stableFor: const Duration(milliseconds: 50),
          timeout: const Duration(milliseconds: 60),
        ),
        isFalse,
      );
    });
  });

  group('TapVerifier（点按自检）', () {
    test('画面变了 → true；没变 → false', () async {
      Future<bool> run(List<String> frames) {
        final f = _Frames(frames);
        return TapVerifier.verify(
          stability: _InstantStability(),
          fingerprint: () async => f.next(),
          tap: () async {},
          stableFor: const Duration(milliseconds: 10),
          timeout: const Duration(milliseconds: 50),
        );
      }

      expect(await run(['BEFORE', 'AFTER']), isTrue);
      expect(await run(['SAME', 'SAME']), isFalse);
    });

    test('点击前画面不稳定 → VerificationTimeout，且不点击', () async {
      var tapped = false;
      await expectLater(
        TapVerifier.verify(
          stability: _NeverStable(),
          fingerprint: () async => 'x',
          tap: () async => tapped = true,
          stableFor: const Duration(milliseconds: 1),
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<VerificationTimeout>()),
      );
      expect(tapped, isFalse);
    });

    test('点击后画面不稳定 → VerificationTimeout', () async {
      var taps = 0;
      await expectLater(
        TapVerifier.verify(
          stability: _FirstStableThenNever(),
          fingerprint: () async => 'x',
          tap: () async => taps++,
          stableFor: const Duration(milliseconds: 1),
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<VerificationTimeout>()),
      );
      expect(taps, 1);
    });

    test('timeout 是点击前后的总预算，不是每次等待各一份', () async {
      final seen = <Duration>[];
      await TapVerifier.verify(
        stability: _CaptureStability(seen),
        fingerprint: () async => 'x',
        tap: () async => Future<void>.delayed(const Duration(milliseconds: 30)),
        stableFor: const Duration(milliseconds: 1),
        timeout: const Duration(milliseconds: 100),
      );
      expect(seen, hasLength(2));
      expect(seen[1], lessThan(const Duration(milliseconds: 100)));
    });
  });

  group('ScreenStats（真机锁屏会返回全黑图）', () {
    Uint8List solid(int r, int g, int b) {
      final image = img.Image(width: 40, height: 40);
      img.fill(image, color: img.ColorRgb8(r, g, b));
      return Uint8List.fromList(img.encodePng(image));
    }

    test('全黑 → true；普通内容 → false', () {
      expect(ScreenStats.isMostlyDark(solid(0, 0, 0)), isTrue);
      expect(ScreenStats.isMostlyDark(solid(250, 250, 250)), isFalse);
      expect(ScreenStats.isMostlyDark(solid(120, 30, 200)), isFalse);
    });
  });
}

class _InstantStability extends Stability {
  _InstantStability() : super(grab: () async => '');

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      true;
}

class _NeverStable extends Stability {
  _NeverStable() : super(grab: () async => '');

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      false;
}

class _FirstStableThenNever extends Stability {
  _FirstStableThenNever() : super(grab: () async => '');

  var _calls = 0;

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      _calls++ == 0;
}

class _CaptureStability extends Stability {
  _CaptureStability(this.seen) : super(grab: () async => '');

  final List<Duration> seen;

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    seen.add(timeout);
    return true;
  }
}

class _Frames {
  _Frames(this._values);
  final List<String> _values;
  int _i = 0;
  String next() => _values[_i < _values.length ? _i++ : _values.length - 1];
}
