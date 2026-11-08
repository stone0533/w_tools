import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 三、WAsyncStateSliver：CustomScrollView 里的四态 sliver。
class SliverPage extends StatefulWidget {
  const SliverPage({super.key});

  @override
  State<SliverPage> createState() => _SliverPageState();
}

class _SliverPageState extends State<SliverPage> {
  late final WAsyncController<List<String>> _controller;
  bool _failNext = false;

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
      throw Exception('模拟 sliver 加载失败');
    }
    return List.generate(8, (index) => 'Sliver 数据 ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Sliver 列表'),
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
            ],
          ),
          WAsyncStateSliver<List<String>>(
            state: _controller.state,
            onRetry: _controller.load,
            readySliverBuilder: (context, items) => SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.view_day_outlined),
                title: Text(items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
