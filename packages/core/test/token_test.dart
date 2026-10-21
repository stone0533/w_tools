import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w_tools_core/src/utils/storage.dart';
import 'package:w_tools_core/src/utils/token.dart';

void main() {
  group('WToken', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await WStorage.init();
      await WStorage.clear();
    });

    tearDown(() async {
      await WStorage.clear();
    });

    test('saveToken + getToken', () async {
      await WToken.saveToken('my_token_123');
      expect(WToken.getToken(), 'my_token_123');
    });

    test('saveToken 带过期时间', () async {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      await WToken.saveToken('expiring_token', expiry);
      expect(WToken.getToken(), 'expiring_token');
      expect(WToken.getTokenExpiry(), isNotNull);
    });

    test('saveRefreshToken + getRefreshToken', () async {
      await WToken.saveRefreshToken('my_refresh_token');
      expect(WToken.getRefreshToken(), 'my_refresh_token');
    });

    test('saveTokens 同时保存', () async {
      await WToken.saveTokens('t1', 'r1');
      expect(WToken.getToken(), 't1');
      expect(WToken.getRefreshToken(), 'r1');
    });

    test('saveTokens 带过期时间', () async {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      await WToken.saveTokens('t2', 'r2', expiry);
      expect(WToken.getToken(), 't2');
      expect(WToken.getTokenExpiry(), isNotNull);
    });

    test('clearToken 清除 token', () async {
      await WToken.saveToken('to_clear');
      expect(WToken.getToken(), 'to_clear');
      await WToken.clearToken();
      expect(WToken.getToken(), isNull);
    });

    test('clearRefreshToken 清除 refresh token', () async {
      await WToken.saveRefreshToken('r_to_clear');
      expect(WToken.getRefreshToken(), 'r_to_clear');
      await WToken.clearRefreshToken();
      expect(WToken.getRefreshToken(), isNull);
    });

    test('clearAllTokens', () async {
      await WToken.saveTokens('t', 'r');
      await WToken.clearAllTokens();
      expect(WToken.getToken(), isNull);
      expect(WToken.getRefreshToken(), isNull);
    });

    test('isTokenExpired - 无过期时间返回 false', () async {
      await WToken.saveToken('no_expiry');
      expect(WToken.isTokenExpired(), isFalse);
    });

    test('isTokenExpired - 已过期', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      await WToken.saveToken('expired', past);
      expect(WToken.isTokenExpired(), isTrue);
    });

    test('isTokenExpired - 未过期', () async {
      final future = DateTime.now().add(const Duration(hours: 1));
      await WToken.saveToken('valid', future);
      expect(WToken.isTokenExpired(), isFalse);
    });

    test('isTokenValid - token 为空返回 false', () async {
      await WToken.clearAllTokens();
      expect(WToken.isTokenValid(), isFalse);
    });

    test('isTokenValid - 已过期返回 false', () async {
      final past = DateTime.now().subtract(const Duration(minutes: 30));
      await WToken.saveToken('expired_token', past);
      expect(WToken.isTokenValid(), isFalse);
    });

    test('isTokenValid - 有效返回 true', () async {
      await WToken.saveToken('good_token');
      expect(WToken.isTokenValid(), isTrue);
    });

    test('hasRefreshToken', () async {
      expect(WToken.hasRefreshToken(), isFalse);
      await WToken.saveRefreshToken('rt');
      expect(WToken.hasRefreshToken(), isTrue);
    });

    test('getTokenExpiry - 无过期返回 null', () async {
      expect(WToken.getTokenExpiry(), isNull);
    });

    test('updateTokenExpiry', () async {
      await WToken.saveToken('t');
      final expiry = DateTime.now().add(const Duration(days: 1));
      await WToken.updateTokenExpiry(expiry);
      final stored = WToken.getTokenExpiry();
      expect(stored, isNotNull);
      expect(stored!.toIso8601String(), expiry.toIso8601String());
    });

    test('WStorage.clear 后 token 同步为空（不保留进程缓存）', () async {
      await WToken.saveToken('stale_token');
      await WStorage.clear();
      expect(WToken.getToken(), isNull);
    });

    test('重复 saveToken 不传过期时间会清除旧过期时间', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      await WToken.saveToken('token_a', past);
      expect(WToken.isTokenExpired(), isTrue);

      await WToken.saveToken('token_b');
      expect(WToken.getToken(), 'token_b');
      expect(WToken.getTokenExpiry(), isNull);
      expect(WToken.isTokenExpired(), isFalse);
    });
  });
}
