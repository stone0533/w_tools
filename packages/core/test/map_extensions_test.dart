import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

/// core 的 Map 扩展。
///
/// 其余扩展（Color / String / Num / Widget / WRow / WPadding 等）属于 w_tools_ui，
/// 见 packages/ui/test/extensions_test.dart。
void main() {
  group('Map Extensions', () {
    test('Map.sortedByKeys - 默认排序', () {
      final map = {'b': 2, 'a': 1, 'c': 3};
      final sorted = map.sortedByKeys();
      expect(sorted.keys.toList(), ['a', 'b', 'c']);
    });

    test('Map.sortedByKeys - 自定义排序', () {
      final map = {'b': 2, 'a': 1, 'c': 3};
      final sorted = map.sortedByKeys((a, b) => b.compareTo(a));
      expect(sorted.keys.toList(), ['c', 'b', 'a']);
    });

    test('Map.sortedByKeys - 空Map', () {
      final map = <String, int>{};
      final sorted = map.sortedByKeys();
      expect(sorted.isEmpty, isTrue);
    });

    test('Map.merge - 默认覆盖', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      map1.merge(map2);
      expect(map1, {'a': 1, 'b': 3, 'c': 4});
    });

    test('Map.merge - 不覆盖', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      map1.merge(map2, overwrite: false);
      expect(map1, {'a': 1, 'b': 2, 'c': 4});
    });

    test('Map.merge - 空Map合并', () {
      final map1 = {'a': 1};
      final map2 = <String, int>{};
      map1.merge(map2);
      expect(map1, {'a': 1});

      final map3 = <String, int>{};
      final map4 = {'b': 2};
      map3.merge(map4);
      expect(map3, {'b': 2});
    });
  });
}
