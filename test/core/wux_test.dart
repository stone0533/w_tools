import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  final wux = WUx();

  group('WUx - debounce 防抖', () {
    test('连续调用只执行最后一次', () async {
      int callCount = 0;
      final debounced = wux.debounce(
        () => callCount++,
        duration: 50,
      );

      debounced();
      debounced();
      debounced();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);
    });

    test('防抖后再次调用正常执行', () async {
      int callCount = 0;
      final debounced = wux.debounce(
        () => callCount++,
        duration: 30,
      );

      debounced();
      await Future.delayed(const Duration(milliseconds: 60));
      debounced();
      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 2);
    });

    test('cancel 可取消尚未触发的回调', () async {
      int callCount = 0;
      final debounced = wux.debounce(
        () => callCount++,
        duration: 50,
      );

      debounced();
      debounced.cancel();
      await Future.delayed(const Duration(milliseconds: 80));

      expect(callCount, 0);
    });
  });

  group('WUx - throttle 节流', () {
    test('节流窗口内只执行一次', () async {
      int callCount = 0;
      final throttled = wux.throttle(
        () => callCount++,
        duration: 50,
      );

      throttled();
      throttled();
      throttled();

      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 100));
      throttled();
      expect(callCount, 2);
    });

    test('cancel 可提前结束节流窗口', () {
      int callCount = 0;
      final throttled = wux.throttle(
        () => callCount++,
        duration: 1000,
      );

      throttled();
      throttled();
      expect(callCount, 1);

      throttled.cancel();
      throttled();
      expect(callCount, 2);
    });
  });

  group('WUx - delay 延迟执行', () {
    test('延迟后执行', () async {
      int callCount = 0;
      await wux.delay(() => callCount++, duration: 30);
      expect(callCount, 1);
    });
  });

  group('WUx - 静态常量', () {
    test('defaultCurve / defaultDuration / fastDuration / slowDuration', () {
      expect(WUx.defaultCurve, isNotNull);
      expect(WUx.defaultDuration, const Duration(milliseconds: 300));
      expect(WUx.fastDuration, const Duration(milliseconds: 150));
      expect(WUx.slowDuration, const Duration(milliseconds: 500));
    });
  });
}
