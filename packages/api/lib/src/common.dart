import 'package:flutter/foundation.dart';

/// API 路径契约：定义如何获取基础 URL
///
/// 扩展点——供使用方实现，库内部不强依赖；请勿因「无内部引用」而删除。
abstract class IApiPath {
  /// 基础 URL
  String get baseUrl;
}

/// API 客户端标识符（不可变），用于区分多个 API 客户端
@immutable
class ApiClientId {
  /// 创建客户端标识符
  const ApiClientId(this.name);

  /// 客户端名称
  final String name;
}
