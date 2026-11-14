import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/internal/image_loader.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

WImageLoader _loader({
  int retryCount = 0,
  int retryDelay = 1000,
  ValueChanged<WImageProgress>? onProgress,
}) {
  final loader = WImageLoader(
    retryCount: retryCount,
    retryDelay: retryDelay,
    onProgress: onProgress,
  );
  addTearDown(loader.dispose);
  return loader;
}

void main() {
  test('reset / beginAttempt 通知监听者', () {
    final loader = _loader(retryCount: 3);
    var notifications = 0;
    loader.addListener(() => notifications++);

    loader.reset(retryCount: 3, retryDelay: 1000);
    expect(loader.attempt, 0);

    loader.beginAttempt();
    expect(loader.attempt, 1);
    expect(notifications, greaterThan(0));
  });

  test('相同状态重复 markLoading 不重复通知', () {
    final loader = _loader();
    var notifications = 0;
    loader.addListener(() => notifications++);

    loader.markLoading();
    final afterFirst = notifications;
    expect(afterFirst, greaterThan(0));

    loader.markLoading();
    expect(notifications, afterFirst);
  });

  test('completed 时进度回调 1.0', () {
    final progress = <WImageProgress>[];
    final loader = _loader(onProgress: progress.add);

    loader.handleCompleted(notifyProgress: true);

    expect(loader.status, WImageLoadStatus.completed);
    expect(progress.single.fraction, 1.0);
  });

  test('失败后按 retryCount 自动重试', () async {
    final loader = _loader(retryCount: 1, retryDelay: 1);
    loader.handleError(
      StateError('connection reset'),
      const WImageError('x', WImageErrorKind.network),
      retry: true,
    );
    expect(loader.retryScheduled, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(loader.attempt, 1);
    expect(loader.retryScheduled, isFalse);
  });

  test('completed 后 markLoading 不会回退状态', () {
    final loader = _loader();
    loader.handleCompleted();
    loader.markLoading();
    expect(loader.status, WImageLoadStatus.completed);
  });

  test('completed 后迟到的进度不会回退状态', () {
    final loader = _loader();
    loader.handleCompleted();
    loader.handleProgress(const WImageProgress(downloadedBytes: 1, totalBytes: 10));
    expect(loader.status, WImageLoadStatus.completed);
  });

  test('completed 会取消已排队的重试', () async {
    final loader = _loader(retryCount: 3, retryDelay: 1);
    loader.handleError(
      StateError('connection reset'),
      const WImageError('x', WImageErrorKind.network),
      retry: true,
    );
    expect(loader.retryScheduled, isTrue);

    loader.handleCompleted();
    expect(loader.retryScheduled, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(loader.attempt, 0);
  });

  test('beginAttempt 清空旧进度', () {
    final loader = _loader(retryCount: 1);
    loader.pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 2);
    loader.beginAttempt();
    expect(loader.pendingProgress, isNull);
  });

  test('状态 / 进度可直接观察', () {
    final loader = _loader(retryCount: 3);
    loader.markStatus(WImageLoadStatus.loading);
    loader.pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 2);
    expect(loader.status, WImageLoadStatus.loading);
    expect(loader.pendingProgress?.fraction, 0.5);
  });
}
