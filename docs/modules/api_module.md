# API 模块文档

## 概述

API 模块（`w_tools_api` 子包）提供了一套基于 Dio 封装的网络请求方案，包含 Dio 实例管理（配置直接使用 Dio 的 `BaseOptions`）、拦截器体系和数据仓库基类。

该子包**零内部依赖**：不依赖其他 w_tools 子包；日志通过 `WApiConfig` 注入回调，Token 通过 `tokenGetter` / `tokenClearer` 注入，由调用方决定存储实现。

Cookie 管理未内置，需要时请使用社区包 [`dio_cookie_manager`](https://pub.dev/packages/dio_cookie_manager)。

## 快速判断
- 要发请求 / 配拦截器 → `DioRegistry` + `WApiConfig`
- Token 401 刷新 → `WTokenInterceptor`
- 日志 → `WLogInterceptor`（默认脱敏敏感头与敏感 body）
- 优先用 `DioRegistry`；裸 `Dio()` 必须传 `dio:`，否则 401 后无法重试
- 可运行示例：[packages/api/example](../../packages/api/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```
api/
├── w_tools_api.dart                # 公开 barrel
└── src/
    ├── api.dart                    # 内部导出
    ├── api_config.dart             # WApiConfig 全局配置
    ├── common.dart                 # IApiPath / ApiClientId
    ├── client/
    │   ├── api_client.dart         # WApiClient / WApiBody / WPage / WApiEnvelopeParser
    │   └── api_exception.dart      # WApiException / WApiErrorKind
    ├── clients/
    │   └── dio_registry.dart       # DioRegistry Dio 实例注册表
    ├── interceptors/
    │   ├── log.dart                # WLogInterceptor 日志拦截器
    │   ├── retry.dart              # WRetryInterceptor 可选重试
    │   └── token.dart              # WTokenInterceptor 令牌拦截器
    └── repositories/
        └── base_repository.dart    # BaseRepository 数据仓库基类
```


---

## 1. DioRegistry - Dio 实例注册表

### 功能说明

按 `baseUrl` 缓存并复用 `Dio` 实例，避免重复创建。配置直接使用 Dio 的 `BaseOptions`，不再引入额外的配置类型。

传入的 `BaseOptions` 会被**复制**并注入 `baseUrl`，因此：

- 传入实例不会被修改；
- 多个 `Dio` 实例之间不会共享同一份可变配置。

### 核心方法

| 成员 | 说明 |
|------|------|
| `DioRegistry.forBaseUrl(baseUrl, {options, interceptors})` | 获取或创建指定 `baseUrl` 的实例 |
| `dio` | 获取内部 `Dio` 实例 |
| `DioRegistry.maybeForBaseUrl(baseUrl)` | 读取已注册的 `Dio`，不创建新实例 |
| `DioRegistry.dispose(baseUrl)` | 关闭并移除指定 `baseUrl` 的实例 |
| `DioRegistry.clearCache()` | 关闭并清空所有缓存实例 |

> 注意：同一 `baseUrl` 命中缓存后返回已有实例；如果这次显式传入了**不同**的 `options` / `interceptors`，会抛 `ArgumentError`（不再静默忽略）。需要更换配置请先 `DioRegistry.dispose(baseUrl)`。

### 使用示例

```dart
// 基础用法（options 缺省时使用 WApiConfig.baseOptions）
final registry = DioRegistry.forBaseUrl('https://api.example.com');
final response = await registry.dio.get('/users');

// 自定义 Dio 配置
final custom = DioRegistry.forBaseUrl(
  'https://api.example.com',
  options: BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    responseType: ResponseType.plain,
  ),
);

// 追加拦截器（按传入顺序挂载）
final withInterceptors = DioRegistry.forBaseUrl(
  'https://api.example.com',
  interceptors: [
    WLogInterceptor(enableLog: kDebugMode),
    WTokenInterceptor(tokenGetter: () => token),
  ],
);

// 释放资源
DioRegistry.dispose('https://api.example.com');
```

---

## 2. WLogInterceptor - 日志拦截器

默认会脱敏 `Authorization` / `Cookie` / `Set-Cookie` / `Proxy-Authorization` / `X-Api-Key` /
`X-Auth-Token` 等敏感头；可通过 `redactedHeaders` 覆盖（大小写不敏感）。

### 功能说明

按 `parts`（`WLogPart`）打印请求与响应详情，输出经 `WApiConfig.logDebugHandler` / `WApiConfig.logErrorHandler`。`parts` 为 `null` 时使用包内默认值（默认不打印 request / response body）；传空集合表示全部关闭。

### 配置参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `parts` | `Set<WLogPart>?` | 要输出的片段：`request` / `requestHeader` / `requestBody` / `responseHeader` / `responseBody` / `error` / `errorHint` |
| `enableLog` | bool | 是否启用日志（默认 true） |
| `redactedHeaders` | `Set<String>?` | 脱敏头列表；默认已内置常见敏感头 |
| `sensitiveQueryKeys` | `Set<String>?` | 需要脱敏的 query 参数；默认 `token` / `access_token` 等 |
| `sensitiveBodyKeys` | `Set<String>?` | 需要脱敏的 body key；默认覆盖 `password` / `token` / `access_token` 等 |
| `maxBodyLength` | int | 单条 body 最大字符数（默认 2000，`<= 0` 不截断） |

> 显式传 `parts` 时，未列出的片段不会输出（`error` 是详细错误，`errorHint` 是友好提示，二者独立）；需要 body 时显式加 `requestBody` / `responseBody`，并用 `kDebugMode` 控制。URI 中 `token` / `access_token` 等敏感 query 参数默认脱敏；`requestBody` / `responseBody` 的 Map / List / JSON 字符串 / FormData fields 会按 `sensitiveBodyKeys` 递归脱敏；单条 body 超过 2000 字符会截断。

### 使用示例

```dart
final logInterceptor = WLogInterceptor(
  parts: {
    WLogPart.request,
    WLogPart.requestHeader,
    if (kDebugMode) WLogPart.requestBody,
    if (kDebugMode) WLogPart.responseBody,
    WLogPart.error,
    WLogPart.errorHint,
  },
  enableLog: true,
);
```

---

## 3. WTokenInterceptor - 令牌拦截器

### 功能说明

自动为请求添加 `Authorization: Bearer <token>`，并在收到未授权错误时清除 Token、请求新 Token 并重试。

存储通过依赖注入解耦：`tokenGetter` / `tokenClearer` 由调用方提供。

### 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `tokenGetter` | `String? Function()?` | null | 读取当前 token |
| `tokenClearer` | `Future<void> Function()?` | null | 清除 token |
| `tokenRefresher` | `Future<String?> Function()?` | null | 刷新 token，返回新 token（返回 null 表示失败） |
| `configureRequest` | `void Function(RequestOptions)?` | null | 配置请求（**可修改**） |
| `configureResponse` | `void Function(Response)?` | null | 配置响应（**可修改**） |
| `observeError` | `void Function(DioException)?` | null | 错误观测（**仅观测**，与 401 刷新独立，可同时使用） |
| `onAuthFailure` | `void Function(DioException)?` | null | 刷新失败 / 无刷新器 / 达到重试上限时回调 |
| `unauthorizedStatusCode` | int | 401 | 未授权状态码 |
| `maxAuthRetries` | int | 1 | 认证重试上限 |

### 行为说明

- 仅对 `Map` / `String` body 补 `application/json`；`Uint8List` / `Stream` / `FormData` 等保持 dio 的推断，不强制 json。
- `observeError` 与 401 刷新**相互独立、可同时使用**：错误观测回调先无条件执行，之后再独立判断 401 走刷新流程。
- 同一个 `WTokenInterceptor` 只能绑定一个 Dio；多个 registry 请各建实例，共享实例会在第二次绑定时报 `ArgumentError`。
- 刷新失败 / 未配置 `tokenRefresher` / 达到 `maxAuthRetries` 时调用 `onAuthFailure`，适合跳登录或清会话。
- **并发 401 共享同一次刷新（single-flight）**，不会重复调用 `tokenRefresher`。
- `tokenRefresher` 抛出的异常会被捕获并记录日志，请求以原错误结束，不会逃逸出拦截器链。
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

---

## 4. WApiConfig - 全局配置

| 字段 | 说明 |
|------|------|
| `baseOptions` | 全局默认 `BaseOptions`（可覆盖；`DioRegistry` 使用时复制，不修改原实例） |
| `logDebugHandler` | Debug 日志回调，需显式注入 |
| `logErrorHandler` | Error 日志回调，需显式注入 |
| `reset()` | 恢复默认 `baseOptions` 并清空日志回调，主要供测试 / 示例清理 |

```dart
WApiConfig.baseOptions = BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
);
WApiConfig.logDebugHandler = (m) => debugPrint('$m');
WApiConfig.logErrorHandler = (m) => debugPrint('[E] $m');
```

---

## 5. BaseRepository - 数据仓库基类

### 功能说明

整合本地数据源与网络数据源的基础结构。

- `BaseLocalDataSource` / `BaseRemoteDataSource`：数据源抽象基类。
- `BaseRepository<LocalDataSourceType, RemoteDataSourceType>`：持有 `localDataSource` / `remoteDataSource`。

### 使用示例

```dart
class UserRepository extends BaseRepository<UserLocalDataSource, UserRemoteDataSource> {
  UserRepository({super.localDataSource, super.remoteDataSource});

  Future<User?> getUser(int id) async {
    final local = await localDataSource?.getUser(id);
    if (local != null) return local;

    final remote = await remoteDataSource?.getUser(id);
    if (remote != null) await localDataSource?.saveUser(remote);
    return remote;
  }
}
```

---

## 6. common.dart

供使用方实现的通用契约（**扩展点**，库内部不强依赖，请勿因"无内部引用"而删除）：

| 类型 | 说明 |
|------|------|
| `IApiPath` | 抽象接口，定义 `String get baseUrl` |
| `ApiClientId` | 不可变标识符，持有 `name` |

---

## 7. WApiClient - 调用层

### 功能说明

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
| `get` / `post` / `put` / `patch` / `delete` | 五个 HTTP 方法 |
| `pathParameters` | 替换 `{id}` 模板，并对值做 `Uri.encodeComponent` |
| `query` | 值为 `null` 的键会被丢弃 |
| `body` | 原始值（Map / String / FormData…）或 `WApiBody` |
| `decode` | `T Function(Object? json)`；不传则返回原始 JSON |
| `WApiBody` | `json` / `form` / `multipart` / `bytes` 四种编码 |
| `page` | GET 分页，返回 `WPage<T>`（`items` / `total` / `hasMore`） |
| `upload` | `multipart/form-data` 上传，支持进度与取消 |
| `download` | 下载并返回 `Uint8List` |
| `WApiDecoders` | 常用 decoder：`none` / `listOf` / `jsonMap` / `nullable` |
| `WApiException` | 统一错误分类；`kind` 供 UI 映射文案 |

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
  ),
);
```

- 业务码失败 → `WApiException(kind: WApiErrorKind.business)`，带
  `businessCode` / `payload`；
- 成功时 `decode` 拿到的是 `data`，不是整个信封；
- HTTP 401 仍由 `WTokenInterceptor` 处理；业务码里的「登录失效」需要业务自己处理。

### 分页

```dart
final page = await client.page(
  '/users',
  query: const WPageQuery(page: 1, pageSize: 20),
  itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

`WPage.hasMore`：有 `total` 时按 `page * pageSize < total` 计算，否则按本页是否满页。
默认只接受 JSON 数组；Map 结构用 `readItems` / `readTotal` 显式读取。
页面状态仍交给 `WAsyncPagedController`，`WPage` 只做传输层结果。

### 上传 / 下载

```dart
await client.upload<void>(
  '/avatars',
  files: {'avatar': MultipartFile.fromBytes(bytes)},
  onProgress: (sent, total) {},
  decode: WApiDecoders.none,
);

final image = await client.download(
  '/avatars/me',
  onProgress: (received, total) {},
);
```

Web 上不要用 `MultipartFile.fromFile`，用 `fromBytes`；下载得到 `Uint8List`，
是否写入文件由业务层决定。

### 注意

- Dart / Flutter 没有反射，`get<User>()` 不会自动反序列化；必须显式 `decode`
  （或用 json_serializable / freezed 生成）。
- `decode` 抛出的异常会包装成 `WApiException(kind: WApiErrorKind.decode)`，不会漏成 `TypeError`。
- 用户传入的 `content-type` 优先于 `WApiBody` 的默认值。
- 重试见第 8 节（可选）；HTTP 缓存 / 离线不在当前范围；401 刷新仍由 `WTokenInterceptor` 负责。

---

## 8. WRetryInterceptor - 可选重试

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
| `retryOnConnectionErrors` | true | 连接 / 超时错误 |
| `jitter` | true | 50%–100% 抖动，避免同时重试 |
| `onRetry` | null | 每次重试前回调 |
| `shouldRetry` | null | 自定义是否重试 |

- 不重试 401（交给 `WTokenInterceptor`）、其他 4xx 和已取消的请求；
- `POST` / `PATCH` 永不重试（避免重复提交）；
- 裸 `Dio` 需构造传 `dio:` 或手动 `bindDio`；`DioRegistry` 会自动绑定；
- 缓存 / 离线不在本包范围，使用 `dio_cache_interceptor` 等外部方案。

---

## 完整配置示例

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:w_tools/w_tools.dart';

void setupApi() {
  // 全局 Dio 基础配置（可选）
  WApiConfig.baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  // 日志回调
  WApiConfig.logDebugHandler = (m) => WLogger.d(m);
  WApiConfig.logErrorHandler = (m) => WLogger.e(m);

  // 创建带拦截器的 Dio 实例
  final registry = DioRegistry.forBaseUrl(
    'https://api.example.com',
    interceptors: [
      WLogInterceptor(enableLog: kDebugMode),
      WTokenInterceptor(tokenGetter: () => token),
    ],
  );
}
```

---

## 拦截器执行顺序

拦截器按添加顺序在请求方向正序执行、响应方向倒序执行（Dio 标准行为）：

```
请求方向:  interceptors[0] → interceptors[1] → ... → 网络请求
响应方向:  网络响应 → ... → interceptors[1] → interceptors[0] → 业务代码
```

---

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| 连接超时 / 发送超时 / 接收超时 | 记录「网络连接超时」错误日志 |
| 网络连接失败 | 记录「网络连接失败」错误日志 |
| 401 未授权 | `WTokenInterceptor` 清除 Token，尝试刷新并重试（受 `maxAuthRetries` 限制） |
| 服务器错误（badResponse） | 记录状态码 |
| 请求取消 | 记录「请求已取消」 |

---

## 安全特性

- ✅ Token 日志不输出任何 token 片段（仅记录「已注入」）
- ✅ `DioRegistry` 使用前复制 `BaseOptions`，避免实例间共享可变配置

---

## 生命周期与全局状态（6.0.0 规划）

- `DioRegistry` 是进程级静态缓存，按精确 `baseUrl` 缓存；可用 `DioRegistry.maxCachedInstances` 开启 LRU（`null` 不限制，默认），或用 `DioRegistry.cacheTtl` 设置惰性过期，或 `dispose(baseUrl)` / `clearCache()` 手动清理。6.0.0 再评估是否提供实例化 registry。
- `WApiConfig` 是全局可变静态配置；`baseOptions` 在 registry 创建时复制，之后修改只影响新实例。测试 / 示例可用 `WApiConfig.reset()` 清理。5.x 不做 breaking；6.0.0 再评估不可变 / 实例化配置。
- `BaseRepository` / `BaseLocalDataSource` / `BaseRemoteDataSource` 只提供数据源容器；5.3 起确认保持该定位，不升级为 CRUD 基类；6.0.0 不改这一点。

---

## 相关文档

- [w_tools_core — WToken / WStorage](core_module.md)：Token 的持久化存储（`WToken` + `WStorage`）在 core 子包，`WTokenInterceptor` 通过 `tokenGetter` / `tokenClearer` 回调与它们解耦。
- [w_tools_core — WLogger](core_module.md)：`WApiConfig.logDebugHandler` / `logErrorHandler` 通常对接 `WLogger.d` / `WLogger.e`。
- [w_tools_async — WAsync](async_module.md)：网络请求的加载状态管理可配合 `WAsync` / `WAsyncController` 与 `WAsyncOptions.loading`。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
