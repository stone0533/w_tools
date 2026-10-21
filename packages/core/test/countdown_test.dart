import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/countdown.dart';

void main() {
  group('WCountdown', () {
    test('构造函数初始状态', () {
      final countdown = WCountdown();
      expect(countdown.isRunning, isFalse);
      expect(countdown.isPaused, isFalse);
      expect(countdown.remainingSeconds, 0);
    });

    test('start 后 isRunning 为 true', () {
      final countdown = WCountdown();
      countdown.start(second: 10);
      expect(countdown.isRunning, isTrue);
      expect(countdown.isPaused, isFalse);
      expect(countdown.totalSeconds, 10);
      countdown.dispose();
    });

    test('start 后立即停止', () async {
      final countdown = WCountdown();
      countdown.start(second: 10);
      countdown.dispose();
      // dispose 后 Timer 已 cancel
      expect(countdown.isRunning, isFalse);
    });

    test('pause 和 resume', () async {
      final countdown = WCountdown();
      countdown.start(second: 5);
      expect(countdown.isRunning, isTrue);

      countdown.pause();
      expect(countdown.isPaused, isTrue);

      countdown.resume();
      expect(countdown.isPaused, isFalse);

      countdown.dispose();
    });

    test('resume 无效果（未运行时）', () {
      final countdown = WCountdown();
      countdown.resume(); // 未 start
      expect(countdown.isRunning, isFalse);
      expect(countdown.isPaused, isFalse);
    });

    test('stop 重置状态', () {
      final countdown = WCountdown();
      countdown.start(second: 10);
      countdown.stop();
      expect(countdown.isRunning, isFalse);
      expect(countdown.isPaused, isFalse);
      expect(countdown.remainingSeconds, 0);
    });

    test('dispose 等同 stop', () {
      final countdown = WCountdown();
      countdown.start(second: 10);
      countdown.dispose();
      expect(countdown.isRunning, isFalse);
    });

    test('formatRemaining() 格式化 - 秒模式', () {
      final countdown = WCountdown();
      countdown.start(second: 5);
      // remainingSeconds 在 start 后初始为 5
      // 由于 Timer 周期是 1s，立即读取可能是 5 或 4
      final text = countdown.formatRemaining();
      expect(text, anyOf('05', '04'));
      countdown.dispose();
    });

    test('formatRemaining() 格式化 - 分:秒模式', () {
      final countdown = WCountdown();
      countdown.start(second: 125);
      final text = countdown.formatRemaining(type: WCountdownRemainingType.minutesSeconds);
      expect(text, '02:05'); // 125s = 2m05s
      countdown.dispose();
    });

    test('formatRemaining() 在 0 时返回 "00"', () {
      final countdown = WCountdown();
      countdown.stop();
      expect(countdown.formatRemaining(), '00');
      expect(countdown.formatRemaining(type: WCountdownRemainingType.minutesSeconds), '00:00');
    });

    test('start(0) 立即完成且不启动定时器', () {
      final events = <int>[];
      final countdown = WCountdown(
        callback: events.add,
        onComplete: events.add,
      );

      countdown.start(second: 0);

      expect(events, [0, 0]); // callback(0) + onComplete(0)
      expect(countdown.isRunning, isFalse);
      expect(countdown.remainingSeconds, 0);
      expect(countdown.totalSeconds, 0);
    });

    test('start 负数按 0 处理', () {
      int? completed;
      final countdown = WCountdown(onComplete: (v) => completed = v);

      countdown.start(second: -5);

      expect(completed, 0);
      expect(countdown.totalSeconds, 0);
      expect(countdown.isRunning, isFalse);
    });

    test('onComplete 回调在结束时触发', () async {
      final completer = Completer<int>();
      final countdown = WCountdown(
        onComplete: (v) {
          completer.complete(v);
        },
      );
      countdown.start(second: 1);
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(result, 0);
      expect(countdown.isRunning, isFalse);
    });
  });
}
