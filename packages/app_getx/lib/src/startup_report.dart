import 'package:w_tools_app/w_tools_app.dart';

/// 一次启动的耗时与插件结果。
///
/// `WApp.startupReport` 在 `init` 结束（成功或失败）后可用；
/// [firstFrameDuration] 在首帧回调里稍后填入（`init()` 后单独调用、
/// 没有 frame 时为 null）。
class WAppStartupReport {
  WAppStartupReport({
    required List<WAppPluginRun> pluginRuns,
    required this.pluginsDuration,
    required this.customTasksDuration,
    required this.initDuration,
  }) : pluginRuns = List<WAppPluginRun>.unmodifiable(pluginRuns);

  /// 本次 init 的插件执行记录（按执行顺序）；重试时只保留最近一轮。
  final List<WAppPluginRun> pluginRuns;

  /// 插件初始化总耗时。
  final Duration pluginsDuration;

  /// `customTasks` 总耗时；没有 customTasks 时为 0。
  final Duration customTasksDuration;

  /// `init` 总耗时（不含首帧等待）。
  final Duration initDuration;

  Duration? _firstFrameDuration;

  /// 从 init 开始到首帧绘制完成的耗时；首帧前为 null。
  Duration? get firstFrameDuration => _firstFrameDuration;

  /// 是否已经记录首帧耗时。
  bool get hasFirstFrame => _firstFrameDuration != null;

  /// 失败的插件记录。
  Iterable<WAppPluginRun> get failures => pluginRuns.where((run) => !run.ok);

  /// 由 `WApp` 在首帧回调里写入；重复调用只保留第一次。
  void markFirstFrame(Duration duration) {
    _firstFrameDuration ??= duration;
  }

  @override
  String toString() =>
      'WAppStartupReport(init: ${initDuration.inMilliseconds}ms, '
      'plugins: ${pluginsDuration.inMilliseconds}ms, '
      'customTasks: ${customTasksDuration.inMilliseconds}ms, '
      'firstFrame: ${_firstFrameDuration?.inMilliseconds ?? '-'}ms, '
      'failures: ${failures.map((run) => run.name).join(', ')})';
}
