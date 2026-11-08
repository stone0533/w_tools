# api 使用规则（给人和 AI）

## 什么时候用

HTTP 请求、token 注入与 401 重试、请求日志。

## 最小用法

```dart
// baseOptions 必须在第一次 forBaseUrl 之前设置；日志回调不注入则拦截器静默不输出
WApiConfig.baseOptions = BaseOptions(connectTimeout: const Duration(seconds: 10));
WApiConfig.logDebugHandler = (message) => debugPrint('$message');
WApiConfig.logErrorHandler = (message) => debugPrint('$message');

final dio = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WTokenInterceptor(
      tokenGetter: WToken.getToken,   // 同步读取，不要包 async
      tokenClearer: WToken.clearToken,
      // 刷新后必须自己落盘，保证 tokenGetter 随后返回新 token
      tokenRefresher: () async => refresh(),
    ),
    WLogInterceptor(parts: {WLogPart.request, WLogPart.error, WLogPart.errorHint}),
  ],
).dio;

final response = await dio.get('/gifts');
```

## 不要用

- 用裸 `Dio()` 绕过 `DioRegistry`；必须裸用时构造传 `dio:`，否则 401 后无法重试；
- 同一 `baseUrl` 第二次传不同 `options` / `interceptors`（会抛 `ArgumentError`）；
- 依赖日志拦截器做业务错误处理。

## 常见坑

- 换配置先 `DioRegistry.dispose(baseUrl)`；
- `WTokenInterceptor` 只注入 token，不负责存储（存储用 `WToken`）；
- 默认不打印 request / response body；需要时显式加 `parts`，并用 `kDebugMode` 控制；
- `validateStatus` 按引用比较：自定义闭包会被视为“不同配置”；
- 裸 `Dio()` 必须构造传 `dio: dio`，否则 401 后无法重试（会报错，不再隐式注册）；推荐用 `DioRegistry`。

完整说明：[api_module.md](../modules/api_module.md) · 示例：`packages/api/example`
