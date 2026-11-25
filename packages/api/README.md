# w_tools_api

[![pub package](https://img.shields.io/pub/v/w_tools_api.svg)](https://pub.dev/packages/w_tools_api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_api` 是 w_tools 的网络层，基于 Dio 提供多客户端注册、调用层、日志与 Token 拦截器、401 刷新与错误分类。

## 最小用法（默认路径）

普通请求只需要 `DioRegistry` + `WApiClient`：

```dart
final registry = DioRegistry.forBaseUrl('https://api.example.com');
final client = WApiClient(registry.dio);

final user = await client.get(
  '/users/{id}',
  pathParameters: {'id': '42'},
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

Token、日志、重试、指标都是按需加；下面「高级配置」里的缓存上限 / TTL、`replace`、
`shouldRefresh`、按请求 `envelope`、`downloadResponse`、`WMetric.attempt` 都不是默认路径。

## 特性

- **多客户端管理**：`DioRegistry` 按 `(baseUrl, key)` 缓存并复用 Dio 实例，支持 `replace` 重建
- **调用层**：`WApiClient` 收敛 GET / POST / PUT / PATCH / DELETE / HEAD / OPTIONS、path / query / body 与显式 JSON 解码
- **请求体**：`WApiBody` 支持 json / form / multipart / bytes
- **统一错误**：`WApiException` 按 `kind` 分类，不写死用户文案
- **拦截器**：`WLogInterceptor` 日志（默认脱敏 Authorization / Cookie 等敏感头与 password / token 等敏感 body）、`WTokenInterceptor` Token 注入与 401 刷新
- **配置收敛**：`WApiSettings` 提供默认 `BaseOptions` 与日志回调
- **元数据**：`WApiClient.send` / `downloadResponse` 保留 status / headers，`page` 可从响应头读 total
- **可选重试 / 指标**：`WRetryInterceptor`、`WMetricsInterceptor`（默认关闭）

## 安装

```yaml
dependencies:
  w_tools_api: ^6.5.0
```

```bash
flutter pub get
```

> 本包最低要求 Flutter 3.38.0。从 5.x 升级先看 [`docs/migrations/api-6.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/api-6.0.md)：
> `WApiConfig` → `WApiSettings`、删除空壳数据层 / `WApiBody.kind` / 日志友好提示。

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
需要单条请求临时覆盖信封时，给 `send` / `page` 传 `envelope:`。

### 单条请求的 options

除已弃用的 `page` / `download` 外，所有请求方法都接受 `options:`（dio 的 `Options`），
用来做单条请求的 dio 级配置：

```dart
// 本次不重试（配合 WRetryInterceptor）
await client.get<void>(
  '/items/1',
  options: Options(extra: {WRetryInterceptor.disableRetryExtraKey: true}),
  decode: WApiDecoders.none,
);

// 接受 409 作为业务结果，用 send 读 statusCode
final response = await client.send<Map<String, dynamic>>(
  'POST',
  '/items/1',
  options: Options(validateStatus: (status) => status == 409),
);
```

合并优先级：`method` 永远由调用的方法决定；`headers` 参数 > `options.headers`；
显式 `Content-Type` 头 > `options.contentType` > `WApiBody` 的默认类型；其余字段
（`extra` / `validateStatus` / `responseType` / `listFormat` / 超时等）原样透传。
`downloadResponse` 的 `responseType` 固定为 `bytes`，其余字段同样可用。

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

需要按请求覆盖时：

```dart
final user = await client.send(
  'GET',
  '/users/42',
  envelope: WApiEnvelopeParser(...),   // 只影响这一次
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

204 / 空 body 默认跳过信封解析（`skipEmptyBody: true`），`readCode` 不需要
自己处理 null；需要旧行为时显式传 `skipEmptyBody: false`。

### 分页

> `WApiClient.page` / `WPage` / `WPageQuery` 已弃用（7.0 删除）。
> 分页参数名、额外 query、total 的位置在不同后端差异很大，不再做通用分页类型。

在 Repository 里按 API 自己取：

```dart
final json = await client.get<Map<String, dynamic>>(
  '/users',
  query: {
    'pageNo': 1,
    'size': 20,
    'status': 'active',
  },
);

final data = json['data'] as Map<String, dynamic>;
final items = (data['list'] as List)
    .map((e) => User.fromJson(e as Map<String, dynamic>))
    .toList();
final total = data['total'] as int?;
final hasMore = total == null ? items.length >= 20 : 1 * 20 < total;
```

需要把分页交给 UI 时，在业务层映射到 `WAsyncPage`（`w_tools_async`），
不要在页面里维护 `page` / `hasMore`。total 在响应头时用 `client.send` 读 headers。

### 上传 / 下载

```dart
await client.upload<void>(
  '/files',
  fields: {'bucket': 'avatar'},
  files: {'file': MultipartFile.fromBytes(bytes, filename: 'a.png')},
  onProgress: (sent, total) {},
  decode: WApiDecoders.none,
);

final response = await client.downloadResponse(
  '/files/1',
  onProgress: (received, total) {},
);
response.data;
```

`upload` 默认 `POST`；需要 PUT / PATCH 时传 `method: 'PUT'`（只允许
`POST` / `PUT` / `PATCH`）。

`downloadResponse` 返回 `WApiResponse<Uint8List>`，保留 status / headers；写文件由业务层决定。
`download`（仅返回 bytes）已弃用，7.0 删除。

```dart
final response = await client.downloadResponse('/files/1');
response.data;                                  // Uint8List
response.headers.value('content-disposition');  // 文件名
```

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

- 只重试幂等方法：GET / HEAD / PUT / DELETE / OPTIONS；**POST / PATCH 默认不重试**（显式覆盖 `retryOnMethods` 后自行保证幂等）；
- 默认只重试网络错误和 408 / 429 / **500 / 502 / 503 / 504**；401 交给 `WTokenInterceptor`；
  501 / 505 / 506 / 507 / 508 / 510 / 511 默认不重试（重试通常无收益），需要时用
  `retryOnStatusCodes` 显式覆盖；
- `DioExceptionType.unknown` 默认不重试；需要放行时用 `shouldRetry` 自定义；
- 单条请求关闭重试：`client.get(..., options: Options(extra: {WRetryInterceptor.disableRetryExtraKey: true}))`；
- `maxRetries` 是重试次数（不含首次）；`baseDelay` 指数退避，`jitter` 默认开启；
- HTTP 缓存 / 离线不在本包范围，可使用 `dio_cache_interceptor` 等外部方案。

### 指标（可选）

`WMetricsInterceptor` 只产出 `WMetric`，不写日志、不上报：

```dart
final metrics = WMetricsInterceptor(
  onMetric: (metric) {
    analytics.track('http', {
      'method': metric.method,
      'path': metric.path,
      'status': metric.statusCode,
      'ms': metric.duration.inMilliseconds,
    });
  },
);
```

- 默认全量采样；`sampleRate: 0.1` 可抽样；
- 回调抛异常会被吞掉，不影响请求；
- 401 刷新 / 重试每次尝试都会各产生一条（`WMetric.attempt` 从 1 递增）；
  是否每次尝试都出 metric 取决于拦截器顺序，严格场景把 metrics 放在重试 / token 之前；
- `uri` 可能带 query，上报用 `path` 或自行过滤敏感参数。

> `WLogInterceptor` 只有注入 `WApiSettings.logDebugHandler` / `logErrorHandler` 后才会输出；默认不打印 request / response body，需要时显式传 `parts` 并用 `kDebugMode` 控制。URI 中 `token` / `access_token` 等敏感 query 参数默认脱敏；`requestBody` / `responseBody` 里的 `password` / `token` / `access_token` 等敏感 key 也会递归脱敏（Map / List / JSON 字符串 / FormData fields），自定义 key 会与内置集合合并；单条 body 超过 2000 字符会截断，可用 `maxBodyLength` 覆盖。

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
    WTokenInterceptor(
      tokenGetter: WToken.getToken,
      tokenClearer: WToken.clearToken,
      tokenRefresher: () async => refreshAccessToken(),
    ),
    WLogInterceptor(parts: {WLogPart.request, WLogPart.error}),
  ],
);
```

### 刷新客户端（同一 baseUrl 的第二套配置）

`WTokenInterceptor.tokenRefresher` 是调用方自管的刷新入口。刷新请求通常需要更长的
`connectTimeout`，并且**不能**再挂 `WTokenInterceptor`（否则刷新请求返回 401 会递归）。
用 `key` 给同一 baseUrl 开第二个桶，仍然走 registry：

```dart
final refresh = DioRegistry.forBaseUrl(
  'https://api.example.com',
  key: 'refresh',
  options: WApiSettings.baseOptions.copyWith(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ),
  // 只挂日志等无 401 刷新的拦截器；不要挂 WTokenInterceptor。
  interceptors: [WLogInterceptor(parts: {WLogPart.request, WLogPart.error})],
);
final response = await refresh.dio.post<Map<String, dynamic>>(
  '/auth/refresh',
  data: {'refresh_token': currentRefreshToken},
);
// 解析 response.data 里的 access_token，持久化后让 tokenGetter 返回新值。
```

默认 key（null）和 `key: 'refresh'` 是两个独立桶，互不冲突；`dispose(baseUrl)` 会清理
该 baseUrl 下的所有桶，`dispose(baseUrl, key: 'refresh')` 只清刷新桶。

### 拦截器顺序与绑定

- `DioRegistry.forBaseUrl(interceptors: [...])` 会为 `WTokenInterceptor` /
  `WRetryInterceptor` 自动绑定 Dio；用裸 `Dio()` 自己 `interceptors.add(...)` 时必须
  构造传 `dio: dio`，否则 401 刷新与重试都无法重放请求（只在错误时放弃，默认不打印日志）。
- 请求方向按添加顺序执行：要把注入 `Authorization` 之后的头写进日志，`WLogInterceptor`
  必须放在 `WTokenInterceptor` **后面**（想同时记录 401 刷新前的原始头，就再挂一个放在前面）。
- 想让 `WMetricsInterceptor` 统计每次重试尝试，把它放在 token / retry 之前；
  只要最终结果就放在后面。
- `WRetryInterceptor` 只管重放，不做 token 刷新；401 永远交给 `WTokenInterceptor`。

登录 / 刷新 / 公开接口等需要自己处理 401 时，可传 `shouldRefresh`：

```dart
WTokenInterceptor(
  tokenGetter: WToken.getToken,
  tokenRefresher: refreshAccessToken,
  shouldRefresh: (options) => !options.path.contains('/auth/'),
);
```

返回 `false` 时不会清除 token、不会刷新、也不会重试，直接把原始 401 交给调用方。

请求自己带了 `Authorization`（API Key / 第三方 token 等）时，401 不会被自动处理：
不清理 session token、不刷新、也不会改用 session token 重试，原 401 直接交给调用方。
需要自动刷新时让 `WTokenInterceptor` 注入 token，或自行处理 401。

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

## 高级配置（按需）

| 能力 | 什么时候用 | 入口 |
|---|---|---|
| 换配置 / 重建实例 | 同 `baseUrl` 要换 options / interceptors | `DioRegistry.forBaseUrl(..., replace: true)` |
| 缓存上限 / TTL（已弃用，7.0 删除） | 多域名、长驻进程 | `DioRegistry.maxCachedInstances` / `cacheTtl` |
| 登录 / 刷新接口跳过自动刷新 | 这些接口自己处理 401 | `WTokenInterceptor.shouldRefresh` |
| 单条请求覆盖信封 | 同一个 client 混用不同后端 | `client.send(..., envelope: ...)` |
| 单条请求 dio 配置 | 关重试 / 接受 409 / 换 responseType | `client.get(..., options: Options(...))` |
| 下载元数据 | 需要文件名 / Content-Type | `client.downloadResponse(...)` |
| 页头 total | 后端把 total 放在 `X-Total-Count` | `client.send(...)` 读 `WApiResponse.headers` |
| 自定义重试边界 | 只对特定路径 / 状态重试 | `WRetryInterceptor.shouldRetry` / `disableRetryExtraKey` |
| 请求指标 | 埋点 / 监控 | `WMetricsInterceptor` |

这些能力默认不启用；不要为了用而用。普通请求保持“registry + client”两层即可。

## 主要 API

| 能力 | 入口 |
|---|---|
| Dio 注册表 | `DioRegistry.forBaseUrl(replace:)` / `maybeForBaseUrl` / `dispose` / `clearCache` |
| 默认配置 | `WApiSettings.baseOptions` / `WApiSettings.reset`（测试清理） |
| 调用层 | `WApiClient.get/post/put/patch/delete/head/options`（均支持 `options:`） |
| 原始响应 | `WApiClient.send` / `WApiResponse` |
| 下载响应 | `WApiClient.downloadResponse` |
| 请求体 | `WApiBody.json/form/multipart/bytes` |
| 业务信封 | `WApiEnvelopeParser` |
| 分页 | 已弃用：`WApiClient.page` / `WPage` / `WPageQuery`（7.0 删除） |
| 上传 / 下载 | `WApiClient.upload` / `downloadResponse`（`download` 已弃用） |
| 重试（可选） | `WRetryInterceptor` |
| decoder helper | `WApiDecoders.none/listOf/jsonMap/nullable` |
| 错误分类 | `WApiException` / `WApiErrorKind` |
| 日志拦截 | `WLogInterceptor` |
| Token 拦截 | `WTokenInterceptor` |
| 指标（可选） | `WMetricsInterceptor` / `WMetric` |

## 完整示例

见 [`example/`](example/)：DioRegistry、日志脱敏、401 刷新与重试（使用内存 MockAdapter，不需要网络）。

调用层示例见 [`example/lib/wapi_client_demo.dart`](example/lib/wapi_client_demo.dart)：
`WApiClient` + path / query / JSON body / 显式 decoder / 分页 / 上传。

真实项目分层写法见 [`example/lib/real_world/`](example/lib/real_world/)：
`TokenStore` 注入、登录 / 刷新、`DioException` → `ApiException` 映射、
本地缓存 + 远程数据源组合，附对应测试。

## 选型：WApiClient / retrofit / OpenAPI

| 路线 | 适用场景 | 成本 | 与 w_tools_api 的关系 |
|---|---|---|---|
| `WApiClient` + 手写 `fromJson` | 模型少、后端无契约 | 低 | 本包默认；`decode` 显式传 |
| `json_serializable` / `freezed` | 模型多、嵌套 / 日期 / 枚举多 | 中 | 只生成 DTO；`WApiClient` 继续做调用 |
| retrofit | 接口多、团队协作 | 中高 | 替代接口层；`DioRegistry` / 拦截器仍可用 |
| OpenAPI 生成 | 后端有 Swagger / OpenAPI | 低（生成） | 生成 client + model；`WApiClient` 可不参与 |

retrofit 的接口写法（示例，不在本包内）：

```dart
@GET('/users/{id}')
Future<User> getUser(@Path('id') int id);
```

不要在本仓库自研注解代码生成器；缓存 / 离线用 `dio_cache_interceptor` 等外部方案。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。

## License

MIT
