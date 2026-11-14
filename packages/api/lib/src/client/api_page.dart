/// 分页请求参数。
///
/// [pageKey] / [pageSizeKey] 用于适配不同后端的参数名（默认 `page` / `pageSize`）。
/// 只支持 1-based 页码分页；offset / limit 或 cursor 分页请用 `WApiClient.send`
/// 手工请求并自行构造 `WPage`。
class WPageQuery {
  /// 创建分页参数；页码从 1 开始。
  const WPageQuery({
    this.page = 1,
    this.pageSize = 20,
    this.pageKey = 'page',
    this.pageSizeKey = 'pageSize',
  }) : assert(page >= 1, 'page 从 1 开始'),
       assert(pageSize >= 1, 'pageSize 必须大于 0');

  /// 页码（从 1 开始）
  final int page;

  /// 每页条数
  final int pageSize;

  /// 页码参数名
  final String pageKey;

  /// 每页条数参数名
  final String pageSizeKey;

  /// 转成 query 参数
  Map<String, Object?> toQuery() => {pageKey: page, pageSizeKey: pageSize};
}

/// 一页数据 + 是否还有更多。
class WPage<T> {
  /// 创建分页结果。
  const WPage({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
  });

  /// 当前页数据
  final List<T> items;

  /// 当前页码（从 1 开始）
  final int page;

  /// 每页条数
  final int pageSize;

  /// 总条数；服务端不返回时为 null
  final int? total;

  /// 是否还有下一页。
  ///
  /// 有 [total] 时按 `page * pageSize < total` 计算；没有时按「本页是否满页」判断。
  /// 服务端若把 pageSize 截得比请求小，按满页判断可能提前结束；这种场景请让后端
  /// 返回 total，或改用 `readTotal`。
  bool get hasMore {
    final total = this.total;
    if (total != null) return page * pageSize < total;
    return items.length >= pageSize;
  }
}
