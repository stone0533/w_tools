import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 一、WAsyncController + WAsyncView：页面区块四态。
class AsyncViewPage extends StatefulWidget {
  const AsyncViewPage({super.key});

  @override
  State<AsyncViewPage> createState() => _AsyncViewPageState();
}

class _AsyncViewPageState extends State<AsyncViewPage> {
  late final WAsyncController<List<String>> _controller;
  bool _failNext = false;
  bool _emptyNext = false;

  @override
  void initState() {
    super.initState();
    _controller = WAsyncController<List<String>>(_load);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<String>> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (_failNext) {
      _failNext = false;
      throw Exception('模拟网络错误');
    }
    if (_emptyNext) {
      _emptyNext = false;
      return const [];
    }
    return const ['异步数据 A', '异步数据 B', '异步数据 C'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('四态视图'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '下一次失败',
            onPressed: () {
              _failNext = true;
              _controller.load();
            },
            icon: const Icon(Icons.error_outline_rounded),
          ),
          IconButton(
            tooltip: '下一次为空',
            onPressed: () {
              _emptyNext = true;
              _controller.load();
            },
            icon: const Icon(Icons.inbox_outlined),
          ),
        ],
      ),
      body: WAsyncView<List<String>>(
        state: _controller.state,
        onRetry: _controller.load,
        readyBuilder: (context, items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(items[index]),
              subtitle: const Text('ready 状态内容'),
            ),
          ),
        ),
      ),
    );
  }
}
