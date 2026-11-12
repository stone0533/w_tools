import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  test('分页追加 100k 条不会退化为整表复制', () async {
    const pageSize = 200;
    const pageCount = 500;

    final controller = WAsyncPagedController<int>((page) async {
      if (page > pageCount) return const <int>[];
      final start = (page - 1) * pageSize;
      return List<int>.generate(pageSize, (index) => start + index);
    });
    addTearDown(controller.dispose);

    final watch = Stopwatch()..start();
    await controller.refresh();
    while (controller.page <= pageCount) {
      await controller.loadMore();
    }
    watch.stop();

    expect(controller.state.value.data, hasLength(pageCount * pageSize));
    expect(
      watch.elapsed,
      lessThan(const Duration(seconds: 10)),
      reason: '100k 条追加应保持 chunked 结构共享；超过预算说明退化为整表复制',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
