import 'dart:async';

import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 真实场景页：
/// - 提交订单：retry + timeout + cancel
/// - App 启动：parallel + WAsyncActivity
/// - 上传：pool 限流
/// - 搜索：tryRun + 旧请求取消
class ScenariosPage extends StatefulWidget {
  const ScenariosPage({super.key});

  @override
  State<ScenariosPage> createState() => _ScenariosPageState();
}

class _ScenariosPageState extends State<ScenariosPage> {
  final _logs = <String>[];
  bool _bootstrapping = false;
  int _submitAttempt = 0;
  int _searchSeq = 0;
  WCancelToken? _submitToken;
  WCancelToken? _searchToken;

  void _log(String message) {
    if (mounted) setState(() => _logs.insert(0, message));
  }

  Future<void> _submitOrder() async {
    _submitToken?.cancel('superseded');
    final token = _submitToken = WCancelToken();
    _submitAttempt = 0;

    try {
      final order = await WAsync.retry<String>(
        () => WAsync.timeout<String>(
          () => _fakeCreateOrder(token),
          const Duration(seconds: 2),
          cancelToken: token,
        ),
        retryCount: 2,
        retryDelay: const Duration(milliseconds: 200),
        retryIf: (error) => error is Exception,
        cancelToken: token,
      );
      _log('提交成功：$order');
    } on WCancellationException {
      _log('提交已取消');
    } on TimeoutException {
      _log('提交超时');
    } catch (error) {
      _log('提交失败：$error');
    } finally {
      if (identical(_submitToken, token)) _submitToken = null;
    }
  }

  Future<String> _fakeCreateOrder(WCancelToken token) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    token.throwIfCancelled();
    _submitAttempt++;
    if (_submitAttempt < 3) throw Exception('网络失败 #$_submitAttempt');
    return 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _cancelSubmit() {
    _submitToken?.cancel('用户取消');
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    final activity = WAsyncActivity(
      onStart: () {
        if (mounted) setState(() => _bootstrapping = true);
      },
      onEnd: () {
        if (mounted) setState(() => _bootstrapping = false);
      },
    );
    final options = WAsyncOptions(activity: activity);

    try {
      final values = await WAsync.parallel<String>(
        [
          Future.delayed(const Duration(milliseconds: 300), () => '配置'),
          Future.delayed(const Duration(milliseconds: 200), () => '用户'),
          Future.delayed(const Duration(milliseconds: 400), () => '通知'),
        ],
        options: options,
      );
      _log('启动完成：${values.join(' / ')}');
    } on WCancellationException {
      _log('启动已取消');
    } catch (error) {
      _log('启动失败：$error');
    }
  }

  Future<void> _upload() async {
    final token = WCancelToken();
    try {
      final results = await WAsync.pool<String>(
        List.generate(6, (index) {
          return () async {
            await Future<void>.delayed(Duration(milliseconds: 150 + index * 30));
            token.throwIfCancelled();
            return '文件 $index';
          };
        }),
        concurrency: 2,
        cancelToken: token,
      );
      _log('上传完成：${results.join('、')}');
    } on WCancellationException {
      _log('上传已取消');
    } catch (error) {
      _log('上传失败：$error');
    }
  }

  Future<void> _search() async {
    _searchToken?.cancel('superseded');
    final token = _searchToken = WCancelToken();
    final seq = ++_searchSeq;

    final result = await WAsync.tryRun<String>(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        token.throwIfCancelled();
        return '搜索结果 #$seq';
      },
      cancelToken: token,
    );

    if (!identical(token, _searchToken)) return;

    switch (result) {
      case WAsyncSuccess(:final value):
        _log(value);
      case WAsyncFailure(:final error, :final stackTrace):
        _log('搜索失败：$error');
        debugPrint('$stackTrace');
      case WAsyncCancelled():
        _log('搜索已取消');
    }
  }

  @override
  void dispose() {
    _submitToken?.cancel('page disposed');
    _searchToken?.cancel('page disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('真实场景'),
        actions: [
          if (_bootstrapping)
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
            'WAsync 只负责执行；页面四态仍交给 WAsyncController + WAsyncView。',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          if (_logs.isEmpty)
            const Text('点击按钮查看场景结果')
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
          const SizedBox(height: 16),
          _ScenarioCard(
            title: '提交订单',
            subtitle: 'retry + timeout + cancel',
            actions: [
              FilledButton(
                onPressed: _submitOrder,
                child: const Text('提交'),
              ),
              OutlinedButton(
                onPressed: _cancelSubmit,
                child: const Text('取消提交'),
              ),
            ],
          ),
          _ScenarioCard(
            title: 'App 启动',
            subtitle: 'parallel + WAsyncActivity',
            actions: [
              FilledButton.tonal(
                onPressed: _bootstrap,
                child: const Text('并行加载'),
              ),
            ],
          ),
          _ScenarioCard(
            title: '上传文件',
            subtitle: 'pool(concurrency: 2)',
            actions: [
              FilledButton.tonal(
                onPressed: _upload,
                child: const Text('开始上传'),
              ),
            ],
          ),
          _ScenarioCard(
            title: '搜索',
            subtitle: 'tryRun + 旧请求取消',
            actions: [
              FilledButton.tonal(
                onPressed: _search,
                child: const Text('搜索'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
