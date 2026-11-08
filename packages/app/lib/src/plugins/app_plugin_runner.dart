import 'dart:collection';

import 'app_plugin.dart';

/// `WAppPlugin` 的注册表与分层初始化器。
///
/// 只负责插件依赖图与生命周期，不依赖 GetX；任何应用壳都可以复用它。
class WAppPluginRunner {
  WAppPluginRunner([Iterable<WAppPlugin> plugins = const []]) : _plugins = <WAppPlugin>[...plugins];

  final List<WAppPlugin> _plugins;
  bool _initialized = false;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => UnmodifiableListView<WAppPlugin>(_plugins);

  void addPlugin(WAppPlugin plugin) {
    _ensureEditable('addPlugin');
    _plugins.add(plugin);
  }

  void addPlugins(Iterable<WAppPlugin> plugins) {
    _ensureEditable('addPlugins');
    _plugins.addAll(plugins);
  }

  void removePlugin(String name) {
    _ensureEditable('removePlugin');
    _plugins.removeWhere((plugin) => plugin.name == name);
  }

  void clearPlugins() {
    _ensureEditable('clearPlugins');
    _plugins.clear();
  }

  /// 按 [WAppPlugin.dependsOn] 分层执行 [WAppPlugin.onInit]。
  ///
  /// 同层并行、跨层串行；插件 name 重复、依赖未注册、循环依赖时抛 [StateError]。
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

    final done = <String>{};
    final pending = <WAppPlugin>[..._plugins];

    while (pending.isNotEmpty) {
      final ready = pending
          .where((plugin) => plugin.dependsOn.every(done.contains))
          .toList(growable: false);
      if (ready.isEmpty) {
        throw StateError(
          '插件存在循环依赖：${pending.map((plugin) => plugin.name).join(", ")}',
        );
      }

      await Future.wait(ready.map((plugin) => plugin.onInit()));
      done.addAll(ready.map((plugin) => plugin.name));
      pending.removeWhere(ready.contains);
    }

    _initialized = true;
  }

  void _ensureEditable(String action) {
    if (_initialized) {
      throw StateError('$action() 必须在 init() 之前调用');
    }
  }
}
