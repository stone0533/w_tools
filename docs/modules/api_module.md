# API 模块文档

## 概述

API 模块（`w_tools_api` 子包）提供基于 Dio 的网络请求方案：Dio 实例注册表、调用层
（`WApiClient`）、错误分类、日志 / Token / 重试 / 指标拦截器，以及全局设置。

该子包**零内部依赖**：不依赖其他 w_tools 子包；日志通过 `WApiSettings` 注入回调，
Token 通过 `tokenGetter` / `tokenClearer` 注入，由调用方决定存储实现。

Cookie 管理未内置，需要时请使用社区包 [`dio_cookie_manager`](https://pub.dev/packages/dio_cookie_manager)。

## 最小用法（默认路径）

普通请求只需要 `DioRegistry` + `WApiClient`；完整示例见
[`packages/api/README.md`](../../packages/api/README.md) 的「最小用法」。
Token / 日志 / 重试 / 指标都是按需加。下面的 LRU / TTL、`replace`、`shouldRefresh`、
按请求 `envelope`、`downloadResponse`、`WMetric.attempt` 属于高级能力，默认路径不需要。

## 快速判断

- 要发请求 / 配拦截器 → `DioRegistry` + `WApiSettings`
- 统一调用 / 显式解码 / 分页 / 上传下载 → `WApiClient`
- Token 401 刷新 → `WTokenInterceptor`
- 日志 → `WLogInterceptor`（默认脱敏敏感头与敏感 body）
- 优先用 `DioRegistry`；裸 `Dio()` 必须传 `dio:`，否则 401 后无法重试
- 可运行示例：[packages/api/example](../../packages/api/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)
- 6.0 升级步骤：[api-6.0 迁移](../migrations/api-6.0.md)

## 模块结构

```text
api/
├── w_tools_api.dart                # 公开 barrel
└── src/
    ├── api.dart                    # 内部导出
    ├── api_settings.dart           # WApiSettings 全局设置
    ├── client/
    │   ├── api_client.dart         # WApiClient
    │   ├── api_body.dart           # WApiBody
    │   ├── api_decoders.dart       # WApiDecoder / WApiDecoders
    │   ├── api_envelope.dart       # WApiEnvelopeParser
    │   ├── api_exception.dart      # WApiException / WApiErrorKind
    │   ├── api_page.dart           # WPageQuery / WPage
    │   ├── api_response.dart       # WApiResponse
    │   └── dio_registry.dart       # DioRegistry
    └── interceptors/
        ├── log.dart                # WLogInterceptor / WLogPart
        ├── metrics.dart            # WMetricsInterceptor / WMetric
        ├── retry.dart              # WRetryInterceptor
        └── token.dart              # WTokenInterceptor
```

---

## 1. DioRegistry - Dio 实例注册表

按 `baseUrl` 缓存并复用 `Dio` 实例，避免重复创建。配置直接使用 Dio 的 `BaseOptions`。
传入的 `BaseOptions` 会被**复制**并注入 `baseUrl`，因此传入实例不会被修改，多个
Dio 实例之间也不会共享同一份可变配置。

### 核心方法

| 成员 | 说明 |
|------|------|
| `DioRegistry.forBaseUrl(baseUrl, {options, interceptors})` | 获取或创建指定 `baseUrl` 的实例 |
| `dio` | 获取内部 `Dio` 实例 |
| `DioRegistry.maybeForBaseUrl(baseUrl)` | 读取已注册的 `Dio`，不创建新实例 |
| `DioRegistry.dispose(baseUrl)` | 关闭并移除指定 `baseUrl` 的实例 |
| `DioRegistry.clearCache()` | 关闭并清空所有缓存实例 |
| `maxCachedInstances` | 已弃用（7.0 删除）；缓存上限，`null` 不限制，`<= 0` 不缓存 |
| `cacheTtl` | 已弃用（7.0 删除）；缓存惰性过期，`null` 不过期 |

> 同一 `baseUrl` 命中缓存后返回已有实例；如果这次显式传入了**不同**的
> `options` / `interceptors`，会抛 `ArgumentError`。需要更换配置用
> `DioRegistry.forBaseUrl(..., replace: true)` 或先 `DioRegistry.dispose(baseUrl)`；
> `replace` 会 `close(force: true)`；LRU / TTL 淘汰用 `close(force: false)`，
> 不强制中断在途请求。
>
> `BaseOptions` 的 `headers` / `extra` / `queryParameters` 都会被复制，实例之间不共享
> 可变 Map。
>
> `maxCachedInstances` / `cacheTtl` 已弃用（7.0 删除）；`maxCachedInstances <= 0` 时不缓存：每次 `forBaseUrl` 都新建实例，返回的实例仍可用，
> 但注册表不持有它；需要释放时由调用方 `registry.dio.close(force: true)`。

### 使用示例

```dart
final registry = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WLogInterceptor(parts: {WLogPart.request, WLogPart.error}),
    WTokenInterceptor(tokenGetter: () => token),
  ],
);
final response = await registry.dio.get('/users');

DioRegistry.dispose('https://api.example.com');
```

---

## 2. WLogInterceptor - 日志拦截器

默认脱敏 `Authorization` / `Cookie` / `Set-Cookie` / `Proxy-Authorization` / `X-Api-Key` /
`X-Auth-Token` 等敏感头；`redactedHeaders` 会与内置集合合并（大小写不敏感），不能整体替换默认值。

按 `parts`（`WLogPart`）打印请求与响应详情，输出经 `WApiSettings.logDebugHandler` /
`WApiSettings.logErrorHandler`。`parts` 为 `null` 时使用包内默认值（默认不打印
request / response body）；传空集合表示全部关闭。

### 配置参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `parts` | `Set<WLogPart>?` | 要输出的片段：`request` / `requestHeader` / `requestBody` / `responseHeader` / `responseBody` / `error` |
| `redactedHeaders` | `Set<String>?` | 脱敏头列表；默认追加到内置敏感头 |
| `sensitiveQueryKeys` | `Set<String>?` | 需要脱敏的 query 参数；默认追加 `token` / `access_token` 等 |
| `sensitiveBodyKeys` | `Set<String>?` | 需要脱敏的 body key；默认追加 `password` / `token` / `access_token` 等 |
| `maxBodyLength` | int | 单条 body 最大字符数（默认 2000，`<= 0` 不截断） |

> 显式传 `parts` 时，未列出的片段不会输出；需要 body 时显式加
> `requestBody` / `responseBody`，并用 `kDebugMode` 控制。URI 中 `token` /
> `access_token` 等敏感 query 参数默认脱敏；`requestBody` / `responseBody` 的
> Map / List / JSON 字符串 / FormData fields 会按 `sensitiveBodyKeys` 递归脱敏；
> 自定义 key 会与内置集合合并；
> 单条 body 超过 2000 字符会截断。
>
> 6.0 起日志只输出技术信息，不再内置面向用户的「友好提示」文案；UI 提示请按
> `WApiException.kind` 自行映射。
>
> 只开 `responseHeader` / `responseBody` 时，错误响应片段也会输出（不需要同时开 `error`）。

### 使用示例

```dart
final logInterceptor = WLogInterceptor(
  parts: {
    WLogPart.request,
    WLogPart.requestHeader,
    if (kDebugMode) WLogPart.requestBody,
    if (kDebugMode) WLogPart.responseBody,
    WLogPart.error,
  },
);
```

---

## 3. WTokenInterceptor - 令牌拦截器

自动为请求添加 `Authorization: Bearer <token>`，并在收到未授权错误时清除 Token、
请求新 Token 并重试。请求已显式带 `Authorization` 时不覆盖（大小写不敏感），
登录 / 公开接口可以自己控制该头。

存储通过依赖注入解耦：`tokenGetter` / `tokenClearer` 由调用方提供。

### 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `tokenGetter` | `String? Function()?` | null | 读取当前 token |
| `tokenClearer` | `Future<void> Function()?` | null | 清除 token |
| `tokenRefresher` | `Future<String?> Function()?` | null | 刷新 token，返回新 token（返回 null 表示失败） |
| `onAuthFailure` | `void Function(DioException)?` | null | 刷新失败 / 无刷新器 / 达到重试上限时回调 |
| `shouldRefresh` | `bool Function(RequestOptions)?` | null | 每次 401 是否允许自动刷新；返回 false 时直接交出 401 |
| `unauthorizedStatusCode` | int | 401 | 未授权状态码 |
| `maxAuthRetries` | int | 1 | 认证重试上限 |

### 行为说明

- 请求已显式带 `Authorization` 时跳过注入；否则按 `tokenGetter` 注入。
- 同一个 `WTokenInterceptor` 只能绑定一个 Dio；多个 registry 请各建实例，共享实例会在第二次绑定时报 `ArgumentError`。
- 登录 / 刷新 / 公开接口可用 `shouldRefresh` 跳过自动刷新；返回 false 时不清理、不刷新、不重试。
- 刷新失败 / 未配置 `tokenRefresher` / 达到 `maxAuthRetries` 时调用 `onAuthFailure`，适合跳登录或清会话。
- **并发 401 共享同一次刷新（single-flight）**，不会重复调用 `tokenRefresher`。
- `tokenRefresher` 抛出的异常会被捕获并记录日志，请求以原错误结束，不会逃逸出拦截器链。
- 刷新成功但重试请求失败（例如 500）时，调用方拿到的是**重试的真实错误**，不会误触发
  `onAuthFailure`。
- 刷新契约：`tokenRefresher` 取得新 token 后应自行持久化，使 `tokenGetter` 随后返回新 token；若提供 `tokenClearer`，须保证清除后 `tokenGetter` 不再返回旧 token（返回 null 亦可，此时重试会使用拦截器显式写入的新 token）。
- 重试会**重新经过整条请求拦截器链**（请保证 `onRequest` 逻辑幂等）；`FormData` 请求体会在重放前被 `clone()`，`Stream` 请求体无法重放，此时放弃重试并记录日志。
- 重试只复用已知 Dio：`DioRegistry` 自动绑定；裸 `Dio()` 需构造传 `dio:`。若同 `baseUrl` 已有 registry，裸 Dio 的 401 会落到该实例（配置可能不一致）；否则不重试并记录错误。

### 使用示例

```dart
final tokenInterceptor = WTokenInterceptor(
  tokenGetter: () => WToken.getToken(),
  tokenClearer: WToken.clearToken,   // 只清 access token；clearAllTokens 会删掉 refresher 依赖的 refresh token
  tokenRefresher: () async => await refreshToken(),
  unauthorizedStatusCode: 401,
);
```

> 公共 header、响应加工、错误观测不要塞进 token 拦截器：再挂一个普通
> `Interceptor` 或 `InterceptorsWrapper` 即可。

---

## 4. WApiSettings - 全局设置

| 字段 | 说明 |
|------|------|
| `baseOptions` | 全局默认 `BaseOptions`（可覆盖；`DioRegistry` 使用时复制，不修改原实例） |
| `logDebugHandler` | Debug 日志回调，需显式注入 |
| `logErrorHandler` | Error 日志回调，需显式注入 |
| `reset()` | 恢复默认 `baseOptions` 并清空日志回调，主要供测试 / 示例清理 |

```dart
WApiSettings.baseOptions = BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
);
WApiSettings.logDebugHandler = (m) => debugPrint('$m');
WApiSettings.logErrorHandler = (m) => debugPrint('[E] $m');
```

> 默认 `BaseOptions` 只设 connect / receive 超时，不设 `sendTimeout`；大文件上传请显式设置。
> `reset()` 只重置设置；`DioRegistry` 的实例缓存用 `DioRegistry.clearCache()` 单独清理。

---

## 5. WApiClient - 调用层

在 `DioRegistry` 之上收敛 HTTP 方法、参数编码、JSON 解码与错误分类。只负责「怎么调」，
不负责 token（`WTokenInterceptor`）、日志、缓存和业务编排。

```dart
final client = WApiClient(registry.dio);

final user = await client.get(
  '/users/{id}',
  pathParameters: {'id': '42'},
  query: {'include': 'profile'},
  decode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### 方法与参数

| 成员 | 说明 |
|------|------|
| `get` / `post` / `put` / `patch` / `delete` / `head` / `options` | HTTP 方法 |
| `send` | 任意方法，返回 `WApiResponse<T>`（含 status / headers），支持 `onReceiveProgress` 与按请求 `envelope` |
| `pathParameters` | 替换 `{id}` 模板，并对值做 `Uri.encodeComponent`；缺参数抛 `ArgumentError` |
| `query` | 值为 `null` 的键会被丢弃 |
| `body` | 原始值（Map / String / FormData…）或 `WApiBody` |
| `decode` | `T Function(Object? json)`；不传则返回原始 JSON |
| `WApiBody` | `json` / `form` / `multipart` / `bytes` 四种编码 |
| `page` | GET 分页，返回 `WPage<T>`（`items` / `total` / `hasMore`）；`readTotalFromResponse` 可从响应头读 total，`envelope` 可按请求覆盖 |
| `upload` | `multipart/form-data` 上传；`method` 支持 POST / PUT / PATCH |
| `download` | 已弃用（7.0 删除）；下载并返回 `Uint8List` |
| `downloadResponse` | 下载并保留 status / headers / requestOptions |
| `WApiDecoders` | 常用 decoder：`none` / `listOf` / `jsonMap` / `nullable` |
| `WApiException` | 统一错误分类；`kind` 供 UI 映射文案 |

### 原始响应（WApiResponse）

```dart
final raw = await client.send(
  'HEAD',
  '/users',
);
raw.statusCode;
raw.headers.value('x-total-count');
```

`WApiResponse<T>` 保留 `data` / `statusCode` / `headers` / `requestOptions`；
`get/post/...` 仍只返回 `data`。

### 业务信封（可选）

很多后端返回 `{code, message, data}`；默认不假设信封，传 `WApiEnvelopeParser` 才启用：

```dart
final client = WApiClient(
  registry.dio,
  envelope: WApiEnvelopeParser(
    readCode: (json) => (json as Map)['status'],
    readData: (json) => (json as Map)['result'],
    readMessage: (json) => (json as Map)['msg'] as String?,
    isSuccess: (code) => code == 'ok',
    authFailureCodes: {401},
  ),
  onAuthFailure: (error) { /* 清会话、跳登录 */ },
);
```

- 业务码失败 → `WApiException(kind: WApiErrorKind.business)`，带
  `businessCode` / `payload`；
- 命中 `authFailureCodes` → `kind: unauthorized`，并调用 `WApiClient.onAuthFailure`；
- 成功时 `decode` 拿到的是 `data`，不是整个信封；
- HTTP 401 仍由 `WTokenInterceptor` 处理；
- 204 / 空 body 默认跳过信封（`skipEmptyBody: true`），不会调用 `readCode(null)`；
  需要旧行为时显式传 `skipEmptyBody: false`；
- 需要只对某条请求启用 / 覆盖信封时，用 `client.send(..., envelope: parser)` 或
  `client.page(..., envelope: parser)`。

### 分页

```dart
final page = await client.page(
  '/users',
  query: const WPageQuery(page: 1, pageSize: 20),
  itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

`WPage.hasMore`：有 `total` 时按 `page * pageSize < total` 计算，否则按本页是否满页。
服务端若把 pageSize 截得比请求小，按满页判断可能提前结束；这种场景请让后端返回 total。
默认只接受 JSON 数组；Map 结构用 `readItems` / `readTotal` 显式读取；total 在响应头
（如 `X-Total-Count`）时用 `readTotalFromResponse`。页面状态仍交给
`WAsyncPagedController`，`WPage` 只做传输层结果。`page` 只支持 1-based 页码分页；
offset / cursor 后端用 `WApiClient.send` 手工请求并构造 `WPage`。

### 上传 / 下载

```dart
await client.upload<void>(
  '/avatars',
  files: {'avatar': MultipartFile.fromBytes(bytes)},
  onProgress: (sent, total) {},
  decode: WApiDecoders.none,
);

final response = await client.downloadResponse('/avatars/me');
response.data;                                  // Uint8List
response.headers.value('content-disposition');  // 文件名
```

Web 上不要用 `MultipartFile.fromFile`，用 `fromBytes`；下载得到 `Uint8List`，
是否写入文件由业务层决定。

### 注意

- Dart / Flutter 没有反射，`get<User>()` 不会自动反序列化；必须显式 `decode`
  （或用 json_serializable / freezed 生成）。
- `decode` 抛出的异常会包装成 `WApiException(kind: WApiErrorKind.decode)`，不会漏成 `TypeError`。
- 用户传入的 `content-type` 优先于 `WApiBody` 的默认值。
- 重试见第 6 节（可选）；HTTP 缓存 / 离线不在当前范围；401 刷新仍由 `WTokenInterceptor` 负责。

---

## 6. WRetryInterceptor - 可选重试

默认不启用，显式加入 `DioRegistry` 才生效：

```dart
final registry = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WTokenInterceptor(...),
    WRetryInterceptor(maxRetries: 2),
  ],
);
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `maxRetries` | 2 | 重试次数（不含首次请求） |
| `baseDelay` | 300ms | 指数退避基数 |
| `maxDelay` | 5s | 单次等待上限 |
| `retryOnMethods` | GET / HEAD / PUT / DELETE / OPTIONS | 幂等方法 |
| `retryOnStatusCodes` | 408 / 429 / 500 / 502 / 503 / 504 | 可重试状态码 |
| `retryOnConnectionErrors` | true | 连接 / 超时错误（含 `transformTimeout`） |
| `jitter` | true | 50%–100% 抖动，避免同时重试 |
| `onRetry` | null | 每次重试前回调 |
| `shouldRetry` | null | 自定义是否重试 |

- 不重试 401（交给 `WTokenInterceptor`）、其他 4xx、`unknown`（默认）和已取消的请求；
  需要放行 `unknown` 用 `shouldRetry`；
- `POST` / `PATCH` 默认不重试（避免重复提交）；显式覆盖 `retryOnMethods` 后自行保证幂等；
- 单条请求关闭重试：`Options(extra: {WRetryInterceptor.disableRetryExtraKey: true})`；
- 裸 `Dio` 需构造传 `dio:` 或手动 `bindDio`；`DioRegistry` 会自动绑定；
- 缓存 / 离线不在本包范围，使用 `dio_cache_interceptor` 等外部方案。

---

## 7. WMetricsInterceptor - 可选指标

默认不启用，显式加入 `DioRegistry` 才生效；只观测，不写日志 / 不上报：

```dart
final metrics = WMetricsInterceptor(
  sampleRate: 0.1,
  onMetric: (m) => print('${m.method} ${m.path} ${m.statusCode}'),
);
```

| 字段 | 说明 |
|------|------|
| `method` | HTTP 方法（大写） |
| `uri` | 完整 URI，可能带 query |
| `path` | 不含 query 的路径 |
| `duration` | 从请求开始到响应 / 错误 |
| `statusCode` | HTTP 状态码，网络错误为 null |
| `failed` | 网络错误或 4xx / 5xx |
| `error` | 原始错误（失败时） |
| `attempt` | 第几次尝试（首次 1，重试 / 401 刷新递增） |

- `onMetric` 抛异常会被吞掉，不影响请求；
- 401 刷新 / 重试每次尝试都会各产生一条；是否每条都出取决于拦截器顺序，
  严格场景把 metrics 放在重试 / token 之前；
- `sampleRate` 取值 0–1，0 表示关闭。

---

## 完整配置示例

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:w_tools/w_tools.dart';

void setupApi() {
  // 全局 Dio 基础配置（可选）
  WApiSettings.baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  // 日志回调
  WApiSettings.logDebugHandler = (m) => WLogger.d(m);
  WApiSettings.logErrorHandler = (m) => WLogger.e(m);

  // 创建带拦截器的 Dio 实例
  final registry = DioRegistry.forBaseUrl(
    'https://api.example.com',
    interceptors: [
      WLogInterceptor(parts: {WLogPart.request, WLogPart.error}),
      WTokenInterceptor(tokenGetter: () => token),
    ],
  );
}
```

---

## 拦截器执行顺序

拦截器按添加顺序在请求方向正序执行、响应方向倒序执行（Dio 标准行为）：

```text
请求方向:  interceptors[0] → interceptors[1] → ... → 网络请求
响应方向:  网络响应 → ... → interceptors[1] → interceptors[0] → 业务代码
```

---

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| 连接超时 / 发送超时 / 接收超时 / 转换超时 | `WApiException.kind == timeout`；`WRetryInterceptor` 可重试 |
| 网络连接失败 / 证书校验失败 | `WApiException.kind == network`；`WRetryInterceptor` 可重试 |
| 401 未授权 | `WTokenInterceptor` 清除 Token，尝试刷新并重试（受 `maxAuthRetries` 限制） |
| 403 / 404 / 其他 4xx | `WApiException.kind` 分别为 `forbidden` / `notFound` / `client` |
| 5xx | `WApiException.kind == server`；`WRetryInterceptor` 可重试 |
| 请求取消 | `WApiException.kind == canceled` |
| 响应解码失败 | `WApiException.kind == decode`，`cause` 保留原始异常 |
| 业务码失败 | `WApiException.kind == business`，带 `businessCode` / `payload` |

---

## 安全特性

- ✅ Token 日志不输出任何 token 片段（仅记录「已注入」）
- ✅ `DioRegistry` 使用前复制 `BaseOptions`，避免实例间共享可变配置
- ✅ 日志默认脱敏敏感头、敏感 query 与敏感 body key

---

## 全局状态

- `DioRegistry` 是进程级静态缓存，按精确 `baseUrl` 缓存；可用
  `maxCachedInstances` / `cacheTtl` 已弃用（7.0 删除）；缓存开启 LRU 时 `null` 不限制，用 `cacheTtl` 设置惰性过期，
  或 `dispose(baseUrl)` / `clearCache()` 手动清理。`<= 0` 表示不缓存。
  LRU / TTL 淘汰不强制中断在途请求；显式 `dispose` / `clearCache` 仍 `force: true`。
- `WApiSettings` 是全局可变设置；`baseOptions` 在 registry 创建时复制，之后修改只影响
  新实例。测试 / 示例可用 `WApiSettings.reset()` + `DioRegistry.clearCache()` 清理。
- 数据源 / Repository 由业务项目自己定义，本包不再提供空壳基类。

---

## 相关文档

- [w_tools_core — WToken / WStorage](core_module.md)：Token 的持久化存储（`WToken` + `WStorage`）在 core 子包，`WTokenInterceptor` 通过 `tokenGetter` / `tokenClearer` 回调与它们解耦。
- [w_tools_core — WLogger](core_module.md)：`WApiSettings.logDebugHandler` / `logErrorHandler` 通常对接 `WLogger.d` / `WLogger.e`。
- [w_tools_async — WAsync](async_module.md)：网络请求的加载状态管理可配合 `WAsync` / `WAsyncController` 与 `WAsyncOptions.loading`。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
