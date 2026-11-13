# 分页列表测试 recipe

`WAsyncPagedController` 的测试不需要每个项目重写一套 fake。先复制下面的本地
harness；它只依赖 `WAsyncPage` / `WAsyncPagedController`，不进入 runtime API。

## 本地 harness

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

class PagedHarness<T> {
  PagedHarness({
    required this.pages,
    this.errors = const {},
    this.total,
    this.pageSize = 10,
  });

  final List<List<T>> pages;
  final Map<int, Object> errors;
  final int? total;
  final int pageSize;
  final calls = <int>[];

  Future<WAsyncPage<T>> load(int page) async {
    calls.add(page);
    final error = errors[page];
    if (error != null) throw error;

    final items = page <= pages.length ? pages[page - 1] : const <T>[];
    return WAsyncPage<T>.fromTotal(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }
}
```

## 标准用例

```dart
group('分页 controller', () {
  test('第一页不足一页：hasMore=false，不再请求第二页', () async {
    final harness = PagedHarness<int>(
      pages: const [
        [1, 2, 3],
      ],
      total: 3,
    );
    final controller = WAsyncPagedController<int>.withPage(harness.load);
    addTearDown(controller.dispose);

    await controller.refresh();
    expect(controller.hasMore, isFalse);
    expect(controller.footerStatus, WAsyncPagedFooterStatus.hidden);

    await controller.loadMore();
    expect(harness.calls, [1]);
  });

  test('第二页空：hasMore=false，旧数据保留', () async {
    final harness = PagedHarness<int>(
      pages: const [
        [1, 2],
        [],
      ],
    );
    final controller = WAsyncPagedController<int>.withPage(harness.load);
    addTearDown(controller.dispose);

    await controller.refresh();
    await controller.loadMore();
    expect(controller.state.value.data, [1, 2]);
    expect(controller.hasMore, isFalse);
  });

  test('loadMore 失败：保留旧数据，写 loadMoreError', () async {
    final harness = PagedHarness<int>(
      pages: const [
        [1],
        [2],
      ],
      errors: {2: StateError('network')},
    );
    final controller = WAsyncPagedController<int>.withPage(harness.load);
    addTearDown(controller.dispose);

    await controller.refresh();
    await controller.loadMore();
    expect(controller.state.value.data, [1]);
    expect(controller.loadMoreError.value, isA<StateError>());
  });

  test('refresh 取代在飞 loadMore：旧结果不写回', () async {
    final page2 = Completer<List<int>>();
    var calls = 0;
    final controller = WAsyncPagedController<int>.withPage((page) async {
      calls++;
      if (page == 1) return const WAsyncPage(items: [1], hasMore: true);
      return WAsyncPage(items: await page2.future, hasMore: true);
    });
    addTearDown(controller.dispose);

    await controller.refresh();
    final loading = controller.loadMore();
    await controller.refresh();
    page2.complete(const [2]);
    await loading;

    expect(controller.state.value.data, [1]);
    expect(calls, 3);
  });

  test('total 为 null：回退旧行为', () async {
    final harness = PagedHarness<int>(
      pages: const [
        [1],
      ],
      total: null,
    );
    final controller = WAsyncPagedController<int>.withPage(harness.load);
    addTearDown(controller.dispose);

    await controller.refresh();
    expect(controller.hasMore, isTrue, reason: '本页非空且 total 未知');
  });
});
```

## 注意

- 用 `withPage` + `WAsyncPage.fromTotal`，不要自己重复 `page * pageSize < total`；
- `total` 是**总条数**，不是剩余条数；`page` 从 1 开始；
- `total == null` 时 `hasMore` 为 null，控制器回退“本页非空即有更多”；
- footer 状态直接断言 `controller.footerStatus`，不要只测 `state.data.length`；
- 不要把这个 harness 放进 `w_tools_async` 的 runtime 导出；需要跨项目复用时再单独评估。
