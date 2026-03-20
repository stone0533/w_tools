/// 插件接口
abstract class WPlugin {
  /// 插件名称
  String get name;

  /// 初始化插件
  Future<void> initialize();

  /// 销毁插件
  Future<void> dispose();

  /// 插件版本
  String get version;
}
