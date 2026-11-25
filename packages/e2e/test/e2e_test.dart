import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

List<String> _captureDebugPrint() {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
  addTearDown(() => debugPrint = original);
  return logs;
}

void main() {
  group('E2eConfig', () {
    test('无 dart-define 时关闭', () {
      final c = E2eConfig.fromEnvironment();
      expect(c.enabled, isFalse);
      expect(c.canAutoLogin, isFalse);
      expect(c.email, isEmpty);
      expect(c.skipReason, E2eSkipReason.flagOff);
    });

    test('canAutoLogin 需要 enabled + 账号 + 密码', () {
      const ok = E2eConfig(enabled: true, email: 'a@b.c', password: 'x');
      expect(ok.canAutoLogin, isTrue);
      expect(ok.skipReason, isNull);

      const noPwd = E2eConfig(enabled: true, email: 'a@b.c', password: '');
      expect(noPwd.canAutoLogin, isFalse);
      expect(noPwd.skipReason, E2eSkipReason.missingPassword);

      const noEmail = E2eConfig(enabled: true, email: '', password: 'x');
      expect(noEmail.skipReason, E2eSkipReason.missingEmail);

      const disabled = E2eConfig(enabled: false, email: 'a@b.c', password: 'x');
      expect(disabled.canAutoLogin, isFalse);
      expect(disabled.skipReason, E2eSkipReason.disabled);
    });

    test('copyWith 保留 skipReason', () {
      final disabled = E2eConfig.fromEnvironment().copyWith(
        timeout: const Duration(seconds: 5),
      );
      expect(disabled.skipReason, E2eConfig.fromEnvironment().skipReason);
      expect(disabled.timeout, const Duration(seconds: 5));
    });

    test('toString 不泄露密码', () {
      const c = E2eConfig(enabled: true, email: 'a@b.c', password: 'secret');
      expect(c.toString(), isNot(contains('secret')));
    });
  });

  group('E2eLogin.run', () {
    test('未启用时打 skip 行并返回 false，不调 login', () async {
      final logs = _captureDebugPrint();
      var called = false;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: false, email: 'a', password: 'b'),
        login: (_, __) async => called = true,
      );
      expect(ok, isFalse);
      expect(called, isFalse);
      expect(logs, contains('[E2E] skip: disabled'));
    });

    test('缺密码时 skip 行给出具体原因', () async {
      final logs = _captureDebugPrint();
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: ''),
        login: (_, __) async {},
      );
      expect(ok, isFalse);
      expect(logs, contains('[E2E] skip: missingPassword'));
    });

    test('beforeLogin 在 login 之前执行', () async {
      final order = <String>[];
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        beforeLogin: () async => order.add('before'),
        login: (_, __) async => order.add('login'),
      );
      expect(ok, isTrue);
      expect(order, ['before', 'login']);
    });

    test('beforeLogin 抛错：返回 false，不调 login，错误上报', () async {
      Object? captured;
      var loginCalled = false;
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        beforeLogin: () => throw StateError('reset failed'),
        login: (_, __) async => loginCalled = true,
        onError: (e, _) => captured = e,
      );
      expect(ok, isFalse);
      expect(loginCalled, isFalse);
      expect(captured, isA<StateError>());
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

    test('afterLogin 永不 resolve 时也能返回 true（导航不阻塞）', () async {
      final ok = await E2eLogin.run(
        config: const E2eConfig(enabled: true, email: 'a', password: 'b'),
        login: (_, __) async {},
        afterLogin: () => Completer<void>().future,
      );
      expect(ok, isTrue);
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

  group('E2eSignals', () {
    test('ready 打稳定前缀，可带 detail', () {
      final logs = _captureDebugPrint();
      E2eSignals.ready();
      E2eSignals.ready('home');
      expect(logs, ['[E2E] ready', '[E2E] ready home']);
      expect(E2eSignals.readyPrefix, '[E2E] ready');
      expect(E2eSignals.readyLine('home'), '[E2E] ready home');
    });
  });
}
