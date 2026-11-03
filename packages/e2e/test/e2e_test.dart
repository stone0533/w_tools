import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

void main() {
  group('E2eConfig', () {
    test('无 dart-define 时关闭', () {
      final c = E2eConfig.fromEnvironment();
      expect(c.enabled, isFalse);
      expect(c.canAutoLogin, isFalse);
      expect(c.email, isEmpty);
    });

    test('canAutoLogin 需要 enabled + 账号 + 密码', () {
      const ok = E2eConfig(enabled: true, email: 'a@b.c', password: 'x');
      expect(ok.canAutoLogin, isTrue);

      const noPwd = E2eConfig(enabled: true, email: 'a@b.c', password: '');
      expect(noPwd.canAutoLogin, isFalse);

      const disabled = E2eConfig(enabled: false, email: 'a@b.c', password: 'x');
      expect(disabled.canAutoLogin, isFalse);
    });

    test('toString 不泄露密码', () {
      const c = E2eConfig(enabled: true, email: 'a@b.c', password: 'secret');
      expect(c.toString(), isNot(contains('secret')));
    });
  });

  group('E2eLogin.run', () {
    test('未启用时直接返回 false，不调 login', () async {
      var called = false;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: false, email: 'a', password: 'b'),
        login: (_, __) async => called = true,
      );
      expect(ok, isFalse);
      expect(called, isFalse);
    });

    test('成功：login + afterLogin 都被调到', () async {
      var loggedIn = false;
      var navigated = false;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a@b.c', password: 'x'),
        login: (e, p) async {
          expect(e, 'a@b.c');
          expect(p, 'x');
          loggedIn = true;
        },
        afterLogin: () => navigated = true,
      );
      expect(ok, isTrue);
      expect(loggedIn, isTrue);
      expect(navigated, isTrue);
    });

    test('失败：返回 false 并回调 onError，不抛', () async {
      Object? captured;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        login: (_, __) async => throw StateError('boom'),
        onError: (e, _) => captured = e,
      );
      expect(ok, isFalse);
      expect(captured, isA<StateError>());
    });

    test('超时：返回 false', () async {
      final ok = await E2eLogin.run(
        config: const E2eConfig(
          enabled: true,
          email: 'a',
          password: 'b',
          timeout: Duration(milliseconds: 30),
        ),
        login: (_, __) => Future<void>.delayed(const Duration(seconds: 5)),
      );
      expect(ok, isFalse);
    });
  });
}
