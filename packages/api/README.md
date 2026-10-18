# w_tools_api

[![pub package](https://img.shields.io/pub/v/w_tools_api.svg)](https://pub.dev/packages/w_tools_api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_api` 是 w_tools 的网络层，基于 Dio 提供多客户端注册、日志与 Token 拦截器、统一错误处理及 Repository 基类。

## 特性

- **多客户端管理**：`DioRegistry` 按 `baseUrl` 缓存并复用 Dio 实例
- **拦截器**：`WLogInterceptor` 日志、`WTokenInterceptor` Token 注入与 401 刷新
- **配置收敛**：`WApiConfig` 提供默认 `BaseOptions`
- **Repository 基类**：`BaseRepository` 统一请求入口
- **路径契约**：`IApiPath` 供业务实现基础 URL

## 安装

```yaml
dependencies:
  w_tools_api: ^1.0.0
```

```bash
flutter pub get
```

> 本包最低要求 Flutter 3.27.0。

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

释放实例：

```dart
DioRegistry.dispose('https://api.example.com');
```

## 主要 API

| 能力 | 入口 |
|---|---|
| Dio 注册表 | `DioRegistry.forBaseUrl` / `dispose` / `clearCache` |
| 默认配置 | `WApiConfig.baseOptions` |
| 日志拦截 | `WLogInterceptor` |
| Token 拦截 | `WTokenInterceptor` |
| Repository | `BaseRepository` |
| 路径契约 | `IApiPath` / `ApiClientId` |

## License

MIT
