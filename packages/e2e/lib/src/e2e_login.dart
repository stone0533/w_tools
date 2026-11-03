import 'dart:async';

import 'package:flutter/foundation.dart';

import 'e2e_config.dart';

/// 用测试账号登录。
typedef E2eLoginCallback = Future<void> Function(String email, String password);

/// 免登录流程：调 [login] → [afterLogin]（一般是重建导航栈）。
class E2eLogin {
  const E2eLogin._();

  /// 返回**登录本身**是否成功；失败只回调 [onError] 并返回 false，不抛异常。
  ///
  /// [afterLogin] 的失败（同步抛 / Future 报错）只上报，不影响返回值 ——
  /// 登录已经成功，不能因为导航出错就判成"没登录"。
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
      debugPrint('[E2E] auto login ok: ${cfg.email}');
      _runAfterLogin(afterLogin, onError);
      return true;
    } catch (e, st) {
      _report(onError, e, st, failed: true);
      return false;
    }
  }

  /// 导航这类善后动作：不 await（GetX 的 offAllNamed 有时不 resolve），
  /// 出错也不影响「登录成功」的结论。
  static void _runAfterLogin(
    FutureOr<void> Function()? afterLogin,
    void Function(Object, StackTrace)? onError,
  ) {
    if (afterLogin == null) return;
    try {
      final after = afterLogin();
      if (after is Future<void>) {
        unawaited(
          after.then(
            (_) {},
            onError: (Object e, StackTrace st) => _report(onError, e, st, failed: false),
          ),
        );
      }
    } catch (e, st) {
      _report(onError, e, st, failed: false);
    }
  }

  static void _report(
    void Function(Object, StackTrace)? onError,
    Object e,
    StackTrace st, {
    required bool failed,
  }) {
    final handler = onError ??
        (Object err, StackTrace stack) {
          debugPrint(
            failed
                ? '[E2E] auto login failed: $err\n$stack'
                : '[E2E] afterLogin failed: $err\n$stack',
          );
        };
    try {
      handler(e, st);
    } catch (handlerError, handlerStack) {
      // 用户回调自己抛错时，不能破坏 run() “失败不抛”的契约。
      debugPrint('[E2E] onError handler failed: $handlerError\n$handlerStack');
    }
  }
}
