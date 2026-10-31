# w_tools_api 示例

真实场景示例，使用内存 MockAdapter，不发起网络请求。

覆盖：

- `DioRegistry.forBaseUrl`：按 baseUrl 创建并复用 Dio
- `WLogInterceptor`：请求 / 响应日志与敏感头脱敏
- `WTokenInterceptor`：401 清除、刷新、重试
- `WApiConfig`：日志回调注入
- `FormData` / Stream 等重试边界（见包测试）

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

## 页面

```text
GET /public      返回 200，观察请求 / 响应日志
401 → 刷新 → 重试
                 token 先过期，服务端返回 401；
                 WTokenInterceptor 清除旧 token、刷新、重试成功
清空日志
```

日志中的 `Authorization` 默认显示为：

```text
Authorization: ***
```

不会输出真实 token。

## 说明

示例用 `HttpClientAdapter` 模拟服务端：

```text
/secure 只接受 Bearer fresh-token
其余路径返回 200
```

因此不需要网络，也不会依赖真实接口。
