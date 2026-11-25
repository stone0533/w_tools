import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'app_plugin.dart';
import 'app_plugin_run.dart';

/// `WAppPlugin` 的注册表与分层初始化器。
///
/// 只负责插件依赖图与生命周期，不依赖 GetX；任何应用壳都可以复用它。
/// 插件列表在构造时确定，[init] 之后不再修改。
class WAppPluginRunner {
  /// [plugins] 在构造时固定；[debugLogging] 为 true 时输出
  /// `[WApp] plugin <name> ...` 日志（`WApp` 会按 `startupLog` 传入）。
  WAppPluginRunner([
    Iterable<WAppPlugin> plugins = const [],
    bool debugLogging = false,
  ]) : _plugins = <WAppPlugin>[...plugins],
       _debugLogging = debugLogging;

  final List<WAppPlugin> _plugins;
  final bool _debugLogging;
  final Set<String> _completed = <String>{};
  final Set<String> _failed = <String>{};
  final List<WAppPluginRun> _runs = <WAppPluginRun>[];
  bool _initialized = false;
  bool _firstFrameDone = false;
  Duration? _totalDuration;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => UnmodifiableListView<WAppPlugin>(_plugins);

  /// 每次 [init] 里的插件执行记录（按执行顺序；重试会追加）。
  List<WAppPluginRun> get runs => UnmodifiableListView<WAppPluginRun>(_runs);

  /// 最近一次 [init] 的总耗时（含失败）。
  Duration? get totalDuration => _totalDuration;

  /// 按 [WAppPlugin.dependsOn] 分层执行 [WAppPlugin.onInit]。
  ///
  /// 同层按注册顺序串行、跨层串行。单个插件失败时：
  /// - [WAppPlugin.critical] 为 true（默认）→ 抛
  ///   [WAppPluginInitException]（带插件名，`cause` 保留原异常）；
  /// - 为 false → 记入 [runs]、继续下一个插件，依赖它的插件仍会执行。
  ///
  /// 插件 name 重复、依赖未注册、循环依赖时抛 [StateError]。
  /// 失败后可以重试：已经成功的插件不会重复执行，从失败点继续。
  Future<void> init() async {
    if (_initialized) return;
    if (_plugins.isEmpty) {
      _initialized = true;
      _totalDuration = Duration.zero;
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

    final stopwatch = Stopwatch()..start();
    final done = <String>{..._completed};
    final pending = _plugins.where((plugin) => !done.contains(plugin.name)).toList();

    try {
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
          final run = await _runOnInit(plugin);
          _runs.add(run);
          if (run.ok) {
            _completed.add(plugin.name);
            _failed.remove(plugin.name);
            done.add(plugin.name);
            continue;
          }
          if (plugin.critical) {
            throw WAppPluginInitException(
              pluginName: plugin.name,
              cause: run.error!,
              stackTrace: run.stackTrace!,
              timedOut: run.timedOut,
            );
          }
          // 非关键插件：记录失败后继续；依赖它的插件仍会执行。
          _failed.add(plugin.name);
          _completed.add(plugin.name);
          done.add(plugin.name);
        }

        pending.removeWhere((plugin) => done.contains(plugin.name));
      }

      _initialized = true;
    } finally {
      stopwatch.stop();
      _totalDuration = stopwatch.elapsed;
    }
  }

  /// 首帧之后逐个插件调用 [WAppPlugin.onFirstFrame]（幂等）。
  ///
  /// 失败隔离：单个插件抛错只记录，不中断其它插件，也不改变 [init] 的结果。
  /// 未成功初始化的插件（含关键/非关键失败）不会收到回调。
  Future<void> firstFrame() async {
    if (_firstFrameDone) return;
    _firstFrameDone = true;
    for (final plugin in _plugins) {
      if (!_completed.contains(plugin.name) || _failed.contains(plugin.name)) {
        continue;
      }
      try {
        await plugin.onFirstFrame();
      } catch (error) {
        _log('plugin ${plugin.name} onFirstFrame failed: $error');
      }
    }
  }

  Future<WAppPluginRun> _runOnInit(WAppPlugin plugin) async {
    final stopwatch = Stopwatch()..start();
    _log('plugin ${plugin.name} start');
    try {
      final init = plugin.onInit();
      final timeout = plugin.timeout;
      if (timeout == null) {
        await init;
      } else {
        await init.timeout(timeout);
      }
      stopwatch.stop();
      _log('plugin ${plugin.name} ${stopwatch.elapsedMilliseconds}ms ok');
      return WAppPluginRun(name: plugin.name, duration: stopwatch.elapsed);
    } on TimeoutException catch (error, stackTrace) {
      stopwatch.stop();
      _log(
        'plugin ${plugin.name} ${stopwatch.elapsedMilliseconds}ms timeout '
        '(${plugin.timeout})',
      );
      return WAppPluginRun(
        name: plugin.name,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        timedOut: true,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      _log(
        'plugin ${plugin.name} ${stopwatch.elapsedMilliseconds}ms failed: $error',
      );
      return WAppPluginRun(
        name: plugin.name,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _log(String message) {
    if (_debugLogging) debugPrint('[WApp] $message');
  }
}
