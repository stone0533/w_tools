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

## 调用层（WApiClient）

`DioRegistry` 负责连接，`WApiClient` 负责调用：

```dart
final client = WApiClient(registry.dio);

final user = await client.get(
  '/users/{id}',
  pathParameters: {'id': '42'},
  query: {'include': 'profile'},
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

- `decode` 必须显式传：Dart 没有反射，`get<User>()` 不会自动反序列化；
- 失败统一抛 `WApiException`，UI 按 `kind` 决定提示 / 重试 / 跳登录；
- body 用 `WApiBody.json` / `form` / `multipart` / `bytes`。

信封 / 分页 / 上传：

```dart
// 信封默认关闭；业务码失败是 WApiException(kind: business)
final client = WApiClient(
  registry.dio,
  envelope: WApiEnvelopeParser(
    readCode: (json) => (json as Map)['code'],
    readData: (json) => (json as Map)['data'],
    isSuccess: (code) => code == 0,
  ),
);

final page = await client.page(
  '/users',
  query: const WPageQuery(page: 1, pageSize: 20),
  itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
);

await client.upload<void>(
  '/files',
  files: {'file': MultipartFile.fromBytes(bytes)},
  decode: WApiDecoders.none,
);
```

- 分页结果转成 `WAsyncPage` 后交给 `WAsyncPagedController`，不要自己维护 page / hasMore 状态；
- 业务码里的「登录失效」不会触发 `WTokenInterceptor`，需要业务自己处理或让服务端返回 HTTP 401；
- 重试用 `WRetryInterceptor`（默认关闭，只对幂等方法）；HTTP 缓存 / 离线用外部方案，不在本包范围。

## 不要用

- 用裸 `Dio()` 绕过 `DioRegistry`；必须裸用时构造传 `dio:`，否则 401 后无法重试；
- 同一 `baseUrl` 第二次传不同 `options` / `interceptors`（会抛 `ArgumentError`）；
- 依赖日志拦截器做业务错误处理；
- 为了调试把 `password` / token 原样打进日志；`WLogInterceptor` 的 `requestBody` / `responseBody`
  会按 `sensitiveBodyKeys` 脱敏，自定义字段用 `sensitiveBodyKeys` 补，不要关掉脱敏。

## 常见坑

- 换配置先 `DioRegistry.dispose(baseUrl)`；
- `WTokenInterceptor` 只注入 token，不负责存储（存储用 `WToken`）；
- 默认不打印 request / response body；需要时显式加 `parts`，并用 `kDebugMode` 控制；
- `validateStatus` 按引用比较：自定义闭包会被视为“不同配置”；
- 裸 `Dio()` 必须构造传 `dio: dio`，否则 401 后无法重试（会报错，不再隐式注册）；推荐用 `DioRegistry`；
- `WRetryInterceptor` 不重试 POST / PATCH，也不重试 401；`maxRetries` 不含首次请求。

完整说明：[api_module.md](../modules/api_module.md) · 示例：`packages/api/example`
