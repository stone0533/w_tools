/// Map 扩展：按键排序与合并
extension WMapExtension<K, V> on Map<K, V> {
  /// 按键排序并返回新 Map
  ///
  /// 未传 [compare] 时：键实现 [Comparable] 则按 `compareTo` 排序，
  /// 否则回退为字符串比较。
  Map<K, V> sortedByKeys([int Function(K, K)? compare]) {
    final sortedKeys = keys.toList();
    if (compare != null) {
      sortedKeys.sort(compare);
    } else {
      // 键不一定实现 Comparable，此时回退到字符串比较，避免运行期类型转换失败
      sortedKeys.sort((a, b) {
        if (a is Comparable && b is Comparable) {
          return a.compareTo(b);
        }
        return a.toString().compareTo(b.toString());
      });
    }
    return Map<K, V>.fromEntries(sortedKeys.map((key) => MapEntry<K, V>(key, this[key] as V)));
  }

  /// 将 [other] 合并到当前 Map
  ///
  /// [overwrite] 为 true（默认）时覆盖已存在的键。
  /// 原地修改并返回自身；不可变 Map 会抛 [UnsupportedError]。
  Map<K, V> merge(Map<K, V> other, {bool overwrite = true}) {
    other.forEach((key, value) {
      if (overwrite || !containsKey(key)) {
        this[key] = value;
      }
    });
    return this;
  }
}
