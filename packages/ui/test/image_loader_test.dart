import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_loader.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  test('reset / beginAttempt 会推送快照', () {
    final loader = WImageLoader(retryCount: 3, retryDelay: 1000);
    addTearDown(loader.dispose);
    final snapshots = <WImageLoadSnapshot>[];
    loader.state.addListener(() => snapshots.add(loader.state.value));

    loader.reset(retryCount: 3, retryDelay: 1000);
    expect(loader.state.value.attempt, 0);

    loader.beginAttempt();
    expect(loader.state.value.attempt, 1);
    expect(snapshots, isNotEmpty);
  });

  test('相同状态重复 emit 不重复通知', () {
    final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    var notifications = 0;
    loader.state.addListener(() => notifications++);

    loader.emit();
    loader.emit();
    expect(notifications, 0);

    loader.markLoading();
    final afterLoading = notifications;
    loader.markLoading();
    expect(notifications, afterLoading);
  });

  test('completed 时进度归 1.0', () {
    final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    loader.handleCompleted(notifyProgress: true);
    expect(loader.state.value.progress?.fraction, 1.0);
    expect(loader.state.value.isCompleted, isTrue);
  });

  test('失败后按 retryCount 自动重试', () async {
    final loader = WImageLoader(retryCount: 1, retryDelay: 1);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 1, retryDelay: 1);
    loader.handleError(
      StateError('connection reset'),
      const WImageNetworkError('x', 'cause'),
      retry: true,
    );
    expect(loader.state.value.retryScheduled, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(loader.attempt, 1);
    expect(loader.state.value.retryScheduled, isFalse);
  });

  test('completed 后 markLoading 不会回退状态', () {
    final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    loader.handleCompleted();
    loader.markLoading();
    expect(loader.state.value.isCompleted, isTrue);
  });

  test('completed 后迟到的进度不会回退状态', () {
    final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    loader.handleCompleted();
    loader.handleProgress(const WImageProgress(downloadedBytes: 1, totalBytes: 10));
    expect(loader.state.value.isCompleted, isTrue);
  });

  test('completed 会取消已排队的重试', () async {
    final loader = WImageLoader(retryCount: 3, retryDelay: 1);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 3, retryDelay: 1);
    loader.handleError(
      StateError('connection reset'),
      const WImageNetworkError('x', 'cause'),
      retry: true,
    );
    expect(loader.state.value.retryScheduled, isTrue);

    loader.handleCompleted();
    expect(loader.state.value.retryScheduled, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(loader.attempt, 0);
  });

  test('beginAttempt 清空旧进度', () {
    final loader = WImageLoader(retryCount: 1, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 1, retryDelay: 1000);
    loader.pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 2);
    loader.beginAttempt();
    expect(loader.pendingProgress, isNull);
  });

  test('status / progress 进入快照', () {
    final loader = WImageLoader(retryCount: 3, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.markStatus(WImageLoadStatus.loading);
    loader.pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 2);
    loader.emit();
    expect(loader.state.value.isLoading, isTrue);
    expect(loader.state.value.progress?.fraction, 0.5);
  });
}
