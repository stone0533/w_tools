# w_tools_api 示例

真实场景示例，使用内存 MockAdapter，不发起网络请求。

覆盖：

- `DioRegistry.forBaseUrl`：按 baseUrl 创建并复用 Dio
- `WApiClient`：GET / POST / PUT / PATCH / DELETE、path / query、显式 decoder（`lib/wapi_client_demo.dart`）
- `WApiEnvelopeParser`：可选 `{code, message, data}` 信封
- `WApiClient.page` / `WPage`：分页、`total` 与 `hasMore`
- `WApiClient.upload` / `download`：multipart 上传与字节下载
- `WRetryInterceptor`：可选幂等重试（见包测试）
- `WLogInterceptor`：请求 / 响应日志与敏感头脱敏
- `WTokenInterceptor`：401 清除、刷新、重试；`configureRequest` / `configureResponse` / `observeError`
- `WApiConfig`：baseOptions 与日志回调注入
- `BaseRepository` / 本地 / 远程数据源组合
- `IApiPath` / `ApiClientId` 扩展契约
- 响应头脱敏 与 500 错误日志
- 重试 / 取消 / Stream 等边界（见包测试）

## 运行

```bash
cd packages/api/example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 真实项目分层示例

`lib/real_world/` 是按真实项目拆分的接入示例，不依赖 UI，可直接复制到业务项目：

| 文件 | 作用 |
|---|---|
| `app_api.dart` | `AppApi.init`：装配 `WApiConfig` + `DioRegistry` + `WTokenInterceptor`；登录 / 刷新 / 退出 |
| `token_store.dart` | `TokenStore` 契约；生产实现基于 `w_tools_core` 的 `WToken`，测试用内存实现 |
| `api_exception.dart` | `DioException` → `ApiException` 的业务错误分类 |
| `user_repository.dart` | `BaseRepository` + 本地缓存 / 远程数据源组合 |

`main()` 的接入顺序（示意）：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 默认 WTokenStore 时，AppApi.init 内部会 await WStorage.init()。
  final api = await AppApi.init(baseUrl: 'https://api.example.com');

  runApp(App(api: api));
}
```

只跑这个示例的测试（MockAdapter，无网络）：

```bash
flutter test test/real_world_api_test.dart
```

覆盖：登录写入凭证、首个请求 401 自动刷新并重试、并发 401 只刷新一次、
刷新失败触发 `onAuthFailure` 并映射为 `unauthorized`、Repository 缓存命中。

## 页面

```text
GET /public      返回 200，观察请求 / 响应日志
GET /error（500） 返回 500，观察错误日志
401 → 刷新 → 重试
                 token 先过期，服务端返回 401；
                 WTokenInterceptor 清除旧 token、刷新、重试成功
Repository 缓存
                 通过 BaseRepository 组合本地 / 远程数据源
分页             WApiClient.page + WPageQuery，展示 items / hasMore
上传             WApiClient.upload + WApiDecoders.none
500 重试          WRetryInterceptor 只对 /flaky 生效，首次 500 后成功
清空日志
```

日志中的 `Authorization` 默认显示为：

```text
Authorization: ***
```

不会输出真实 token。

响应头：

```text
set-cookie: ***
```

也不会输出真实 cookie。

## 说明

示例用 `HttpClientAdapter` 模拟服务端：

```text
/secure 只接受 Bearer fresh-token
其余路径返回 200
```

因此不需要网络，也不会依赖真实接口。
