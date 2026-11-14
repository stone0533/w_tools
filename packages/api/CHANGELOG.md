# Changelog

## 6.2.0

### Deprecated
- `DioRegistry.maxCachedInstances` / `DioRegistry.cacheTtl`：缓存策略过度封装，7.0.0 删除；
  迁移到 `replace` / `dispose`，或由业务层持有 Dio。
- `WApiClient.download`：与 `downloadResponse` 重复，7.0.0 删除；
  改用 `downloadResponse(...).data`。
- `WLogInterceptor.enableLog`：与 `parts` / 日志回调三重开关，7.0.0 删除；
  改用 `parts: {}` 或不注入日志回调。

### Changed
- 测试 / 示例改用 `downloadResponse`、`parts`，不再使用上述弃用入口。

## 6.1.0

### Breaking
- `DioRegistry.forBaseUrl` 签名新增可选参数 `replace`（源码兼容；公开签名快照变化需记录）。
- `WTokenInterceptor` 构造新增可选 `shouldRefresh`；`WApiClient.send` / `page` 新增可选
  `envelope`（均为源码兼容的可选参数，公开签名快照变化需记录）。

### Added
- `WApiEnvelopeParser.skipEmptyBody`：204 / 空 body 默认跳过信封解析，不再要求
  `readCode(null)` 自己判空。
- `DioRegistry.forBaseUrl(replace: true)`：替换同 `baseUrl` 的已有实例。
- `WApiClient.send(onReceiveProgress:)`、`WApiClient.downloadResponse`，以及
  `WApiClient.page(readTotalFromResponse:)`（从 `X-Total-Count` 等响应头读 total）。
- `WRetryInterceptor.disableRetryExtraKey`：单条请求关闭重试。
- `WMetric.attempt`：区分首次请求与重试 / 401 刷新后的尝试。
- `WTokenInterceptor.shouldRefresh`：对登录 / 刷新 / 公开接口等请求跳过自动刷新。
- `WApiClient.send` / `page` 的 `envelope` 参数：按请求覆盖 client 级信封。
- barrel 重导出 `InterceptorsWrapper` / `QueuedInterceptor`。

### Fixed
- 业务信封 + 204 / 空 body 不再先执行 `readCode(null)` 而误报 `decode` 错误。
- `DioRegistry` 配置冲突比较补上 `transformTimeout`；`queryParameters` 深拷贝，
  不再与调用方 / 全局 `BaseOptions` 共享可变 Map。
- 日志回调抛异常不再影响请求；token / retry 内部日志的 URI 也按敏感 query 脱敏。
- `DioExceptionType.unknown` 带 response 时按 HTTP 状态分类，不再一律 `unknown`。
- `WLogInterceptor` 只开 `responseHeader` / `responseBody` 时，错误响应片段也会输出。
- `WLogInterceptor` 截断 body 时不再切断 UTF-16 代理对（emoji 等）。
- `WLogInterceptor` 对超大 body 先按字符预算限量再 JSON 编码，避免 `maxBodyLength`
  只限制输出、不限制中间内存。
- `DioRegistry` 的 LRU / TTL 淘汰改为 `close(force: false)`，不再强制中断在途请求；
  显式 `dispose` / `clearCache` 仍强制关闭。
- `WRetryInterceptor` 退避期间取消会立即结束等待，不再等完整个 backoff。
- `WApiClient._decode` 里 `onAuthFailure` 的日志回调异常不再覆盖原始 unauthorized。

### Changed
- 业务信封在 204 / 空 body 默认跳过 `readCode`；旧行为显式传 `skipEmptyBody: false`。
- `WLogInterceptor` 的 `sensitiveQueryKeys` / `sensitiveBodyKeys` / `redactedHeaders`
  与内置敏感集合合并；不再提供整体替换开关。
- `WRetryInterceptor` 默认不再重试 `DioExceptionType.unknown`；需要放行时用
  `shouldRetry` 自定义。
- `WApiClient.page` 返回的 `items` 改为不可变列表。
- `WApiClient.page` 对 `page < 1` / `pageSize < 1` 抛 `ArgumentError`（release 也生效）。
- `WTokenInterceptor.maxAuthRetries` 为负时触发 `assert`。
- `download` 改为委托 `downloadResponse`，行为不变。
- example 补 `send` 元数据 / 按请求信封 / `downloadResponse` / 页头 total /
  `WTokenInterceptor.shouldRefresh` 的可运行示例与测试。

## 6.0.0

### Breaking
- `WApiConfig` 改名 `WApiSettings`（文件 `api_settings.dart`）；日志回调参数由 `dynamic`
  收紧为 `String`。迁移见 [`docs/migrations/api-6.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/api-6.0.md)。
- `WApiMetricsInterceptor` / `WApiMetric` 改名 `WMetricsInterceptor` / `WMetric`。
- `WTokenInterceptor` 删除 `WTokenInterceptor.configureRequest` /
  `WTokenInterceptor.configureResponse` / `WTokenInterceptor.observeError`，以及仅用于转发
  `configureResponse` 的 `WTokenInterceptor.onResponse` 覆写：公共 header / 响应加工 / 错误观测
  改用普通 `Interceptor`。
- `WLogPart.errorHint` 删除；日志只输出技术信息，UI 按 `WApiException.kind` 映射文案。
- `WApiBody.kind` / `WApiBodyKind` 删除。
- `WApiClient` 的 `pathParameters` 未覆盖占位符时一律抛 `ArgumentError`（含空 Map / 未传）。

### Removed
- `IApiPath` / `ApiClientId`：库内无消费方，直接用 `baseUrl`。
- `BaseRepository` / `BaseLocalDataSource` / `BaseRemoteDataSource`：空壳基类，由业务项目自定义。

### Fixed
- `DioRegistry.maxCachedInstances <= 0` 不再关闭刚创建、正要返回的实例。
- 刷新成功但重试请求失败时保留真实错误（如 500），不再误报原始 401 或误触发 `onAuthFailure`。
- `WApiClient` 空 `pathParameters` 不再把 `%7Bid%7D` 发给服务端。
- `WRetryInterceptor` 把 `DioExceptionType.transformTimeout` 视为可重试网络错误。

### Changed
- `WTokenInterceptor` 不再覆盖显式 `Authorization`；请求已带该头时跳过注入。
- `WTokenInterceptor` 不再修改 `content-type`（交给 dio 内置推断）。
- `DioRegistry` 源码移入 `src/client/`；`api_client.dart` 按角色拆分为多个文件。
- 认证重试计数键改为 `_w_tools_auth_retry_count`，与网络的
  `_w_tools_network_retry_count` 区分。

### Added
- barrel 重导出 `RequestInterceptorHandler` / `ResponseInterceptorHandler` /
  `ErrorInterceptorHandler`，自定义拦截器不必再直接依赖 dio。

## 5.6.0

### Added
- `WApiMetricsInterceptor` / `WApiMetric`：可选的请求指标（method / path / status /
  duration / failed），支持 `sampleRate` 与 `onMetric`。

## 5.5.0

### Added
- `WApiResponse<T>` / `WApiClient.send`：保留 `statusCode` / `headers` / `requestOptions`。
- `WApiEnvelopeParser.authFailureCodes` / `WApiClient.onAuthFailure`：业务码登录失效
  抛 `unauthorized` 并回调，与 HTTP 401 走同一条登出链路。

## 5.4.0

### Added
- `WApiClient.head` / `WApiClient.options`：补全 HEAD / OPTIONS。
- `WApiClient.upload` 新增 `method`（`POST` / `PUT` / `PATCH`，默认 `POST`）。

## 5.3.0

### Added
- `WApiClient`：统一 GET / POST / PUT / PATCH / DELETE，支持 `pathParameters`、`query`、
  `WApiBody`、显式 `decode`、`CancelToken` 与自定义 header。
- `WApiBody`：`json` / `form` / `multipart` / `bytes` 四种请求体编码。
- `WApiException` / `WApiErrorKind`：把 `DioException` 与 decoder 异常统一成可分类的业务错误
  （timeout / network / unauthorized / forbidden / notFound / client / server / canceled / decode / unknown / business）。
- `WApiDecoder<T>`：显式 JSON → 模型映射契约。
- `WApiEnvelopeParser`：可选业务信封（`code/message/data`）；业务码失败抛
  `WApiException(kind: WApiErrorKind.business)`，带 `businessCode` / `payload`。
- `WApiClient.page` / `WPage` / `WPageQuery`：分页结果、`total` 与 `hasMore`。
- `WApiClient.upload` / `download`：multipart 上传与字节下载，支持进度与取消。
- `WApiDecoders`：`none` / `listOf` / `jsonMap` / `nullable`。
- `WApiErrorKind.business` / `WApiException.businessCode`。
- `WRetryInterceptor`：可选的幂等请求重试（GET / HEAD / PUT / DELETE / OPTIONS），
  默认只重试网络错误与 408 / 429 / 5xx，支持指数退避 + 抖动、`onRetry` / `shouldRetry`。
- `DioRegistry` 自动绑定 `WRetryInterceptor`。
- 重导出 `FormData` / `MultipartFile` / `ListFormat` / `ProgressCallback` / `HttpClientAdapter` /
  `ResponseBody`，消费方做上传或写 MockAdapter 时不必再直接依赖 `dio`。

### Changed
- `WApiClient` 统一在 `_decode` 中处理信封与 decoder 异常。

### Notes
- `decode` 必须显式传；Dart / Flutter 没有反射，`get<User>()` 不会自动反序列化。
- 依赖 `dio: ^5.10.0`（使用 `DioExceptionType.transformTimeout` 做超时分类）。
- 重试默认关闭；401 仍由 `WTokenInterceptor` 处理，POST / PATCH 永不重试。
- HTTP 缓存 / 离线不在本包范围，使用 `dio_cache_interceptor` 等外部方案。
- `WApiErrorKind` 是本次新增的类型，不存在对已发布 5.2.0 的穷尽 switch 破坏。

## 5.2.0

### Added
- `WLogInterceptor.sensitiveBodyKeys`：自定义 request / response body 的脱敏 key；默认覆盖
  `password` / `token` / `access_token` / `refresh_token` / `api_key` / `secret` 等。

### Fixed
- `WLogInterceptor` 的 `requestBody` / `responseBody` 不再明文输出敏感字段；按 key 递归脱敏
  Map / List / JSON 字符串 / FormData fields，且不修改调用方原始 body。

## 5.1.0

### Added
- `WTokenInterceptor.onAuthFailure`：刷新失败 / 未配置刷新 / 达到重试上限时回调，便于跳登录或清会话。
- `WLogInterceptor.maxBodyLength` / `sensitiveQueryKeys`：可覆盖 body 截断阈值与敏感 query 参数。
- `DioRegistry.maxCachedInstances`：可开启按最近使用淘汰的缓存上限（`null` 不限制）。
- `DioRegistry.cacheTtl`：可设置缓存惰性过期时间（`null` 不过期，默认）。
- `WApiConfig.reset()`：恢复默认 `baseOptions` 并清空日志回调，主要供测试 / 示例清理。
- `ApiClientId` 增加 `==` / `hashCode` / `toString`，同名实例可按值比较。

### Changed
- `WLogInterceptor`：默认不打印 request / response body；`parts` 只输出显式开启的片段；
  二进制 body 只输出 `<N bytes>`，文本 body 超过 2000 字符截断；URI 敏感 query 参数脱敏；
  `redactedHeaders` 大小写不敏感并补充常见敏感头。
- `WTokenInterceptor`：无 token 请求的晚到 401 不再清掉后来登录的 token；重试计数改用
  `_w_tools_retry_count`；日志不再输出 token 片段；`tokenClearer` / `observeError` 抛异常
  不再替换原始 401；共享实例第二次绑定 Dio 时报 `ArgumentError`。
- `DioRegistry`：配置比较对 header 大小写不敏感，query / extra 值按内容比较；新增可选 LRU 上限。

### Fixed
- 修复 catalog 中 `WApiConfig` 的不可编译 usage，并补齐 `WTokenInterceptor` / `WLogInterceptor` /
  `WLogPart` 的教学条目。
- 修复 example 打印 `X-Demo-Secret`、退出后未恢复 `WApiConfig.baseOptions` 的问题。

## 5.0.0

### Removed
- `WLogInterceptor` 的 6 个旧 bool 参数（`request` / `requestHeader` / `requestBody` /
  `responseHeader` / `responseBody` / `error`）：统一用 `parts: {WLogPart...}`。

## 2.1.0

### Changed
- 401 重试不再隐式创建 `DioRegistry` 实例：只复用已知 Dio（registry 自动绑定，或构造时传 `dio:`）。
  未绑定且未注册时记录错误并结束重试；裸 `Dio()` 需要显式 `dio: dio` 才能重试。

### Added
- `WTokenInterceptor(dio: ...)` / `bindDio(...)`；`DioRegistry.maybeForBaseUrl(...)`。

## 2.0.0

### Breaking
- `DioRegistry.forBaseUrl` 命中缓存时，若显式传入不同的 `options` / `interceptors` 会抛
  `ArgumentError`（此前静默忽略）。需要更换配置请先 `dispose(baseUrl)`。

### Added
- `WLogPart` + `WLogInterceptor(parts: ...)`：按片段控制日志输出。
- 重导出公开 API 用到的 dio 类型（`BaseOptions` / `Dio` / `Response` / `Options` / `Interceptor` 等），消费方无需再单独依赖 dio。

### Deprecated（5.0 移除）
- `WLogInterceptor` 的 `request` / `requestHeader` / `requestBody` / `responseHeader` /
  `responseBody` / `error` 六个 bool 参数：改用 `parts`。

## 1.0.2

### Fixed
- `WTokenInterceptor` 并发 401：晚到的 401 若发现当前 token 已与本次请求带出去的不同，会直接用新 token 重试，不再清空刚刷新成功的 token、也不再触发第二次刷新（可能导致用户被登出）。

### Tests
- 新增「快 / 慢两个请求并发 401」用例：晚到的 401 不应清 token，也不应二次刷新。

## 1.0.1

### Fixed
- `WLogInterceptor` 默认脱敏 `Authorization` / `Cookie` / `Set-Cookie` / `Proxy-Authorization` / `X-Api-Key`，并支持自定义 `redactedHeaders`。
- 长度正好 10 的 token 不再在调试日志中完整输出。
- 401 在达到重试上限时也先清除失效 token；`tokenRefresher` 为 null 时同样清除。

### Tests
- 补充敏感请求头 / 响应头脱敏、自定义脱敏头、短 token 与 401 清除边界测试。

## 1.0.0

首次发布。

- 新增 `DioRegistry`：按 `baseUrl` 缓存并复用 Dio 实例，支持 `dispose` / `clearCache`
- 新增 `WApiConfig`：统一默认 `BaseOptions`
- 新增 `WLogInterceptor`：请求 / 响应 / 错误日志
- 新增 `WTokenInterceptor`：Token 注入、401 刷新与并发 single-flight
- 新增 `BaseRepository`：统一持有本地 / 远程数据源
- 新增 `IApiPath` / `ApiClientId`：基础 URL 契约与客户端标识
