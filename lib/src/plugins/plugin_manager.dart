import 'plugin.dart';
import '../utils/logger.dart';

/// 插件管理器
class WPluginManager {
  /// 单例实例
  static final WPluginManager _instance = WPluginManager._internal();

  /// 插件列表
  final Map<String, WPlugin> _plugins = {};

  /// 构造函数
  factory WPluginManager() {
    return _instance;
  }

  /// 内部构造函数
  WPluginManager._internal();

  /// 注册插件
  void registerPlugin(WPlugin plugin) {
    _plugins[plugin.name] = plugin;
  }

  /// 初始化所有插件
  Future<void> initializeAll() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.initialize();
      } catch (e) {
        WLogger.e('Failed to initialize plugin ${plugin.name}: $e');
      }
    }
  }

  /// 销毁所有插件
  Future<void> disposeAll() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.dispose();
      } catch (e) {
        WLogger.e('Failed to dispose plugin ${plugin.name}: $e');
      }
    }
  }

  /// 获取插件
  T? getPlugin<T extends WPlugin>(String name) {
    return _plugins[name] as T?;
  }

  /// 获取所有插件
  List<WPlugin> getAllPlugins() {
    return _plugins.values.toList();
  }

  /// 移除插件
  void removePlugin(String name) {
    _plugins.remove(name);
  }

  /// 插件数量
  int get pluginCount => _plugins.length;
}
