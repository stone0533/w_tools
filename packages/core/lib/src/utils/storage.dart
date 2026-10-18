import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import 'logger.dart';

/// 基于 SharedPreferences 的静态工具类，用于本地存储操作
///
/// 提供了多种类型数据的存储和读取方法，包括：
/// - 基本类型：字符串、整数、布尔值、双精度浮点数
/// - 复杂类型：字符串列表、对象（通过 JSON 序列化）
/// - 管理操作：删除、清除、检查键是否存在、获取所有键
///
/// 写方法返回 `bool`，表示是否写入成功。
/// 使用前需先调用 [init]（写方法会自动初始化）；读取方法在未初始化时会
/// 抛出 [StateError]，避免把「未初始化」误判为「没有数据」。
class WStorage {
  // 纯静态工具类，禁止实例化
  WStorage._();

  /// SharedPreferences 实例
  static SharedPreferences? _prefs;

  /// 初始化锁，避免并发调用时重复创建实例
  static final Lock _initLock = Lock();

  // ============== 初始化相关 ==============

  /// 初始化 SharedPreferences
  ///
  /// 幂等：已初始化时直接返回；初始化失败会向调用方抛出异常。
  static Future<void> init() async {
    await _initLock.synchronized(() async {
      if (_prefs != null) return;
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        _prefs = null;
        rethrow;
      }
    });
  }

  /// SharedPreferences 实例
  ///
  /// 未初始化时抛出 [StateError]，请先调用 [init]。
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SharedPreferences not initialized. Call WStorage.init() first.');
    }
    return _prefs!;
  }

  /// 检查是否已初始化
  static bool get isInitialized => _prefs != null;

  // ============== 字符串操作 ==============

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return _prefs!.setString(key, value);
  }

  /// 读取字符串
  static String? getString(String key, {String? defaultValue}) {
    return prefs.getString(key) ?? defaultValue;
  }

  // ============== 整数操作 ==============

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return _prefs!.setInt(key, value);
  }

  /// 读取整数
  static int? getInt(String key, {int? defaultValue}) {
    return prefs.getInt(key) ?? defaultValue;
  }

  // ============== 布尔值操作 ==============

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return _prefs!.setBool(key, value);
  }

  /// 读取布尔值
  static bool? getBool(String key, {bool? defaultValue}) {
    return prefs.getBool(key) ?? defaultValue;
  }

  // ============== 双精度浮点数操作 ==============

  /// 存储双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    return _prefs!.setDouble(key, value);
  }

  /// 读取双精度浮点数
  static double? getDouble(String key, {double? defaultValue}) {
    return prefs.getDouble(key) ?? defaultValue;
  }

  // ============== 字符串列表操作 ==============

  /// 存储字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    return _prefs!.setStringList(key, value);
  }

  /// 读取字符串列表
  static List<String>? getStringList(String key, {List<String>? defaultValue}) {
    return prefs.getStringList(key) ?? defaultValue;
  }

  // ============== 对象操作（JSON 序列化） ==============

  /// 存储对象
  ///
  /// 非字符串对象会先 `jsonEncode`；编码失败时记录日志并返回 false。
  static Future<bool> setObject(String key, dynamic value) async {
    await _ensureInitialized();
    try {
      final jsonString = value is String ? value : jsonEncode(value);
      return _prefs!.setString(key, jsonString);
    } catch (e) {
      WLogger.e('WStorage.setObject($key) failed: $e');
      return false;
    }
  }

  /// 读取对象（将 JSON 字符串转换为对象）
  ///
  /// 仅支持 `jsonDecode` 可直接得到的类型（`Map` / `List` / `String` /
  /// `num` / `bool`）；自定义模型请先读取 `Map<String, dynamic>` 再自行 `fromJson`。
  /// 键不存在、类型不匹配或解析失败时返回 [defaultValue]。
  static T? getObject<T>(String key, {T? defaultValue}) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return defaultValue;

    try {
      final dynamic result = jsonDecode(jsonString);
      if (result is T) return result;
      WLogger.w('WStorage.getObject($key): type mismatch, expected $T, got ${result.runtimeType}');
      return defaultValue;
    } catch (e) {
      WLogger.e('WStorage.getObject($key) failed: $e');
      return defaultValue;
    }
  }

  // ============== 管理操作 ==============

  /// 删除指定键的数据
  static Future<bool> remove(String key) async {
    await _ensureInitialized();
    return _prefs!.remove(key);
  }

  /// 清除所有数据
  static Future<bool> clear() async {
    await _ensureInitialized();
    return _prefs!.clear();
  }

  /// 检查是否存在指定键的数据
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  /// 获取所有键
  static Set<String> allKeys() {
    return prefs.getKeys();
  }

  // ============== 私有方法 ==============

  /// 确保 SharedPreferences 已初始化
  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}
