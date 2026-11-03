# 登录 / 401 刷新 token + toast

```dart
Future<String?> refreshToken() async {
  final refresh = WToken.getRefreshToken();
  if (refresh == null) return null;

  final result = await api.refresh(refresh);      // 你自己的刷新接口
  await WToken.saveToken(result.token, result.expiry);
  return result.token;
}

final dio = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WTokenInterceptor(
      tokenGetter: WToken.getToken,       // String? Function()
      tokenClearer: WToken.clearToken,    // Future<void> Function()
      tokenRefresher: refreshToken,       // Future<String?> Function()
    ),
    WLogInterceptor(
      parts: {
        WLogPart.request,
        WLogPart.error,
        WLogPart.errorHint,
        if (kDebugMode) WLogPart.responseBody,
      },
    ),
  ],
).dio;
```

登录成功后：

```dart
await WToken.saveTokens(token, refreshToken, expiry);
WToast.showSuccess('登录成功');
```

要点：

- 刷新接口必须**自己持久化**，保证 `tokenGetter` 随后返回新 token；
- `WTokenInterceptor` 只在 `DioRegistry` 创建的 Dio 上工作；自行 `Dio()` 不会复用；
- 同一 `baseUrl` 第二次传不同 options / interceptors 会抛 `ArgumentError`，换配置先 `DioRegistry.dispose(baseUrl)`；
- token 是明文存储（SharedPreferences），高敏感场景用 Keychain / Keystore。
