import 'dart:collection';

import 'app_plugin.dart';

/// `WAppPlugin` 的注册表与分层初始化器。
///
/// 只负责插件依赖图与生命周期，不依赖 GetX；任何应用壳都可以复用它。
/// 插件列表在构造时确定，[init] 之后不再修改。
class WAppPluginRunner {
  WAppPluginRunner([Iterable<WAppPlugin> plugins = const []]) : _plugins = <WAppPlugin>[...plugins];

  final List<WAppPlugin> _plugins;
  final Set<String> _completed = <String>{};
  bool _initialized = false;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => UnmodifiableListView<WAppPlugin>(_plugins);

  /// 按 [WAppPlugin.dependsOn] 分层执行 [WAppPlugin.onInit]。
  ///
  /// 同层按注册顺序串行、跨层串行；某个 onInit 抛错会立即中断本次 init。
  /// 插件 name 重复、依赖未注册、循环依赖时抛 [StateError]。
  ///
  /// 失败后可以重试：已经成功的插件不会重复执行，从失败点继续。
  Future<void> init() async {
    if (_initialized) return;
    if (_plugins.isEmpty) {
      _initialized = true;
      return;
    }

    final names = _plugins.map((plugin) => plugin.name).toSet();
    if (names.length != _plugins.length) {
      throw StateError('插件 name 必须唯一');
    }

    for (final plugin in _plugins) {
      for (final dependency in plugin.dependsOn) {
        if (!names.contains(dependency)) {
          throw StateError(
            '插件 "${plugin.name}" 依赖了未注册的插件 "$dependency"',
          );
        }
      }
    }

    final done = <String>{..._completed};
    final pending = _plugins.where((plugin) => !done.contains(plugin.name)).toList();

    while (pending.isNotEmpty) {
      final ready = pending
          .where((plugin) => plugin.dependsOn.every(done.contains))
          .toList(growable: false);
      if (ready.isEmpty) {
        throw StateError(
          '插件存在循环依赖：${pending.map((plugin) => plugin.name).join(", ")}',
        );
      }

      for (final plugin in ready) {
        await plugin.onInit();
        _completed.add(plugin.name);
        done.add(plugin.name);
      }

      pending.removeWhere((plugin) => done.contains(plugin.name));
    }

    _initialized = true;
  }
}
