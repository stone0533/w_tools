import 'package:flutter/foundation.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_core/w_tools_core.dart';

import 'api_exception.dart';
import 'token_store.dart';

/// 应用统一 API 客户端。
///
/// 一个 baseUrl 只创建一个 [AppApi]；在 `main()` 里 `await AppApi.init(...)`
/// 后注入给 Repository / Controller，不要在页面里反复创建。
///
/// 关键点：
/// - 配置在第一次 [DioRegistry.forBaseUrl] **之前**写入 [WApiSettings]；
/// - 同一 baseUrl 的 options / interceptors 只能确定一次，换配置先 [dispose]；
/// - token 存储通过 [TokenStore] 注入，生产用 [WTokenStore]，测试用
///   [MemoryTokenStore]；
/// - 401 → 清 access token → `tokenRefresher` → 自动重试，全部由
///   [WTokenInterceptor] 完成，业务层只处理最终失败。
class AppApi {
  AppApi._(this._registry, this._store);

  /// 示例默认地址；真实项目替换成自己的网关
  static const String defaultBaseUrl = 'https://api.example.com';

  final DioRegistry _registry;
  final TokenStore _store;

  /// 供 Repository / 拦截器使用；业务代码不要直接裸用 [Dio]
  Dio get dio => _registry.dio;

  /// 当前凭证（只读用途；写凭证走 [login] / [logout] / 刷新）
  TokenStore get tokens => _store;

  /// 初始化并注册 Dio。
  ///
  /// 必须且只能调用一次；重复调用同一 baseUrl 会因配置不同抛
  /// [ArgumentError]，需要换配置请先 [dispose]。
  ///
  /// [adapter] 只用于测试 / 预览时注入 MockAdapter，生产不传。
  static Future<AppApi> init({
    String baseUrl = defaultBaseUrl,
    TokenStore? tokenStore,
    HttpClientAdapter? adapter,
    bool enableLog = kDebugMode,
    void Function()? onAuthFailure,
  }) async {
    final store = tokenStore ?? const WTokenStore();

    // WToken 底层是 SharedPreferences，读之前必须初始化。
    if (store is WTokenStore) {
      await WStorage.init();
    }

    // 全局默认配置：在第一次创建 registry 之前设置才会生效。
    WApiSettings.baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    );
    WApiSettings.logDebugHandler = enableLog ? (message) => WLogger.d(message) : null;
    WApiSettings.logErrorHandler = enableLog ? (message) => WLogger.e(message) : null;

    // 先声明再创建：tokenRefresher 需要拿到 registry 自己。
    late final DioRegistry registry;
    registry = DioRegistry.forBaseUrl(
      baseUrl,
      interceptors: [
        // 公共 header 不属于 token 职责，用普通拦截器。
        _AppHeaderInterceptor(),
        // 放在日志前：请求方向先注入 Authorization，日志才能看到（已脱敏的）头。
        WTokenInterceptor(
          tokenGetter: () => store.accessToken,
          tokenClearer: store.clearAccessToken,
          tokenRefresher: () => _refresh(registry, store),
          // 刷新失败 / 达到重试上限：交给 App 层清会话并跳登录。
          onAuthFailure: (_) => onAuthFailure?.call(),
        ),
        WLogInterceptor(
          enableLog: enableLog,
          parts: {
            WLogPart.request,
            WLogPart.requestHeader,
            if (enableLog) WLogPart.requestBody,
            if (enableLog) WLogPart.responseBody,
            WLogPart.error,
          },
        ),
      ],
    );
    if (adapter != null) {
      registry.dio.httpClientAdapter = adapter;
    }
    return AppApi._(registry, store);
  }

  /// 登录并持久化凭证。
  ///
  /// 失败统一抛 [ApiException]。
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final session = _parseSession(response.data ?? const {});
      await _store.save(session);
      return session;
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  /// 退出登录：清全部凭证。调用方再负责清路由 / 跳登录页。
  Future<void> logout() => _store.clearAll();

  /// 释放 Dio（测试 / 热重载 / 切换环境时用）
  static void dispose([String baseUrl = defaultBaseUrl]) {
    DioRegistry.dispose(baseUrl);
  }

  /// 401 时由 [WTokenInterceptor] 调用。
  ///
  /// 契约：这里必须自己把新 token 写回 [TokenStore]，否则下一次
  /// `tokenGetter` 仍返回旧值，重试会再次 401。
  ///
  /// 注意：此刻 access token 已被 `tokenClearer` 清掉，所以同一 dio 发出的
  /// 刷新请求不会被注入旧 token；refresh token 放在 body 里。
  static Future<String?> _refresh(
    DioRegistry registry,
    TokenStore store,
  ) async {
    final refreshToken = store.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await registry.dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final session = _parseSession(
      response.data ?? const {},
      fallbackRefreshToken: refreshToken,
    );
    await store.save(session);
    return session.accessToken;
  }

  static AuthSession _parseSession(
    Map<String, dynamic> json, {
    String? fallbackRefreshToken,
  }) {
    final accessToken = json['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ApiException(
        ApiErrorKind.unknown,
        '服务端响应缺少 accessToken',
      );
    }
    final expiresIn = json['expiresIn'];
    return AuthSession(
      accessToken: accessToken,
      refreshToken: (json['refreshToken'] as String?) ?? fallbackRefreshToken ?? '',
      expiry: expiresIn is num ? DateTime.now().add(Duration(seconds: expiresIn.toInt())) : null,
    );
  }
}

/// 示例：公共 header 用普通拦截器注入，不要塞进 token 拦截器。
class _AppHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-App-Platform'] = defaultTargetPlatform.name;
    handler.next(options);
  }
}
