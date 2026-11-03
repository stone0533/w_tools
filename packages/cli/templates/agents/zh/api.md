- **网络**：统一 `WApiConfig` + `DioRegistry.forBaseUrl`，不要直接 `Dio()`；
  同一 baseUrl 只初始化一次；命中后传不同配置会报错，需要先 dispose。Token 存 `w_tools_core` 的 `WToken`，通过
  `WTokenInterceptor` 的 `tokenGetter` / `tokenClearer` / `tokenRefresher` 注入；
  401 重试依赖 DioRegistry。日志用 `WLogInterceptor`，默认脱敏敏感头。
