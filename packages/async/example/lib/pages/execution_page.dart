import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 四、WAsync / WAsyncOptions / WAsyncActivity / WCancelToken：不需要 UI 状态时的执行入口。
class ExecutionPage extends StatefulWidget {
  const ExecutionPage({super.key});

  @override
  State<ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<ExecutionPage> {
  final _logs = <String>[];
  bool _loading = false;
  int _retryAttempt = 0;

  WAsyncOptions get _options => WAsyncOptions(
    activity: WAsyncActivity(
      onStart: () {
        if (mounted) setState(() => _loading = true);
      },
      onEnd: () {
        if (mounted) setState(() => _loading = false);
      },
    ),
  );

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
        options: _options,
      );
      _log('run: $result');
    } catch (error) {
      _log('run error: $error');
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
        options: _options,
        retryCount: 3,
        retryDelay: const Duration(milliseconds: 150),
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
        options: _options,
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
      options: _options,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('执行编排'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'WAsync 不依赖 Widget；适合接口调用、重试、超时和取消。',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: _run, child: const Text('执行')),
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
