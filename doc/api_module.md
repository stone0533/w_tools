# API 模块文档

## 概述

API 模块提供了一套完整的网络请求解决方案，基于 Dio 封装，包含配置管理、拦截器体系和数据仓库模式。

## 模块结构

```
api/
├── api.dart                    # 统一导出文件
├── common.dart                 # 公共接口和标识符
├── clients/
│   ├── http_config.dart        # HTTP 配置类
│   └── dio_util.dart           # Dio 工具类
├── interceptors/
│   ├── log.dart                # 日志拦截器
│   ├── token.dart              # Token 拦截器
│   ├── cache.dart              # 缓存拦截器
│   └── cookie.dart             # Cookie 拦截器
└── repositories/
    └── base_repository.dart    # 数据仓库基础类
```

---

## 1. HttpConfig - HTTP 配置类

### 功能说明

用于管理 HTTP 请求的配置参数，支持不可变性设计和便捷工厂方法。

### 配置字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `connectTimeout` | Duration | 10秒 | 连接超时时间 |
| `receiveTimeout` | Duration | 50秒 | 接收超时时间 |
| `retry` | bool | false | 是否启用重试 |
| `retryCount` | int | 3 | 重试次数 |
| `enableCertificateValidation` | bool | true | 是否启用证书验证 |
| `securityHeaders` | Map<String,String> | 安全头部 | 安全响应头部配置 |

### 使用示例

```dart
// 创建默认配置
final config = HttpConfig();

// 创建自定义配置
final custom = HttpConfig(
  connectTimeout: const Duration(seconds: 5),
  retry: true,
  retryCount: 3,
);

// 使用便捷工厂方法
final fast = HttpConfig.fastTimeout();       // 快速超时配置
final withRetry = HttpConfig.withRetry();    // 带重试配置
final unsafe = HttpConfig.unsafe();          // 不安全配置（测试用）

// 基于现有配置创建新配置
final modified = custom.copyWith(retryCount: 5);
```

---

## 2. DioUtil - Dio 工具类

### 功能说明

单例模式管理 Dio 实例，支持缓存拦截器和自定义拦截器配置。

### 核心方法

| 方法 | 说明 |
|------|------|
| `instance(baseUrl, options)` | 获取或创建 DioUtil 实例 |
| `dio` | 获取 Dio 实例 |

### 使用示例

```dart
// 基础用法
final dioUtil = DioUtil.instance('https://api.example.com');
final response = await dioUtil.dio.get('/users');

// 启用缓存
final cachedDio = DioUtil.instance(
  'https://api.example.com',
  enableCache: true,
  maxCacheSize: 1024 * 1024 * 20, // 20MB
  maxCacheAge: 60 * 60, // 1小时
);

// 添加自定义拦截器
final customDio = DioUtil.instance(
  'https://api.example.com',
  interceptors: [WLogInterceptor(), WTokenInterceptor()],
);
```

---

## 3. WLogInterceptor - 日志拦截器

### 功能说明

记录 HTTP 请求和响应的详细日志，支持灵活配置日志输出内容。

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
  requestBody: true,
  responseBody: true,
  enableLog: kDebugMode, // 仅在调试模式启用
);
```

---

## 4. WTokenInterceptor - Token 拦截器

### 功能说明

自动处理 Token 的添加、更新和过期重试逻辑。

### 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `onAuthError` | Future<String?> Function() | null | 认证错误回调，返回新 Token |
| `onRequestOptions` | void Function(RequestOptions) | null | 请求选项修改回调 |
| `onResponseOptions` | void Function(Response) | null | 响应处理回调 |
| `onErrorOptions` | void Function(DioException) | null | 错误处理回调 |
| `unauthorizedStatusCode` | int | 401 | 未授权状态码 |
| `maxAuthRetries` | int | 1 | 最大重试次数 |

### 使用示例

```dart
final tokenInterceptor = WTokenInterceptor(
  onAuthError: () async {
    // 获取新 token 的逻辑
    return await refreshToken();
  },
  unauthorizedStatusCode: 401,
);
```

---

## 5. WCacheInterceptor - 缓存拦截器

### 功能说明

支持内存缓存和磁盘缓存，实现 LRU 淘汰策略。

### 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `maxCacheSize` | int | 10MB | 最大缓存大小 |
| `maxCacheAge` | int | 24小时 | 最大缓存时间（秒） |
| `maxMemoryEntries` | int | 100 | 内存缓存最大条目数 |

### 使用示例

```dart
final cacheInterceptor = WCacheInterceptor(
  maxCacheSize: 1024 * 1024 * 20, // 20MB
  maxCacheAge: 60 * 60, // 1小时
  maxMemoryEntries: 200,
);
```

---

## 6. WCookieInterceptor - Cookie 拦截器

### 功能说明

自动管理 HTTP 请求和响应中的 Cookie。

### 使用示例

```dart
final cookieInterceptor = WCookieInterceptor();
```

---

## 7. BaseRepository - 数据仓库基础类

### 功能说明

提供数据仓库的基础结构，整合本地数据源和网络数据源。

### 使用示例

```dart
class UserRepository extends BaseRepository<UserLocalDataSource, UserRemoteDataSource> {
  UserRepository({
    super.localDataSource,
    super.remoteDataSource,
  });

  Future<User?> getUser(int id) async {
    // 先从本地缓存获取
    final local = await localDataSource?.getUser(id);
    if (local != null) return local;

    // 从网络获取
    final remote = await remoteDataSource?.getUser(id);
    await localDataSource?.saveUser(remote!);
    return remote;
  }
}
```

---

## 完整配置示例

```dart
import 'package:w_tools/w_tools.dart';

void setupApi() {
  // 配置全局 HTTP 配置
  WConfig.httpConfig = HttpConfig(
    connectTimeout: const Duration(seconds: 15),
    retry: true,
    retryCount: 3,
  );

  // 创建带所有拦截器的 Dio 实例
  final dioUtil = DioUtil.instance(
    'https://api.example.com',
    enableCache: true,
    interceptors: [
      WLogInterceptor(enableLog: kDebugMode),
      WTokenInterceptor(
        onAuthError: () async => await AuthService.refreshToken(),
      ),
      WCookieInterceptor(),
    ],
  );
}
```

---

## 拦截器执行顺序

```
请求方向:
┌─────────────────────────────────────────────────────────┐
│  WTokenInterceptor → WLogInterceptor → WCookieInterceptor → 网络请求  │
└─────────────────────────────────────────────────────────┘

响应方向:
┌─────────────────────────────────────────────────────────┐
│  网络响应 → WCacheInterceptor → WLogInterceptor → 业务代码    │
└─────────────────────────────────────────────────────────┘
```

---

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| 连接超时 | 记录错误日志，可配置重试 |
| 网络错误 | 记录错误日志，提示用户检查网络 |
| 401 未授权 | 清除 Token，尝试刷新并重试 |
| 服务器错误 | 记录错误日志，返回错误信息 |

---

## 缓存策略

1. **内存缓存**：优先使用，容量限制 100 条，LRU 淘汰
2. **磁盘缓存**：二级缓存，容量限制 10MB，按时间和大小清理
3. **缓存键**：基于 URL + 查询参数生成 MD5 哈希
4. **缓存有效期**：默认 24 小时，可配置

---

## 安全特性

- ✅ HTTPS 证书验证（默认启用）
- ✅ 安全响应头部配置
- ✅ Token 日志脱敏（仅显示前10位）
- ✅ 不可变配置对象
