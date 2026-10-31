import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 五、WAsyncStateBuilder：自己控制状态 UI，但保持同一个滚动壳。
class StateBuilderPage extends StatefulWidget {
  const StateBuilderPage({super.key});

  @override
  State<StateBuilderPage> createState() => _StateBuilderPageState();
}

class _StateBuilderPageState extends State<StateBuilderPage> {
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_failNext) {
      _failNext = false;
      throw Exception('自定义失败');
    }
    return List.generate(6, (index) => 'Builder 数据 ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('状态构建器'),
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
      body: WAsyncStateBuilder<List<String>>(
        state: _controller.state,
        // builder 始终返回同一个滚动壳；四态只作为 ListView 内容。
        builder: (context, state) => RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: state.when(
              loading: () => const [
                SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              ready: (items) => [
                for (final item in items)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: Text(item),
                    ),
                  ),
              ],
              empty: () => const [
                SizedBox(
                  height: 320,
                  child: Center(child: Text('自定义空状态')),
                ),
              ],
              failed: (error) => [
                SizedBox(
                  height: 320,
                  child: WAsyncErrorView(
                    error: error,
                    onRetry: _controller.load,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
