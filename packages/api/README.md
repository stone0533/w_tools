# w_tools_api

[![pub package](https://img.shields.io/pub/v/w_tools_api.svg)](https://pub.dev/packages/w_tools_api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_api` 是 w_tools 的网络层，基于 Dio 提供多客户端注册、调用层、日志与 Token 拦截器、401 刷新与错误提示，以及 Repository 基类。

## 特性

- **多客户端管理**：`DioRegistry` 按 `baseUrl` 缓存并复用 Dio 实例
- **调用层**：`WApiClient` 收敛 GET / POST / PUT / PATCH / DELETE / HEAD / OPTIONS、path / query / body 与显式 JSON 解码
- **请求体**：`WApiBody` 支持 json / form / multipart / bytes
- **统一错误**：`WApiException` 按 `kind` 分类，不写死用户文案
- **拦截器**：`WLogInterceptor` 日志（默认脱敏 Authorization / Cookie 等敏感头与 password / token 等敏感 body）、`WTokenInterceptor` Token 注入与 401 刷新
- **配置收敛**：`WApiConfig` 提供默认 `BaseOptions`
- **Repository 基类**：`BaseRepository` 统一持有本地 / 远程数据源
- **路径契约**：`IApiPath` 供业务实现基础 URL

`IApiPath` / `ApiClientId` 是业务侧扩展契约，库内部不强制使用；`DioRegistry` 仍按 `baseUrl` 缓存实例。

## 安装

```yaml
dependencies:
  w_tools_api: ^5.5.0
```

```bash
flutter pub get
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:w_tools_api/w_tools_api.dart';

final registry = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WLogInterceptor(),
  ],
);

final response = await registry.dio.get('/users');
```

## 调用层：WApiClient

`DioRegistry` 负责“怎么连”，`WApiClient` 负责“怎么调”：

```dart
final client = WApiClient(registry.dio);

final user = await client.get(
  '/users/{id}',
  pathParameters: {'id': '42'},
  query: {'include': 'profile'},
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);

final created = await client.post(
  '/users',
  body: WApiBody.json({'name': 'Ada'}),
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);

await client.put('/users/42', body: WApiBody.form({'name': 'Ada'}));
await client.delete('/users/42');
```

> Dart / Flutter 没有反射，`get<User>()` 不会自动反序列化；`decode` 必须显式传
> （或用 json_serializable / freezed 生成）。失败统一抛 `WApiException`，
> 用 `kind` 分类（`timeout` / `network` / `unauthorized` / `server` / `decode` / `business` 等）。

### 原始响应（status / headers）

需要限流头、分页 total 或请求 ID 时用 `send`，它返回 `WApiResponse<T>`：

```dart
final response = await client.send<User>(
  'GET',
  '/users/42',
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);

response.data;
response.statusCode;
response.headers;
response.uri;
```

`get/post/...` 仍直接返回模型；只有需要元数据时才用 `send`。

### 业务信封（可选）

```dart
final client = WApiClient(
  registry.dio,
  envelope: WApiEnvelopeParser(
    readCode: (json) => (json as Map)['code'],
    readData: (json) => (json as Map)['data'],
    isSuccess: (code) => code == 0,
    authFailureCodes: {401},
  ),
  onAuthFailure: (error) { /* 清会话、跳登录 */ },
);
```

业务码失败会抛 `WApiException(kind: business, businessCode: ...)`；
命中 `authFailureCodes` 时抛 `kind: unauthorized` 并调用 `onAuthFailure`。
HTTP 401 仍由 `WTokenInterceptor` 处理。

### 分页

```dart
final page = await client.page(
  '/users',
  query: const WPageQuery(page: 1, pageSize: 20),
  itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
);

page.items;      // List<User>
page.hasMore;    // 有 total 时按 total 计算，否则按是否满页
page.total;
```

默认只接受 JSON 数组；后端返回 `{list: [], total: 0}` 时用
`readItems` / `readTotal` 显式读取。

### 上传 / 下载

```dart
await client.upload<void>(
  '/files',
  fields: {'bucket': 'avatar'},
  files: {'file': MultipartFile.fromBytes(bytes, filename: 'a.png')},
  onProgress: (sent, total) {},
  decode: WApiDecoders.none,
);

final bytes = await client.download(
  '/files/1',
  onProgress: (received, total) {},
);
```

`upload` 默认 `POST`；需要 PUT / PATCH 时传 `method: 'PUT'`（只允许
`POST` / `PUT` / `PATCH`）。

`download` 返回 `Uint8List`；写文件由业务层决定（Web 与移动端都可用）。

### 重试（可选）

默认不启用；需要时显式加入 `WRetryInterceptor`：

```dart
final registry = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WTokenInterceptor(...),
    WRetryInterceptor(
      maxRetries: 2,   // 最多 3 次请求（首次 + 2 次重试）
      baseDelay: const Duration(milliseconds: 300),
      onRetry: (attempt, error) {},
    ),
  ],
);
```

- 只重试幂等方法：GET / HEAD / PUT / DELETE / OPTIONS；**POST / PATCH 永不重试**；
- 默认只重试网络错误和 408 / 429 / 5xx；401 交给 `WTokenInterceptor`；
- `maxRetries` 是重试次数（不含首次）；`baseDelay` 指数退避，`jitter` 默认开启；
- HTTP 缓存 / 离线不在本包范围，可使用 `dio_cache_interceptor` 等外部方案。

> `WLogInterceptor` 只有注入 `WApiConfig.logDebugHandler` / `logErrorHandler` 后才会输出；默认不打印 request / response body，需要时显式传 `parts` 并用 `kDebugMode` 控制。URI 中 `token` / `access_token` 等敏感 query 参数默认脱敏；`requestBody` / `responseBody` 里的 `password` / `token` / `access_token` 等敏感 key 也会递归脱敏（Map / List / JSON 字符串 / FormData fields），可用 `sensitiveBodyKeys` 自定义；单条 body 超过 2000 字符会截断，可用 `maxBodyLength` 覆盖。

释放实例：

```dart
DioRegistry.dispose('https://api.example.com');
```

带 Token 时，存储交给 `w_tools_core` 的 `WToken`（需要额外依赖该包），拦截器只注入回调：

```dart
import 'package:flutter/foundation.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_core/w_tools_core.dart';

final registry = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WLogInterceptor(enableLog: kDebugMode),
    WTokenInterceptor(
      tokenGetter: WToken.getToken,
      tokenClearer: WToken.clearToken,
      tokenRefresher: () async => refreshAccessToken(),
    ),
  ],
);
```

`tokenRefresher` 由业务实现，**必须自己持久化新 token**，否则下一次 `tokenGetter` 仍返回旧值。刷新失败或达到重试上限时，可配置 `onAuthFailure` 跳登录 / 清会话：

```dart
Future<String?> refreshAccessToken() async {
  final refresh = WToken.getRefreshToken();
  if (refresh == null) return null;

  final result = await api.refresh(refresh);   // 你自己的刷新接口
  await WToken.saveToken(result.token, result.expiry);
  return result.token;
}
```

完整链路（401 → 清除 → 刷新 → 重试）在 [`example/`](example/) 里用 MockAdapter 跑通，
不需要网络与真机。

登录成功后用 `WToken.saveTokens(token, refreshToken, expiry)` 一次写全量凭证；
`saveToken` 只写 access token，适合刷新场景。

> `w_tools_api` 重导出常用 dio 类型（`BaseOptions` / `Dio` / `Response` / `Options` /
> `Interceptor` / `FormData` / `MultipartFile` / `HttpClientAdapter` / `ResponseBody` /
> `ListFormat` / `ProgressCallback` 等），消费方通常不需要再直接依赖 `dio`。

## 主要 API

| 能力 | 入口 |
|---|---|
| Dio 注册表 | `DioRegistry.forBaseUrl` / `maybeForBaseUrl` / `dispose` / `clearCache` |
| 默认配置 | `WApiConfig.baseOptions` / `WApiConfig.reset`（测试清理） |
| 调用层 | `WApiClient.get/post/put/patch/delete/head/options` |
| 原始响应 | `WApiClient.send` / `WApiResponse` |
| 请求体 | `WApiBody.json/form/multipart/bytes` |
| 业务信封 | `WApiEnvelopeParser` |
| 分页 | `WApiClient.page` / `WPage` / `WPageQuery` |
| 上传 / 下载 | `WApiClient.upload` / `download` |
| 重试（可选） | `WRetryInterceptor` |
| decoder helper | `WApiDecoders.none/listOf/jsonMap/nullable` |
| 错误分类 | `WApiException` / `WApiErrorKind` |
| 日志拦截 | `WLogInterceptor` |
| Token 拦截 | `WTokenInterceptor` |
| Repository | `BaseRepository` |
| 路径契约 | `IApiPath` / `ApiClientId` |

## 完整示例

见 [`example/`](example/)：DioRegistry、日志脱敏、401 刷新与重试（使用内存 MockAdapter，不需要网络）。

调用层示例见 [`example/lib/wapi_client_demo.dart`](example/lib/wapi_client_demo.dart)：
`WApiClient` + path / query / JSON body / 显式 decoder / 分页 / 上传。

真实项目分层写法见 [`example/lib/real_world/`](example/lib/real_world/)：
`TokenStore` 注入、登录 / 刷新、`DioException` → `ApiException` 映射、
`BaseRepository` 缓存组合，附对应测试。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。

## License

MIT
