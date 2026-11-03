import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

/// 针对实际使用中踩过的坑补的边界测试。
void main() {
  group('配置边界', () {
    test('enabled=false 时即便有账号也不登录', () async {
      var called = false;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: false, email: 'a@b.c', password: 'x'),
        login: (_, __) async => called = true,
      );
      expect(ok, isFalse);
      expect(called, isFalse);
    });

    test('有开关但缺账号 / 缺密码都不登录', () async {
      for (final c in const [
        E2eConfig(enabled: true, email: '', password: 'x'),
        E2eConfig(enabled: true, email: 'a@b.c', password: ''),
        E2eConfig(enabled: true, email: '', password: ''),
      ]) {
        var called = false;
        expect(c.canAutoLogin, isFalse);
        expect(
          await E2eLogin.run(config: c, login: (_, __) async => called = true),
          isFalse,
        );
        expect(called, isFalse);
      }
    });
  });

  group('超时与迟到完成', () {
    test('登录超时返回 false；之后再完成也不会抛', () async {
      final completer = Completer<void>();
      final ok = await E2eLogin.run(
        config: const E2eConfig(
          enabled: true,
          email: 'a',
          password: 'b',
          timeout: Duration(milliseconds: 20),
        ),
        login: (_, __) => completer.future,
      );
      expect(ok, isFalse);
      // 超时后原始 future 才完成：不应产生未捕获异常
      completer.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  });

  group('onError 自身抛错', () {
    test('不会把 run 变成抛异常', () async {
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        login: (_, __) async => throw StateError('login boom'),
        onError: (_, __) => throw StateError('handler boom'),
      );
      expect(ok, isFalse);
    });
  });

  group('afterLogin 出错', () {
    test('登录成功但 afterLogin 同步抛错：仍算登录成功', () async {
      Object? reported;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        login: (_, __) async {},
        afterLogin: () => throw StateError('nav boom'),
        onError: (e, _) => reported = e,
      );
      // 语义：登录本身成功 → true；导航错误单独上报，不能把登录判成失败
      expect(ok, isTrue, reason: '登录成功不应因导航失败而变 false');
      expect(reported, isA<StateError>());
    });
  });
}
