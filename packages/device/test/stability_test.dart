import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/w_tools_device.dart';

void main() {
  test('画面稳定后返回 true', () async {
    var i = 0;
    final s = Stability(
      grab: () async => (i++ < 2) ? 'a$i' : 'stable',
      interval: const Duration(milliseconds: 5),
    );
    final ok = await s.waitStable(
      stableFor: const Duration(milliseconds: 15),
      timeout: const Duration(seconds: 1),
    );
    expect(ok, isTrue);
  });

  test('一直变化则超时返回 false', () async {
    var i = 0;
    final s = Stability(
      grab: () async => 'frame${i++}',
      interval: const Duration(milliseconds: 5),
    );
    final ok = await s.waitStable(
      stableFor: const Duration(milliseconds: 20),
      timeout: const Duration(milliseconds: 60),
    );
    expect(ok, isFalse);
  });

  test('整屏指纹：同一画面、不同 PNG 压缩级别 → 指纹相同', () {
    final image = img.Image(width: 40, height: 40);
    img.fill(image, color: img.ColorRgb8(30, 30, 30));
    final a = Uint8List.fromList(img.encodePng(image, level: 1));
    final b = Uint8List.fromList(img.encodePng(image, level: 9));
    expect(ScreenFingerprint.of(a), ScreenFingerprint.of(b));
  });

  test('整屏指纹：画面变了 → 指纹不同', () {
    final before = img.Image(width: 40, height: 40);
    img.fill(before, color: img.ColorRgb8(30, 30, 30));
    final after = img.Image(width: 40, height: 40);
    img.fill(after, color: img.ColorRgb8(200, 30, 30));
    expect(
      ScreenFingerprint.of(Uint8List.fromList(img.encodePng(before))),
      isNot(ScreenFingerprint.of(Uint8List.fromList(img.encodePng(after)))),
    );
  });

  test('verify：点击前画面不稳定 → VerificationTimeout，且不点击', () async {
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

  test('verify 的 timeout 是总预算，不是每次等待各一份', () async {
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

  test('verify：点击后画面不稳定 → VerificationTimeout', () async {
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

class _CaptureStability extends Stability {
  _CaptureStability(this.seen) : super(grab: () async => '');

  final List<Duration> seen;

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    seen.add(timeout);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return true;
  }
}

class _FirstStableThenNever extends Stability {
  _FirstStableThenNever() : super(grab: () async => '');

  var calls = 0;

  @override
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      calls++ == 0;
}
