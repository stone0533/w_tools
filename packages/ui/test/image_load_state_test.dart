import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_load_state.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  test('手动重试清零自动重试预算，但 attempt 继续递增', () {
    final state = WImageLoadState()..reset(retryCount: 3, retryDelay: 1000);
    state.beginAttempt();
    state.beginAttempt();
    state.beginAttempt();
    expect(state.autoRetries, 3);

    state.beginManualAttempt();
    expect(state.attempt, 4);
    expect(state.autoRetries, 0);
  });

  test('syncRetryConfig 变化时取消已排队的重试', () {
    final state = WImageLoadState()
      ..reset(retryCount: 3, retryDelay: 1000)
      ..retryScheduled = true
      ..pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 10);
    final generation = state.generation;

    expect(state.syncRetryConfig(retryCount: 0, retryDelay: 1000), isTrue);
    expect(state.generation, generation + 1);
    expect(state.retryScheduled, isFalse);
    expect(state.pendingProgress, isNull);
    expect(state.attempt, 0);
  });

  test('配置不变时不重置', () {
    final state = WImageLoadState()..reset(retryCount: 3, retryDelay: 1000);
    final generation = state.generation;
    expect(state.syncRetryConfig(retryCount: 3, retryDelay: 1000), isFalse);
    expect(state.generation, generation);
  });
}
