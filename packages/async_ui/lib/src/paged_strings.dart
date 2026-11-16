import 'package:flutter/foundation.dart';

/// 分页 footer 的文案。
///
/// 默认使用中性英文；项目可传入中文 / 其他语言。不要修改核心 `WAsyncStrings`。
@immutable
class WAsyncPagedStrings {
  const WAsyncPagedStrings({
    this.loading = 'Loading...',
    this.failed = 'Load failed',
    this.retry = 'Retry',
    this.noMore = 'No more data',
    this.loadMore = 'Pull up to load more',
  });

  final String loading;
  final String failed;
  final String retry;
  final String noMore;
  final String loadMore;

  @override
  bool operator ==(Object other) =>
      other is WAsyncPagedStrings &&
      other.loading == loading &&
      other.failed == failed &&
      other.retry == retry &&
      other.noMore == noMore &&
      other.loadMore == loadMore;

  @override
  int get hashCode => Object.hash(loading, failed, retry, noMore, loadMore);

  @override
  String toString() =>
      'WAsyncPagedStrings(loading: $loading, failed: $failed, retry: $retry, '
      'noMore: $noMore, loadMore: $loadMore)';
}
