/// Map 扩展类，提供按键排序和合并的功能
extension WMapExtension<K, V> on Map<K, V> {
  /// 按键对 Map 进行排序
  ///
  /// @param compare 自定义排序函数，如果不提供则使用默认排序
  /// @return 按键排序后的新 Map
  /// @description 将 Map 的键转换为列表并排序，然后根据排序后的键创建新的 Map
  /// @example
  /// ```dart
  /// final map = {'b': 2, 'a': 1, 'c': 3};
  /// final sorted = map.sortedByKeys();
  /// print(sorted); // 输出: {'a': 1, 'b': 2, 'c': 3}
  /// 
  /// // 使用自定义排序函数
  /// final reverseSorted = map.sortedByKeys((a, b) => b.compareTo(a));
  /// print(reverseSorted); // 输出: {'c': 3, 'b': 2, 'a': 1}
  /// ```
  Map<K, V> sortedByKeys([int Function(K, K)? compare]) {
    final sortedKeys = keys.toList();
    if (compare != null) {
      sortedKeys.sort(compare);
    } else {
      sortedKeys.sort((a, b) => (a as Comparable).compareTo(b));
    }
    return Map<K, V>.fromEntries(sortedKeys.map((key) => MapEntry<K, V>(key, this[key] as V)));
  }

  /// 将另一个 Map 合并到当前 Map 中
  ///
  /// @param other 要合并的 Map
  /// @param overwrite 是否覆盖已存在的键值对，默认为 true
  /// @return 合并后的 Map
  /// @description 将另一个 Map 的键值对添加到当前 Map 中，如果键已存在且 overwrite 为 true，则覆盖原值
  /// @example
  /// ```dart
  /// // 基本用法
  /// final map1 = {'a': 1, 'b': 2};
  /// final map2 = {'b': 3, 'c': 4};
  /// map1.merge(map2);
  /// print(map1); // 输出: {'a': 1, 'b': 3, 'c': 4}
  /// 
  /// // 不覆盖已存在的键
  /// final map3 = {'a': 1, 'b': 2};
  /// final map4 = {'b': 3, 'c': 4};
  /// map3.merge(map4, overwrite: false);
  /// print(map3); // 输出: {'a': 1, 'b': 2, 'c': 4}
  /// ```
  Map<K, V> merge(Map<K, V> other, {bool overwrite = true}) {
    other.forEach((key, value) {
      if (overwrite || !containsKey(key)) {
        this[key] = value;
      }
    });
    return this;
  }
}
