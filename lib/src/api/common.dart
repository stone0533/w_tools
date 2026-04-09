import 'package:flutter/foundation.dart';

/// API 路径接口，定义获取基础 URL 的方法
abstract class IApiPath {
  /// 获取基础 URL
  String get baseUrl;
}

/// API 客户端标识符，用于标识不同的 API 客户端
@immutable
class ApiClientId {
  /// 创建 API 客户端标识符
  const ApiClientId(this.name);

  /// 客户端名称
  final String name;
}
