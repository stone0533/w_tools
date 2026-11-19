import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 四、WAsync / WCancelToken：不需要 UI 状态时的执行入口。
class ExecutionPage extends StatefulWidget {
  const ExecutionPage({super.key});

  @override
  State<ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<ExecutionPage> {
  final _logs = <String>[];
  int _retryAttempt = 0;
  late final WAsyncExecutor _executor;

  @override
  void initState() {
    super.initState();
    _executor = WAsyncExecutor(
      WAsyncHooks(
        onStart: () => _log('executor: start'),
        onError: (error) => _log('executor: error $error'),
        onFinally: () => _log('executor: finally'),
      ),
    );
  }

  void _log(String message) {
    if (mounted) setState(() => _logs.insert(0, message));
  }

  Future<void> _run() async {
    try {
      final result = await WAsync.run<String>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          return '执行成功';
        },
        onError: (error) => _log('run onError: $error'),
      );
      _log('run: $result');
    } catch (error) {
      _log('run error: $error');
    }
  }

  Future<void> _runWithExecutor() async {
    try {
      final result = await _executor.run<String>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return 'executor 执行成功';
        },
      );
      _log('executor: $result');
    } catch (error) {
      _log('executor: error $error');
    }
  }

  Future<void> _retry() async {
    _retryAttempt = 0;
    try {
      final result = await WAsync.retry<String>(
        () async {
          _retryAttempt++;
          if (_retryAttempt < 3) {
            throw Exception('第 $_retryAttempt 次失败');
          }
          return '第 $_retryAttempt 次成功';
        },
        retryCount: 3,
        retryDelayBuilder: (attempt) => Duration(milliseconds: 80 * attempt),
        onRetry: (attempt, error, delay) =>
            _log('retry #$attempt in ${delay.inMilliseconds}ms: $error'),
      );
      _log('retry: $result');
    } catch (error) {
      _log('retry error: $error');
    }
  }

  Future<void> _timeout() async {
    try {
      final result = await WAsync.timeout<String>(
        () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return '不会返回';
        },
        const Duration(milliseconds: 200),
      );
      _log('timeout result: $result');
    } catch (error) {
      _log('timeout: $error');
    }
  }

  Future<void> _cancel() async {
    final token = WCancelToken();
    final future = WAsync.run<String>(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return '已取消，不会回调 onError';
      },
      onError: (error) => _log('cancel onError: $error'),
      cancelToken: token,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    token.cancel('用户取消');
    try {
      final result = await future;
      _log('cancel result: $result');
    } on WCancellationException catch (error) {
      _log('cancel: $error');
    }
  }

  Future<void> _settle() async {
    final results = await WAsync.settle<String>(
      [
        () async => 'banner',
        () async => throw Exception('columns failed'),
        () async => 'notice',
      ],
      onError: (error) => _log('settle onError: $error'),
    );
    final summary = results.map((result) => result.isSuccess ? 'ok' : 'fail').join(', ');
    _log('settle: $summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('执行编排')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'WAsync 不依赖 Widget；适合接口调用、重试、超时、取消和独立区块并行。',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: _run, child: const Text('执行')),
              FilledButton.tonal(
                onPressed: _runWithExecutor,
                child: const Text('executor'),
              ),
              FilledButton.tonal(
                onPressed: _retry,
                child: const Text('重试 3 次'),
              ),
              FilledButton.tonal(
                onPressed: _timeout,
                child: const Text('200ms 超时'),
              ),
              OutlinedButton(
                onPressed: _cancel,
                child: const Text('执行并取消'),
              ),
              FilledButton.tonal(
                onPressed: _settle,
                child: const Text('settle'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_logs.isEmpty)
            const Text('点击按钮查看结果')
          else
            ..._logs.map(
              (log) => Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.terminal_rounded),
                  title: Text(log),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
