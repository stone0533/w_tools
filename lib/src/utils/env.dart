import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 环境配置管理工具类
class WEnv {
  /// 获取配置值
  ///
  /// @param key 配置键
  /// @param defaultValue 默认值
  /// @return 配置值
  static String get(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// 获取布尔类型配置值
  ///
  /// @param key 配置键
  /// @param defaultValue 默认值
  /// @return 布尔类型配置值
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  /// 获取整数类型配置值
  ///
  /// @param key 配置键
  /// @param defaultValue 默认值
  /// @return 整数类型配置值
  static int getInt(String key, {int defaultValue = 0}) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// 获取双精度浮点数类型配置值
  ///
  /// @param key 配置键
  /// @param defaultValue 默认值
  /// @return 双精度浮点数类型配置值
  static double getDouble(String key, {double defaultValue = 0.0}) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  /// 检查配置是否存在
  ///
  /// @param key 配置键
  /// @return 配置是否存在
  static bool containsKey(String key) {
    return dotenv.env.containsKey(key);
  }

  /// 获取所有配置
  ///
  /// @return 所有配置
  static Map<String, String> getAll() {
    return dotenv.env;
  }
}
