import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  group('WDebounce / WThrottle', () {
    test('WDebounce 连续调用只执行最后一次，可取消', () async {
      var count = 0;
      final debounce = WDebounce(() => count++, duration: const Duration(milliseconds: 30));

      debounce();
      debounce();
      debounce();
      expect(debounce.isPending, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(count, 1);

      debounce();
      debounce.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(count, 1);
    });

    test('WThrottle 窗口内只执行第一次，窗口结束后恢复', () async {
      var count = 0;
      final throttle = WThrottle(() => count++, duration: const Duration(milliseconds: 50));

      throttle();
      throttle();
      expect(throttle.isThrottled, isTrue);
      expect(count, 1);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(throttle.isThrottled, isFalse);
      throttle();
      expect(count, 2);
    });
  });

  final wux = WUx();

  group('WUx - debounce 防抖', () {});

  group('WUx - throttle 节流', () {});

  group('WUx - delay 延迟执行', () {
    test('延迟后执行', () async {
      int callCount = 0;
      await wux.delay(() => callCount++, duration: 30);
      expect(callCount, 1);
    });
  });

  group('WUx - duration 校验', () {
    test('delay 负数 duration 返回失败的 Future', () async {
      await expectLater(
        WUx().delay(() {}, duration: -1),
        throwsArgumentError,
      );
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
