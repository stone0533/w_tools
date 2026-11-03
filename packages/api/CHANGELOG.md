# Changelog

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
