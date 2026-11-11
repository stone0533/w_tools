# w_tools_api

[![pub package](https://img.shields.io/pub/v/w_tools_api.svg)](https://pub.dev/packages/w_tools_api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_api` 是 w_tools 的网络层，基于 Dio 提供多客户端注册、日志与 Token 拦截器、401 刷新与错误提示，以及 Repository 基类。

## 特性

- **多客户端管理**：`DioRegistry` 按 `baseUrl` 缓存并复用 Dio 实例
- **拦截器**：`WLogInterceptor` 日志（默认脱敏 Authorization / Cookie 等敏感头与 password / token 等敏感 body）、`WTokenInterceptor` Token 注入与 401 刷新
- **配置收敛**：`WApiConfig` 提供默认 `BaseOptions`
- **Repository 基类**：`BaseRepository` 统一持有本地 / 远程数据源
- **路径契约**：`IApiPath` 供业务实现基础 URL

`IApiPath` / `ApiClientId` 是业务侧扩展契约，库内部不强制使用；`DioRegistry` 仍按 `baseUrl` 缓存实例。

## 安装

```yaml
dependencies:
  w_tools_api: ^5.2.0
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
> `Interceptor` 等）；`FormData` / `MultipartFile` / `HttpClientAdapter` 等上传或 adapter 类型
> 仍需直接依赖 `dio`。

## 主要 API

| 能力 | 入口 |
|---|---|
| Dio 注册表 | `DioRegistry.forBaseUrl` / `maybeForBaseUrl` / `dispose` / `clearCache` |
| 默认配置 | `WApiConfig.baseOptions` / `WApiConfig.reset`（测试清理） |
| 日志拦截 | `WLogInterceptor` |
| Token 拦截 | `WTokenInterceptor` |
| Repository | `BaseRepository` |
| 路径契约 | `IApiPath` / `ApiClientId` |

## 完整示例

见 [`example/`](example/)：DioRegistry、日志脱敏、401 刷新与重试（使用内存 MockAdapter，不需要网络）。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。

## License

MIT
