# API 模块文档

## 概述

API 模块（`w_tools_api` 子包）提供了一套基于 Dio 封装的网络请求方案，包含 Dio 实例管理（配置直接使用 Dio 的 `BaseOptions`）、拦截器体系和数据仓库基类。

该子包**零内部依赖**：不依赖其他 w_tools 子包；日志通过 `WApiConfig` 注入回调，Token 通过 `tokenGetter` / `tokenClearer` 注入，由调用方决定存储实现。

Cookie 管理未内置，需要时请使用社区包 [`dio_cookie_manager`](https://pub.dev/packages/dio_cookie_manager)。

## 模块结构

```
api/
├── api.dart                        # 统一导出文件
├── api_config.dart                 # WApiConfig 全局配置
├── common.dart                     # IApiPath / ApiClientId
├── clients/
│   └── dio_registry.dart           # DioRegistry Dio 实例注册表
├── interceptors/
│   ├── log.dart                    # WLogInterceptor 日志拦截器
│   └── token.dart                  # WTokenInterceptor 令牌拦截器
└── repositories/
    └── base_repository.dart        # BaseRepository 数据仓库基类
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
| `DioRegistry.dispose(baseUrl)` | 关闭并移除指定 `baseUrl` 的实例 |
| `DioRegistry.clearCache()` | 关闭并清空所有缓存实例 |

> 注意：同一 `baseUrl` 命中缓存后会**直接返回已有实例**，此时传入的 `options` / `interceptors` 会被忽略；如需更换配置，请先 `DioRegistry.dispose(baseUrl)`。

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

### 功能说明

按开关打印请求与响应详情，输出经 `WApiConfig.logDebugHandler` / `WApiConfig.logErrorHandler`。

### 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `request` | bool | true | 打印请求信息 |
| `requestHeader` | bool | true | 打印请求头 |
| `requestBody` | bool | true | 打印请求体 |
| `responseHeader` | bool | false | 打印响应头 |
| `responseBody` | bool | true | 打印响应体 |
| `error` | bool | true | 打印错误信息 |
| `enableLog` | bool | true | 是否启用日志 |

### 使用示例

```dart
final logInterceptor = WLogInterceptor(
  responseBody: true,
  enableLog: kDebugMode,
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
| `unauthorizedStatusCode` | int | 401 | 未授权状态码 |
| `maxAuthRetries` | int | 1 | 认证重试上限 |

### 行为说明

- 请求时仅当 `contentType` 为空才补 `application/json`，不覆盖 `multipart/form-data` 等自定义类型。
- `observeError` 与 401 刷新**相互独立、可同时使用**：错误观测回调先无条件执行，之后再独立判断 401 走刷新流程。
- **并发 401 共享同一次刷新（single-flight）**，不会重复调用 `tokenRefresher`。
- `tokenRefresher` 抛出的异常会被捕获并记录日志，请求以原错误结束，不会逃逸出拦截器链。
- 刷新契约：`tokenRefresher` 取得新 token 后应自行持久化，使 `tokenGetter` 随后返回新 token；若提供 `tokenClearer`，须保证清除后 `tokenGetter` 不再返回旧 token（返回 null 亦可，此时重试会使用拦截器显式写入的新 token）。
- 重试会**重新经过整条请求拦截器链**（请保证 `onRequest` 逻辑幂等）；`FormData` 请求体会在重放前被 `clone()`，`Stream` 请求体无法重放，此时放弃重试并记录日志。
- 重试依赖**经 `DioRegistry.forBaseUrl` 创建的 Dio**；若自行 `Dio()` 创建实例，重试会走 `DioRegistry` 中的另一实例，可能导致配置不一致。

### 使用示例

```dart
final tokenInterceptor = WTokenInterceptor(
  tokenGetter: () => WToken.getToken(),
  tokenClearer: () async => WToken.clearAllTokens(),
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

- ✅ Token 日志脱敏（仅显示前 10 位）
- ✅ `DioRegistry` 使用前复制 `BaseOptions`，避免实例间共享可变配置

---

## 相关文档

- [w_tools_core — WToken / WStorage](core_module.md)：Token 的持久化存储（`WToken` + `WStorage`）在 core 子包，`WTokenInterceptor` 通过 `tokenGetter` / `tokenClearer` 回调与它们解耦。
- [w_tools_core — WLogger](core_module.md)：`WApiConfig.logDebugHandler` / `logErrorHandler` 通常对接 `WLogger.d` / `WLogger.e`。
- [w_tools_core — WAsync](core_module.md)：网络请求的加载状态管理可配合 `WAsync` 的 `showLoading` / `onLoadingStart` / `onLoadingEnd`。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
