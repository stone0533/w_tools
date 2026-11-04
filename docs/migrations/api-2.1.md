> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# api 2.1 迁移：401 重试不再隐式注册 Dio

| 旧 | 新 |
| --- | --- |
| 裸 `Dio()` + `WTokenInterceptor`，401 后隐式 `DioRegistry.forBaseUrl` 创建零拦截器实例 | 重试只用**已知 Dio**：`DioRegistry` 自动绑定，或构造时传 `dio: dio` |
| 隐式实例污染 registry 缓存，后续正式初始化可能抛 `ArgumentError` | 未绑定且未注册时直接报错并结束重试，不会创建新实例 |

```dart
final dio = Dio(BaseOptions(baseUrl: base));
dio.interceptors.add(
  WTokenInterceptor(
    dio: dio,                     // 裸 Dio 必须显式绑定
    tokenGetter: WToken.getToken,
    tokenRefresher: refreshToken,
  ),
);

// 推荐：经 registry 创建，自动绑定
final registry = DioRegistry.forBaseUrl(base, interceptors: [WTokenInterceptor(...)]);
```
