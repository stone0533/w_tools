# Changelog

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
