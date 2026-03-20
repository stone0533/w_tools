/// Map 扩展类，提供按键排序的功能
extension SortedMapExtension on Map {
  /// 按键对 Map 进行排序
  ///
  /// @return 按键排序后的新 Map
  /// @description 将 Map 的键转换为列表并排序，然后根据排序后的键创建新的 Map
  Map sortedByKeys() {
    final sortedKeys = keys.toList()..sort();
    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, this[key])));
  }
}
