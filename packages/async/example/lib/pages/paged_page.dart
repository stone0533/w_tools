import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 二、WAsyncPagedController：首屏、loadMore、hasMore、追加失败、本地替换。
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
            tooltip: '本地置顶最后一条',
            onPressed: () {
              final items = List<String>.of(
                _controller.state.value.data ?? const <String>[],
              );
              if (items.isEmpty) return;
              final last = items.removeLast();
              _controller.replaceData([last, ...items]);
            },
            icon: const Icon(Icons.vertical_align_top_rounded),
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
    return AnimatedBuilder(
      animation: controller.changes,
      builder: (context, _) {
        final status = controller.footerStatus;
        if (status == WAsyncPagedFooterStatus.hidden) {
          return const SizedBox.shrink();
        }

        final label = switch (status) {
          WAsyncPagedFooterStatus.loading => '加载中...',
          WAsyncPagedFooterStatus.failed => '重试',
          WAsyncPagedFooterStatus.noMore => '没有更多',
          WAsyncPagedFooterStatus.loadMore => '加载更多',
          WAsyncPagedFooterStatus.hidden => '',
        };
        final canLoad =
            status == WAsyncPagedFooterStatus.loadMore || status == WAsyncPagedFooterStatus.failed;

        return Column(
          children: [
            if (status == WAsyncPagedFooterStatus.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '追加失败：${controller.loadMoreError.value}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextButton(
              onPressed: canLoad ? controller.loadMore : null,
              child: Text(label),
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
  }
}
