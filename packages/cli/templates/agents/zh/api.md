- **接口**（`WApiConfig` + `DioRegistry.forBaseUrl`）：不要直接 `Dio()`，裸 Dio 必须传 `dio:`；
  token 用 `WToken` + `WTokenInterceptor`，日志用 `WLogInterceptor`。细节：`explain WApiConfig`。
- **调用**（`WApiClient`）：GET/POST/PUT/PATCH/DELETE 用 `WApiClient`；`decode` 必须显式传，
  不要手写 `response.data as Map`。细节：`explain WApiClient`。
