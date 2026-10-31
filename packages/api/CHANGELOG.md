# Changelog

## 1.0.0

首次发布。

- 新增 `DioRegistry`：按 `baseUrl` 缓存并复用 Dio 实例，支持 `dispose` / `clearCache`
- 新增 `WApiConfig`：统一默认 `BaseOptions`
- 新增 `WLogInterceptor`：请求 / 响应 / 错误日志；默认脱敏 Authorization / Cookie 等敏感头
- 新增 `WTokenInterceptor`：Token 注入、401 刷新与并发 single-flight
- 新增 `BaseRepository`：统一持有本地 / 远程数据源
- 新增 `IApiPath` / `ApiClientId`：基础 URL 契约与客户端标识
- 修复短 token（长度正好 10）在调试日志中完整输出的问题。
- 补充响应头脱敏与自定义 `redactedHeaders` 测试。
