import 'package:flutter/foundation.dart';

/// E2E 日志标记：给设备黑盒脚本一个稳定的等待点。
///
/// `E2eLogin.run` 的 `[E2E] auto login ok` 只表示**登录接口返回**，不代表
/// 页面 / 首屏数据就绪；App 应在「登录 + 首屏数据就绪」后调用
/// [E2eSignals.ready]，黑盒再开始点击。
///
/// ```dart
/// E2eSignals.ready('home');
/// // 输出：[E2E] ready home
/// ```
abstract final class E2eSignals {
  /// 就绪行的固定前缀；黑盒脚本应匹配这一行。
  static const String readyPrefix = '[E2E] ready';

  /// 打一行就绪标记；`detail` 用于区分页面 / 场景。
  static void ready([String detail = '']) {
    final suffix = detail.trim();
    debugPrint(suffix.isEmpty ? readyPrefix : '$readyPrefix $suffix');
  }

  /// 与 [ready] 输出一致的文本（测试 / 自定义输出用）。
  static String readyLine([String detail = '']) {
    final suffix = detail.trim();
    return suffix.isEmpty ? readyPrefix : '$readyPrefix $suffix';
  }
}
