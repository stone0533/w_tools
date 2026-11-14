# api 使用规则（给人和 AI）

## 什么时候用

HTTP 请求、token 注入与 401 重试、请求日志。

## 最小用法

```dart
// baseOptions 必须在第一次 forBaseUrl 之前设置；日志回调不注入则拦截器静默不输出
WApiSettings.baseOptions = BaseOptions(connectTimeout: const Duration(seconds: 10));
WApiSettings.logDebugHandler = (message) => debugPrint('$message');
WApiSettings.logErrorHandler = (message) => debugPrint('$message');

final dio = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WTokenInterceptor(
      tokenGetter: WToken.getToken,   // 同步读取，不要包 async
      tokenClearer: WToken.clearToken,
      // 刷新后必须自己落盘，保证 tokenGetter 随后返回新 token
      tokenRefresher: () async => refresh(),
    ),
    WLogInterceptor(parts: {WLogPart.request, WLogPart.error}),
  ],
).dio;

final response = await dio.get('/gifts');
```

## 高级能力（按需）

下面这些默认不需要，用了才加：

- `DioRegistry.forBaseUrl(..., replace: true)`：换同 `baseUrl` 的配置；
- `DioRegistry.maxCachedInstances` / `cacheTtl`：已弃用（7.0 删除），新代码用 `dispose` / `replace`；
- `WTokenInterceptor.shouldRefresh`：登录 / 刷新 / 公开接口自己处理 401；
- `WApiClient.send` / `page` 的 `envelope`：单条请求覆盖信封；
- `downloadResponse` / `readTotalFromResponse`：下载元数据 / 页头 total；
- `WRetryInterceptor.shouldRetry` / `disableRetryExtraKey`：自定义重试边界 / 单请求关闭；
- `WMetricsInterceptor`：请求指标。

普通请求只需要 `DioRegistry` + `WApiClient`；不要为了“用全能力”加配置。

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
  // total 在响应头时：
  readTotalFromResponse: (response) =>
      int.tryParse(response.headers.value('x-total-count') ?? ''),
);

await client.upload<void>(
  '/files',
  files: {'file': MultipartFile.fromBytes(bytes)},
  decode: WApiDecoders.none,
);
```

- 分页结果转成 `WAsyncPage` 后交给 `WAsyncPagedController`，不要自己维护 page / hasMore 状态；
- `page` 只支持 1-based 页码分页；offset / cursor 后端用 `client.send` 手工请求并构造 `WPage`；
- 业务码里的「登录失效」用 `WApiEnvelopeParser.authFailureCodes` + `WApiClient.onAuthFailure`；
  不配置时不会触发 `WTokenInterceptor`；
- 单条请求临时覆盖信封用 `client.send(..., envelope: ...)` / `client.page(..., envelope: ...)`；
- 需要 status / headers 用 `WApiClient.send`（返回 `WApiResponse`）；`get/post` 只返回 data；
  下载需要 headers / 文件名用 `WApiClient.downloadResponse`；
- 重试用 `WRetryInterceptor`（默认关闭，只对幂等方法）；HTTP 缓存 / 离线用外部方案，不在本包范围；
- 指标用 `WMetricsInterceptor`（opt-in），只产出 `WMetric`，日志 / 上报由业务决定；
- 选型（手写 `fromJson` / json_serializable / retrofit / OpenAPI）：见
  `packages/api/README.md` 的「选型」章节。

## 不要用

- 用裸 `Dio()` 绕过 `DioRegistry`；必须裸用时构造传 `dio:`，否则 401 后无法重试；
- 同一 `baseUrl` 第二次传不同 `options` / `interceptors`（会抛 `ArgumentError`）；
  需要换配置用 `replace: true` 或先 `dispose`；
- 依赖日志拦截器做业务错误处理；日志只输出技术信息，UI 文案按 `WApiException.kind` 映射；
- 把公共 header / 响应加工塞进 `WTokenInterceptor`；再挂一个普通 `Interceptor` 即可；
- 为了调试把 `password` / token 原样打进日志；`WLogInterceptor` 的 `requestBody` / `responseBody`
  会按 `sensitiveBodyKeys` 脱敏，自定义字段用 `sensitiveBodyKeys` 补（与内置集合合并）。

## 常见坑

- 换配置用 `DioRegistry.forBaseUrl(..., replace: true)` 或先 `dispose(baseUrl)`；
  `replace` 会 `close(force: true)`；LRU / TTL 淘汰用 `close(force: false)`，不强制中断在途请求；
- `WTokenInterceptor` 只注入 token，不负责存储（存储用 `WToken`）；
- 登录 / 刷新 / 公开接口需要自己处理 401 时，用 `WTokenInterceptor.shouldRefresh` 跳过自动刷新；
- 默认不打印 request / response body；需要时显式加 `parts`，并用 `kDebugMode` 控制；
- `validateStatus` 按引用比较：自定义闭包会被视为“不同配置”；
- 裸 `Dio()` 必须构造传 `dio: dio`，否则 401 后无法重试（会报错，不再隐式注册）；推荐用 `DioRegistry`；
- `WRetryInterceptor` 默认不重试 POST / PATCH / 401 / `unknown`；`maxRetries` 不含首次请求；
  需要放行 `unknown` 用 `shouldRetry`；单条请求可用
  `Options(extra: {WRetryInterceptor.disableRetryExtraKey: true})` 关闭重试；
- 显式传 `headers: {'Authorization': ...}` 时 token 拦截器不再覆盖（登录 / 公开接口用得上）；
- 开了业务信封后，204 / 空 body 默认跳过信封（`skipEmptyBody: true`），不会调用 `readCode(null)`；
  需要旧行为时显式传 `skipEmptyBody: false`；
- `DioRegistry.maxCachedInstances` / `cacheTtl` 已弃用（7.0 删除）：新代码用 `dispose` / `replace`。

完整说明：[api_module.md](../modules/api_module.md) · 示例：`packages/api/example`
