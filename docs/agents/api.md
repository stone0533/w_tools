# api 使用规则（给人和 AI）

## 什么时候用

HTTP 请求、token 注入与 401 重试、请求日志。

## 最小用法

```dart
// 必须在第一次 forBaseUrl 之前设置；日志回调不注入则拦截器静默不输出
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

- 直接 `Dio()`（401 重试依赖 `DioRegistry` 的实例）；
- 同一 `baseUrl` 第二次传不同 `options` / `interceptors`（会抛 `ArgumentError`）；
- 旧日志 bool 参数（用 `parts:`）；
- 依赖日志拦截器做业务错误处理。

## 常见坑

- 换配置先 `DioRegistry.dispose(baseUrl)`；
- `WTokenInterceptor` 只注入 token，不负责存储（存储用 `WToken`）；
- release 下请求 / 响应体默认不应输出（用 `parts` + `kDebugMode` 控制）；
- `validateStatus` 按引用比较：自定义闭包会被视为“不同配置”；
- 别用裸 `Dio()` 创建拦截器链路：401 重试会隐式注册一个零拦截器的 registry 条目。

完整说明：[api_module.md](../modules/api_module.md) · 示例：`packages/api/example`
