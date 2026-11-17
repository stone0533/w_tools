// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  setUp(() => WAsync.defaultHooks = WAsyncHooks.none);
  tearDown(() => WAsync.defaultHooks = WAsyncHooks.none);

  test('WAsyncExecutor 使用自己的 hooks，不读取 defaultHooks', () async {
    final globalEvents = <String>[];
    WAsync.defaultHooks = WAsyncHooks(
      onStart: () => globalEvents.add('global-start'),
      onFinally: () => globalEvents.add('global-finally'),
    );
    final events = <String>[];
    final executor = WAsyncExecutor(
      WAsyncHooks(
        onStart: () => events.add('start'),
        onFinally: () => events.add('finally'),
      ),
    );

    expect(await executor.run(() async => 1), 1);

    expect(events, ['start', 'finally']);
    expect(globalEvents, isEmpty);
  });

  test('WAsyncExecutor.run / tryRun 保留失败语义', () async {
    final events = <String>[];
    final executor = WAsyncExecutor(
      WAsyncHooks(
        onStart: () => events.add('start'),
        onError: (_) => events.add('error'),
        onFinally: () => events.add('finally'),
      ),
    );

    await expectLater(
      executor.run<int>(() async => throw StateError('boom')),
      throwsStateError,
    );
    final result = await executor.tryRun<int>(() async => throw StateError('boom'));

    expect(result, isA<WAsyncFailure<int>>());
    expect(events, [
      'start',
      'error',
      'finally',
      'start',
      'error',
      'finally',
    ]);
  });

  test('WAsyncExecutor 支持本次 hooks 覆盖和 none', () async {
    final events = <String>[];
    final executor = WAsyncExecutor(
      WAsyncHooks(
        onStart: () => events.add('default-start'),
        onFinally: () => events.add('default-finally'),
      ),
    );

    await executor.run(
      () async => 1,
      hooks: WAsyncHooks(
        onStart: () => events.add('override-start'),
        onFinally: () => events.add('override-finally'),
      ),
    );
    await executor.run(() async => 1, hooks: WAsyncHooks.none);

    expect(events, ['override-start', 'override-finally']);
  });

  test('WAsyncExecutor 对 retry / timeout / settle 生效', () async {
    final events = <String>[];
    final executor = WAsyncExecutor(
      WAsyncHooks(
        onStart: () => events.add('start'),
        onFinally: () => events.add('finally'),
      ),
    );

    await executor.retry<int>(
      () async => 1,
      retryCount: 0,
      retryDelay: Duration.zero,
    );
    await executor.timeout<int>(() async => 1, const Duration(seconds: 1));
    await executor.settle<int>([() async => 1, () async => 2]);

    expect(events.where((event) => event == 'start'), hasLength(3));
    expect(events.where((event) => event == 'finally'), hasLength(3));
  });
}
