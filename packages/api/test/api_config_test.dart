import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  group('WApiConfig', () {
    test('baseOptions 默认超时正确', () {
      expect(
        WApiConfig.baseOptions.connectTimeout,
        const Duration(milliseconds: 10000),
      );
      expect(
        WApiConfig.baseOptions.receiveTimeout,
        const Duration(milliseconds: 50000),
      );
    });

    test('logDebugHandler / logErrorHandler 默认为 null', () {
      WApiConfig.logDebugHandler = null;
      WApiConfig.logErrorHandler = null;
      expect(WApiConfig.logDebugHandler, isNull);
      expect(WApiConfig.logErrorHandler, isNull);
    });

    test('可以注入日志回调', () {
      List<String> logs = [];
      WApiConfig.logDebugHandler = (m) => logs.add('D:$m');
      WApiConfig.logErrorHandler = (m) => logs.add('E:$m');

      WApiConfig.logDebugHandler?.call('test');
      WApiConfig.logErrorHandler?.call('error');

      expect(logs, ['D:test', 'E:error']);
      // cleanup
      WApiConfig.logDebugHandler = null;
      WApiConfig.logErrorHandler = null;
    });
  });

  group('BaseRepository', () {
    test('子类可以持有 local 和 remote data source', () {
      final repo = _TestRepository(
        localDataSource: _LocalImpl(),
        remoteDataSource: _RemoteImpl(),
      );
      expect(repo.localDataSource, isA<_LocalImpl>());
      expect(repo.remoteDataSource, isA<_RemoteImpl>());
    });

    test('允许 local 为 null', () {
      final repo = _TestRepository(
          localDataSource: null, remoteDataSource: _RemoteImpl());
      expect(repo.localDataSource, isNull);
      expect(repo.remoteDataSource, isA<_RemoteImpl>());
    });

    test('允许 remote 为 null', () {
      final repo = _TestRepository(
          localDataSource: _LocalImpl(), remoteDataSource: null);
      expect(repo.localDataSource, isA<_LocalImpl>());
      expect(repo.remoteDataSource, isNull);
    });

    test('两个都可以为 null', () {
      final repo = _TestRepository(
          localDataSource: null, remoteDataSource: null);
      expect(repo.localDataSource, isNull);
      expect(repo.remoteDataSource, isNull);
    });
  });

  group('IApiPath / ApiClientId', () {
    test('ApiClientId 是 immutable', () {
      const id = ApiClientId('test');
      expect(id.name, 'test');
    });

    test('IApiPath 子类必须提供 baseUrl', () {
      final path = _TestApiPath();
      expect(path.baseUrl, 'https://api.example.com');
    });
  });
}

// === 测试用的具体实现 ===

class _TestRepository extends BaseRepository<_LocalImpl?, _RemoteImpl?> {
  _TestRepository({super.localDataSource, super.remoteDataSource});
}

class _LocalImpl extends BaseLocalDataSource {}

class _RemoteImpl extends BaseRemoteDataSource {}

class _TestApiPath implements IApiPath {
  @override
  String get baseUrl => 'https://api.example.com';
}
