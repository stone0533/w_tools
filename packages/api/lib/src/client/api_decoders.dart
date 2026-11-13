/// 把 JSON 转成业务模型的显式解码函数。
///
/// Dart / Flutter 没有反射，`get<User>()` 不会自动调用 `User.fromJson`；
/// 必须把映射显式传给 `decode`（或用 json_serializable / freezed 生成）。
typedef WApiDecoder<T> = T Function(Object? json);

/// 常用 decoder 辅助。
abstract final class WApiDecoders {
  /// 忽略响应体（DELETE / 204 用）。
  static WApiDecoder<void> get none => (json) {};

  /// 直接返回 `Map<String, dynamic>`（不做字段映射）。
  static WApiDecoder<Map<String, dynamic>> get jsonMap =>
      (json) => json as Map<String, dynamic>;

  /// JSON 数组 → `List<T>`。
  static WApiDecoder<List<T>> listOf<T>(WApiDecoder<T> itemDecode) =>
      (json) => (json as List).map(itemDecode).toList();

  /// 允许响应体为 null 的 decoder。
  static WApiDecoder<T?> nullable<T>(WApiDecoder<T> itemDecode) =>
      (json) => json == null ? null : itemDecode(json);
}
