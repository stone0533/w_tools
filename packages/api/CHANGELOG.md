# Changelog

## 1.0.0

首次发布。

- 新增 `DioRegistry`：按 `baseUrl` 缓存并复用 Dio 实例，支持 `dispose` / `clearCache`
- 新增 `WApiConfig`：统一默认 `BaseOptions`
- 新增 `WLogInterceptor`：请求 / 响应 / 错误日志
- 新增 `WTokenInterceptor`：Token 注入、401 刷新与并发 single-flight
- 新增 `BaseRepository`：统一请求入口与错误处理
- 新增 `IApiPath` / `ApiClientId`：基础 URL 契约与客户端标识
