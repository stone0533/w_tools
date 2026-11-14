import '../api_settings.dart';

/// 默认需要脱敏的 query 参数（大小写不敏感）。
///
/// 由 `WLogInterceptor` 公开为同名静态字段；token / retry 的内部日志也复用它，
/// 避免同一条 URI 在日志拦截器里被脱敏、在重试日志里又原样输出。
const Set<String> defaultSensitiveQueryKeys = {
  'token',
  'access_token',
  'refresh_token',
  'api_key',
  'apikey',
  'secret',
  'password',
  'auth',
};

/// 是否注入了 debug / error 日志回调。
bool get hasDebugHandler => WApiSettings.logDebugHandler != null;
bool get hasErrorHandler => WApiSettings.logErrorHandler != null;

/// 写 debug 日志；日志回调抛错不能影响请求本身。
void logDebug(String message) {
  try {
    WApiSettings.logDebugHandler?.call(message);
  } catch (_) {
    // 日志失败不改变请求语义。
  }
}

/// 写 error 日志；日志回调抛错不能影响请求本身。
void logError(String message) {
  try {
    WApiSettings.logErrorHandler?.call(message);
  } catch (_) {
    // 日志失败不改变请求语义。
  }
}

/// 把 URI 里的敏感 query 值替换成 `***`；没有敏感参数时原样返回。
Uri redactUri(Uri uri, Set<String> sensitiveKeys) {
  if (uri.queryParametersAll.isEmpty || sensitiveKeys.isEmpty) return uri;

  var changed = false;
  final pairs = <String>[];
  uri.queryParametersAll.forEach((key, values) {
    final encodedKey = Uri.encodeQueryComponent(key);
    if (sensitiveKeys.contains(key.toLowerCase())) {
      pairs.add('$encodedKey=***');
      changed = true;
    } else {
      for (final value in values) {
        pairs.add('$encodedKey=${Uri.encodeQueryComponent(value)}');
      }
    }
  });
  return changed ? uri.replace(query: pairs.join('&')) : uri;
}
