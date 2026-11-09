import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 二、WAsyncPagedController：首屏、loadMore、hasMore、追加失败。
class PagedPage extends StatefulWidget {
  const PagedPage({super.key});

  @override
  State<PagedPage> createState() => _PagedPageState();
}

class _PagedPageState extends State<PagedPage> {
  late final WAsyncPagedController<String> _controller;
  bool _failNextPage = false;

  @override
  void initState() {
    super.initState();
    _controller = WAsyncPagedController<String>(_loadPage);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<String>> _loadPage(int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_failNextPage) {
      _failNextPage = false;
      throw Exception('第 $page 页加载失败');
    }
    if (page > 3) return const [];
    return List.generate(2, (index) => '第 $page 页 · ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分页列表'),
        actions: [
          IconButton(
            tooltip: '刷新第一页',
            onPressed: _controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '下一页失败',
            onPressed: () {
              _failNextPage = true;
              _controller.loadMore();
            },
            icon: const Icon(Icons.error_outline_rounded),
          ),
        ],
      ),
      body: WAsyncView<List<String>>(
        state: _controller.state,
        onRetry: _controller.refresh,
        readyBuilder: (context, items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index < items.length) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(items[index]),
                ),
              );
            }
            return _Footer(controller: _controller);
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final WAsyncPagedController<String> controller;

  @override
  Widget build(BuildContext context) {
    // isLoadingMore 在每次 loadMore 前后翻转，footer 会随之重建；
    // 若 footer 只由 state 驱动，必须额外监听 controller.hasMoreListenable。
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoadingMore,
      builder: (context, loading, _) {
        return ValueListenableBuilder<Object?>(
          valueListenable: controller.loadMoreError,
          builder: (context, error, _) {
            return Column(
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '追加失败：$error',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                TextButton(
                  onPressed: loading || !controller.hasMore ? null : controller.loadMore,
                  child: Text(
                    loading
                        ? '加载中...'
                        : controller.hasMore
                        ? '加载更多'
                        : '没有更多',
                  ),
                ),
                // hasLoadedMoreThanOnePage 区分「首屏还没翻过页」和「已翻过页」，
                // 不用自己拿 state.data.length 变大去猜（失败路径上长度不变）。
                Text(
                  controller.hasLoadedMoreThanOnePage ? '已加载多页' : '仅第一页',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
