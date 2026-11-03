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

  test('changedAfter：动作改变画面返回 true', () async {
    var value = 'a';
    final s = Stability(grab: () async => value, interval: const Duration(milliseconds: 5));
    final changed = await s.changedAfter(() async => value = 'b');
    expect(changed, isTrue);
  });

  test('changedAfter：画面不变返回 false', () async {
    final s = Stability(grab: () async => 'same', interval: const Duration(milliseconds: 5));
    final changed = await s.changedAfter(
      () async {},
      timeout: const Duration(milliseconds: 40),
    );
    expect(changed, isFalse);
  });
}
