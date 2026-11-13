import 'package:w_tools_core/w_tools_core.dart';

/// 一次登录得到的凭证。
///
/// [expiry] 为 null 表示服务端没给 `expiresIn`，此时只依赖 401 触发刷新。
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiry,
  });

  /// 访问 token（放进 `Authorization: Bearer <token>`）
  final String accessToken;

  /// 刷新 token（只用来换新的 access token）
  final String refreshToken;

  /// 访问 token 的过期时间
  final DateTime? expiry;

  /// 本地是否已判定过期（只用于提前刷新 / UI 判断，不作为唯一依据）
  bool get isExpired {
    final at = expiry;
    return at != null && DateTime.now().isAfter(at);
  }

  @override
  String toString() => 'AuthSession(accessToken: ***, refreshToken: ***, expiry: $expiry)';
}

/// 凭证存取契约。
///
/// `w_tools_api` 本身不存 token：`WTokenInterceptor` 只通过
/// `tokenGetter` / `tokenClearer` / `tokenRefresher` 回调和存储解耦。
/// 把这三个回调收敛成一个 [TokenStore]，业务层就不用关心 token 存在哪。
abstract class TokenStore {
  /// 当前访问 token；没有时返回 null
  String? get accessToken;

  /// 当前刷新 token；没有时返回 null
  String? get refreshToken;

  /// 保存一次完整凭证
  Future<void> save(AuthSession session);

  /// 只清访问 token，**必须保留刷新 token**（401 刷新还要用它）
  Future<void> clearAccessToken();

  /// 清全部凭证（退出登录 / 刷新失败后使用）
  Future<void> clearAll();
}

/// 生产实现：交给 `w_tools_core` 的 [WToken]（底层是 SharedPreferences）。
///
/// 使用前必须先 `await WStorage.init()`，见 `app_api.dart` 的
/// `AppApi.init` / `main` 示例。
class WTokenStore implements TokenStore {
  const WTokenStore();

  @override
  String? get accessToken => WToken.getToken();

  @override
  String? get refreshToken => WToken.getRefreshToken();

  @override
  Future<void> save(AuthSession session) =>
      WToken.saveTokens(session.accessToken, session.refreshToken, session.expiry);

  // 不要用 clearAllTokens：刷新流程还要用 refresh token。
  @override
  Future<void> clearAccessToken() => WToken.clearToken();

  @override
  Future<void> clearAll() => WToken.clearAllTokens();
}

/// 测试 / 预览实现：只存在内存里，不依赖平台插件。
class MemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiry;

  /// 当前凭证的过期时间（测试断言用）
  DateTime? get expiry => _expiry;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> save(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _expiry = session.expiry;
  }

  @override
  Future<void> clearAccessToken() async {
    _accessToken = null;
    _expiry = null;
  }

  @override
  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
    _expiry = null;
  }
}
