import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'paged_strings.dart';

/// 分页 footer 的纯展示组件；由 [WAsyncPagedList] / [WAsyncPagedSliver] 内部使用。
///
/// 状态来自 [WAsyncPagedSnapshot.footerStatus]；不要由调用方自己拼
/// data / error / hasMore。
class WAsyncPagedFooter extends StatelessWidget {
  const WAsyncPagedFooter({
    super.key,
    required this.status,
    this.strings = const WAsyncPagedStrings(),
    this.onRetry,
  });

  final WAsyncPagedFooterStatus status;
  final WAsyncPagedStrings strings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    switch (status) {
      case WAsyncPagedFooterStatus.hidden:
        return const SizedBox.shrink();
      case WAsyncPagedFooterStatus.loading:
        return SizedBox(
          height: 56,
          child: Center(
            child: Semantics(
              label: strings.loading,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      case WAsyncPagedFooterStatus.failed:
        return SizedBox(
          height: 56,
          child: Center(
            child: TextButton(
              onPressed: onRetry,
              child: Text('${strings.failed} · ${strings.retry}', style: style),
            ),
          ),
        );
      case WAsyncPagedFooterStatus.noMore:
        return SizedBox(
          height: 56,
          child: Center(child: Text(strings.noMore, style: style)),
        );
      case WAsyncPagedFooterStatus.loadMore:
        return SizedBox(
          height: 56,
          child: Center(child: Text(strings.loadMore, style: style)),
        );
    }
  }
}
