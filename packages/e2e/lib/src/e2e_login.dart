import 'dart:async';

import 'package:flutter/foundation.dart';

import 'e2e_config.dart';

/// 用测试账号登录。
typedef E2eLoginCallback = Future<void> Function(String email, String password);

/// 免登录流程：调 [login] → [afterLogin]（一般是重建导航栈）。
class E2eLogin {
  const E2eLogin._();

  /// 返回是否登录成功；失败只回调 [onError] 并返回 false，**不抛异常**。
  static Future<bool> run({
    E2eConfig? config,
    required E2eLoginCallback login,
    FutureOr<void> Function()? afterLogin,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    final cfg = config ?? E2eConfig.fromEnvironment();
    if (!cfg.canAutoLogin) return false;
    try {
      await login(cfg.email, cfg.password).timeout(cfg.timeout);
      await afterLogin?.call();
      debugPrint('[E2E] auto login ok: ${cfg.email}');
      return true;
    } catch (e, st) {
      (onError ?? (Object err, StackTrace stack) {
        debugPrint('[E2E] auto login failed: $err\n$stack');
      })(e, st);
      return false;
    }
  }
}
