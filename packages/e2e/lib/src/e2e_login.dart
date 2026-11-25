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
  /// 条件不满足时返回 false 并打一行 `[E2E] skip: <reason>`（见
  /// [E2eConfig.skipReason]），不再静默返回。
  ///
  /// [beforeLogin] 在 [login] 之前 await，适合清残留会话 / token；它自己抛错
  /// 会以 `[E2E] beforeLogin failed` 上报并返回 false，不会继续登录。
  ///
  /// [afterLogin] 的失败（同步抛 / Future 报错）只上报，不影响返回值 ——
  /// 登录已经成功，不能因为导航出错就判成"没登录"。
  ///
  /// 默认 `afterLogin` 不阻塞 [run]（GetX 的 offAllNamed 有时不 resolve）；
  /// 集成测试需要等导航完成时传 [awaitAfterLogin] = true。
  static Future<bool> run({
    E2eConfig? config,
    FutureOr<void> Function()? beforeLogin,
    required E2eLoginCallback login,
    FutureOr<void> Function()? afterLogin,
    FutureOr<void> Function(Object error, StackTrace stack)? onError,
    bool awaitAfterLogin = false,
  }) async {
    final cfg = config ?? E2eConfig.fromEnvironment();
    final reason = cfg.skipReason;
    if (reason != null) {
      debugPrint('[E2E] skip: ${reason.name}');
      return false;
    }
    var stage = 'beforeLogin';
    try {
      if (beforeLogin != null) {
        await beforeLogin();
      }
      stage = 'auto login';
      await login(cfg.email, cfg.password).timeout(cfg.timeout);
      debugPrint('[E2E] auto login ok: ${cfg.email}');
      final after = _runAfterLogin(afterLogin, onError);
      if (awaitAfterLogin) {
        await after;
      } else {
        unawaited(after);
      }
      return true;
    } catch (e, st) {
      await _report(onError, e, st, stage: stage);
      return false;
    }
  }

  /// 导航这类善后动作：不阻塞 [run]（GetX 的 offAllNamed 有时不 resolve），
  /// 但内部会 await 异步 afterLogin，确保异常能被安全处理。
  static Future<void> _runAfterLogin(
    FutureOr<void> Function()? afterLogin,
    FutureOr<void> Function(Object, StackTrace)? onError,
  ) async {
    if (afterLogin == null) return;
    try {
      final after = afterLogin();
      if (after is Future) await after;
    } catch (e, st) {
      await _report(onError, e, st, stage: 'afterLogin');
    }
  }

  static Future<void> _report(
    FutureOr<void> Function(Object, StackTrace)? onError,
    Object e,
    StackTrace st, {
    required String stage,
  }) async {
    final handler = onError ??
        (Object err, StackTrace stack) {
          debugPrint('[E2E] $stage failed: $err\n$stack');
        };
    try {
      await handler(e, st);
    } catch (handlerError, handlerStack) {
      // 用户回调自己抛错（包括 async 回调）时，不能破坏 run() “失败不抛”的契约。
      debugPrint('[E2E] onError handler failed: $handlerError\n$handlerStack');
    }
  }
}
