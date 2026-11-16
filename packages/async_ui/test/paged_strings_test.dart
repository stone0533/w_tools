import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

void main() {
  test('WAsyncPagedStrings 默认值和相等性', () {
    const a = WAsyncPagedStrings();
    const b = WAsyncPagedStrings();
    const c = WAsyncPagedStrings(noMore: '没有更多');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.noMore, 'No more data');
    expect(c.noMore, '没有更多');
    expect(c, isNot(a));
  });
}
