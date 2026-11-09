- **接口**（`WApiConfig` + `DioRegistry.forBaseUrl`）：不要直接 `Dio()`，裸 Dio 必须传 `dio:`；
  token 用 `WToken` + `WTokenInterceptor`，日志用 `WLogInterceptor`。细节：`explain WApiConfig`。
