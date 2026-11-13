> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# api 6.0 迁移

6.0 的主线是「减」：删掉数据层空壳、`WApiBody.kind`、日志友好提示，并把
`WApiConfig` 改名为 `WApiSettings`。

## 1. 改名

| 旧 | 新 |
| --- | --- |
| `WApiConfig` | `WApiSettings` |
| `WApiMetricsInterceptor` | `WMetricsInterceptor` |
| `WApiMetric` | `WMetric` |

`WApiSettings` 的日志回调参数从 `dynamic` 收紧为 `String`；正常赋值不需要改。

## 2. 删除

| 删除 | 替代 |
| --- | --- |
| `IApiPath` | `DioRegistry.forBaseUrl(baseUrl)` |
| `ApiClientId` | 直接用 `baseUrl` 区分客户端 |
| `BaseRepository` / `BaseLocalDataSource` / `BaseRemoteDataSource` | 业务项目自己定义 Repository / DataSource；库不再提供空壳 |
| `WApiBody.kind` / `WApiBodyKind` | 无；`WApiBody` 仍按命名构造器编码 |
| `WLogPart.errorHint` | UI 按 `WApiException.kind` 映射文案 |
| `WTokenInterceptor.configureRequest` / `WTokenInterceptor.configureResponse` / `WTokenInterceptor.observeError` / `WTokenInterceptor.onResponse` | 另挂普通 `Interceptor` / `InterceptorsWrapper` |

## 3. 行为变化

- `WTokenInterceptor` 不再覆盖显式 `Authorization`（大小写不敏感）。
- `WApiClient` 的 `pathParameters` 为空 Map / 未传时，路径里仍有 `{name}` 会抛
  `ArgumentError`（此前会编码成 `%7Bname%7D` 发出去）。
- `DioRegistry.maxCachedInstances <= 0` 按文档语义「不缓存」，返回的实例不会被立刻 close。
- 刷新成功但重试失败时，调用方拿到重试的真实错误；不再误触发 `onAuthFailure`。
- `WRetryInterceptor` 把 `transformTimeout` 视为可重试的网络错误。

## 4. 升级清单

1. 全局替换 `WApiConfig` → `WApiSettings`（`reset()` / `baseOptions` / 日志回调不变）。
2. 删除 `implements IApiPath` / `ApiClientId` 字段；`baseUrl` 直接传字符串。
3. Repository 改为普通类；需要容器就自己写 `final Local? local; final Remote? remote;`。
4. 日志里去掉 `WLogPart.errorHint`；需要提示时在 UI 层映射 `WApiException.kind`。
5. token 拦截器里的 `configureRequest` / `observeError` 移到单独的拦截器。
6. 指标拦截器改名；`onMetric` 参数类型改为 `WMetric`。
