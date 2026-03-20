import 'package:shared_preferences/shared_preferences.dart';

/// 基于 SharedPreferences 的静态工具类，用于本地存储操作
///
/// 提供了多种类型数据的存储和读取方法，包括：
/// - 基本类型：字符串、整数、布尔值、双精度浮点数
/// - 复杂类型：字符串列表、对象（通过 JSON 序列化）
/// - 管理操作：删除、清除、检查键是否存在、获取所有键
class WStorage {
  /// SharedPreferences 实例
  static SharedPreferences? _prefs;

  /// 初始化 SharedPreferences
  ///
  /// @return Future<void> 初始化完成的 Future
  /// @throws Exception 初始化失败时抛出异常
  static Future<void> init() async {
    // 避免重复初始化
    if (_prefs != null) {
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // 重置状态，确保下次可以重新初始化
      _prefs = null;
      rethrow;
    }
  }

  /// 获取 SharedPreferences 实例
  ///
  /// @return SharedPreferences 实例
  /// @throws Exception 如果未初始化，抛出异常
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized. Call WStorage.init() first.');
    }
    return _prefs!;
  }

  /// 存储字符串
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setString(String key, String value) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.setString(key, value);
  }

  /// 读取字符串
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在时返回
  /// @return String? 存储的值或默认值
  static String? getString(String key, {String? defaultValue}) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  /// 存储整数
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setInt(String key, int value) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.setInt(key, value);
  }

  /// 读取整数
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在时返回
  /// @return int? 存储的值或默认值
  static int? getInt(String key, {int? defaultValue}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  /// 存储布尔值
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.setBool(key, value);
  }

  /// 读取布尔值
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在时返回
  /// @return bool? 存储的值或默认值
  static bool? getBool(String key, {bool? defaultValue}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  /// 存储双精度浮点数
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setDouble(String key, double value) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.setDouble(key, value);
  }

  /// 读取双精度浮点数
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在时返回
  /// @return double? 存储的值或默认值
  static double? getDouble(String key, {double? defaultValue}) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  /// 存储字符串列表
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setStringList(String key, List<String> value) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.setStringList(key, value);
  }

  /// 读取字符串列表
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在时返回
  /// @return List<String>? 存储的值或默认值
  static List<String>? getStringList(String key, {List<String>? defaultValue}) {
    return _prefs?.getStringList(key) ?? defaultValue;
  }

  /// 存储对象（将对象转换为 JSON 字符串）
  ///
  /// @param key 存储键
  /// @param value 存储值
  /// @return Future<bool> 存储是否成功
  static Future<bool> setObject(String key, dynamic value) async {
    if (_prefs == null) {
      await init();
    }
    try {
      final jsonString = value is String ? value : _encodeObject(value);
      return _prefs!.setString(key, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// 读取对象（将 JSON 字符串转换为对象）
  ///
  /// @param key 存储键
  /// @param defaultValue 默认值，当键不存在或解析失败时返回
  /// @return dynamic 存储的对象或默认值
  static dynamic getObject(String key, {dynamic defaultValue}) {
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) {
      return defaultValue;
    }
    try {
      return _decodeObject(jsonString);
    } catch (e) {
      return defaultValue;
    }
  }

  /// 删除指定键的数据
  ///
  /// @param key 存储键
  /// @return Future<bool> 删除是否成功
  static Future<bool> remove(String key) async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.remove(key);
  }

  /// 清除所有数据
  ///
  /// @return Future<bool> 清除是否成功
  static Future<bool> clear() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!.clear();
  }

  /// 检查是否存在指定键的数据
  ///
  /// @param key 存储键
  /// @return bool 是否存在该键
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// 获取所有键
  ///
  /// @return Set<String>? 所有存储的键
  static Set<String>? getKeys() {
    return _prefs?.getKeys();
  }

  /// 编码对象为 JSON 字符串
  ///
  /// @param value 要编码的对象
  /// @return String 编码后的 JSON 字符串
  static String _encodeObject(dynamic value) {
    // 这里可以根据需要实现更复杂的对象编码逻辑
    // 例如使用 json.encode()
    return value.toString();
  }

  /// 解码 JSON 字符串为对象
  ///
  /// @param jsonString 要解码的 JSON 字符串
  /// @return dynamic 解码后的对象
  static dynamic _decodeObject(String jsonString) {
    // 这里可以根据需要实现更复杂的对象解码逻辑
    // 例如使用 json.decode()
    return jsonString;
  }
}
