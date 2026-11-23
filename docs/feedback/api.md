# w_tools_api 反馈

## 待处理






### [待处理] api: WTokenInterceptor 把空/空白 refresh token 当成功，额外发一次必然 401 的请求

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test + mock HttpClientAdapter
- 命令 / 输入：下面的 WTokenInterceptor 片段（刷新返回空串）。

```dart
final adapter = FakeAdapter((options) {
  final auth = options.headers['Authorization'];
  if (auth == 'Bearer fresh') return jsonBody(200, {'ok': true});
  return jsonBody(401, {'error': 'expired'});
});
final dio = Dio(BaseOptions(baseUrl: 'https://empty-token.example.com'))
  ..httpClientAdapter = adapter;
dio.interceptors.add(WTokenInterceptor(
  dio: dio,
  tokenGetter: () => 'expired',
  tokenClearer: () async {},
  tokenRefresher: () async => '',        // 刷新方拿不到 token
  onAuthFailure: (_) => authFailures++,
));

await expectLater(WApiClient(dio).get<dynamic>('/secure'), throwsA(isA<WApiException>()));
// 期望 adapter.calls == 1；实际 2（第二次带 "Bearer "）
```

- 期望：刷新返回 `null` / 空串 / 纯空白都视为刷新失败：清 token、调用 `onAuthFailure`，不再重试。
- 实际：`WTokenInterceptor` 只判断 `newToken == null`（`packages/api/lib/src/interceptors/token.dart:273`）；空串会被当成有效 token，`_retryRequestWithNewToken` 写入 `Authorization: Bearer ` 再发一次必然 401 的请求，第二次 401 才走 `onAuthFailure`。另外 `tokenGetter` 返回纯空白时 `_addTokenToRequest` 也会注入 `Bearer   `。
- 影响（我因此做错了什么 / 多花了什么）：刷新接口返回空 token 是常见失败形态（字段缺失 / 后端异常）；这里会把一次失败拖成「多一次请求 + 延迟登出」，与本项目 `AppRepository.persistRefreshedToken` 注释里明确写的风险一致。当前只能靠消费方自己 guard 空串，库层契约没有兜住。
- 建议：把 `newToken == null || newToken.trim().isEmpty` 都按刷新失败处理，并对 token 做 trim；`tokenGetter` 的空白串也按无 token 处理。补一条「空串刷新」和「空白 tokenGetter」的回归测试。
- 复现数据：本地探针 `suspected_test.dart` 的「tokenRefresher 返回空串时不应把它当成刷新成功去重试」；实际 `adapter.calls=2`、`refreshes=1`、`authFailures=1`，期望 `calls=1`。
- 验证（2026-11-23 复测，6.4.0）：已修复；空/空白刷新只发 1 次请求，`tokenGetter` 空白不注入 Authorization。
- 状态变更：2026-11-23 待处理

### [待处理] api: WApiClient 公开方法没有 Options/extra/validateStatus，README 的单条关闭重试只能绕过 client

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：`WApiClient` 的公开方法签名（`packages/api/lib/src/client/api_client.dart:53-211`）：

```dart
Future<T> get<T>(String path, {
  Map<String, Object?>? query,
  Map<String, String>? pathParameters,
  WApiDecoder<T>? decode,
  CancelToken? cancelToken,
  Map<String, String>? headers,
});
// send 也只多 body / envelope / progress，没有 Options / extra / validateStatus
```

- 期望：`WApiClient` 能按请求传 `Options`（或至少 `extra` / `validateStatus` / `responseType`），这样 README 写的「单条请求关闭重试」和「接受 304 / 409」能在主调用层直接用。
- 实际：当前只能传 `headers`；README 第 226 行写：
  `Options(extra: {WRetryInterceptor.disableRetryExtraKey: true})`，
  但 `WApiClient` 方法没有 `options` / `extra` 参数，只能绕过 `WApiClient` 用 `client.dio.get(...)`，同时失去统一 decode / `WApiException` 映射。`validateStatus`、`responseType` 也只能在 `downloadResponse` 内部固定。
- 影响（我因此做错了什么 / 多花了什么）：按 README 使用 `WApiClient + WRetryInterceptor` 的消费方，无法对单条 GET 关闭重试；遇到以 409 / 304 表示业务结果的接口也无法在 client 层接受，只能降级到裸 dio 并自己处理错误。本项目 `AppApiClient` 全走 `WApiClient`，将来加 retry 时会直接撞上。
- 建议：给 `send` / `get` / `post` 等加可选 `Options? options`（或拆出 `extra`、`validateStatus`、`responseType`），与内部 `Options(method/headers/contentType)` 合并时注意 content-type 优先级；至少在 README 明确「单条关闭重试只能走裸 dio」。
- 复现数据：源码签名 `api_client.dart:53-211`；README 单条关闭重试 `README.md:224-226`，高级表 `README.md:326`。
- 验证（2026-11-23 复测，6.4.0）：已修复；`send/get/.../upload/downloadResponse` 均支持 `options:`；`extra` 关重试、`validateStatus` 409、`responseType`、headers/Content-Type 优先级均通过。
- 状态变更：2026-11-23 待处理

### [待处理] api: README/类注释说默认重试 5xx，实际只重试 500/502/503/504

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test + mock HttpClientAdapter
- 命令 / 输入：下面片段（501 → 200）。

```dart
var calls = 0;
final adapter = FakeAdapter((_) {
  calls++;
  return calls == 1
      ? jsonBody(501, {'error': 'not implemented'})
      : jsonBody(200, {'ok': true});
});
final dio = Dio(BaseOptions(baseUrl: 'https://retry501.example.com'))
  ..httpClientAdapter = adapter;
dio.interceptors.add(WRetryInterceptor(
  dio: dio, maxRetries: 1, baseDelay: Duration.zero, jitter: false,
));
await WApiClient(dio).get<dynamic>('/x');
// 期望 calls == 2；实际 1（501 直接失败）
```

- 期望：README / 类注释说「默认只重试网络错误和 408 / 429 / 5xx」，那 501（以及其他 5xx）应重试；或者文档明确写「只重试 500 / 502 / 503 / 504」。
- 实际：`_defaultStatusCodes` 只有 `{408, 429, 500, 502, 503, 504}`（`packages/api/lib/src/interceptors/retry.dart:109`），501 / 505 / 506 / 507 / 508 / 510 / 511 都不重试，与「5xx」的文档口径不一致。
- 影响（我因此做错了什么 / 多花了什么）：按文档给 507（空间不足）/ 511（需要认证）之类可恢复 5xx 配 retry 的消费方，实际不会重试；只能自己覆盖 `retryOnStatusCodes`，但文档没有提示。
- 建议：二选一——文档改成「常用 5xx：500 / 502 / 503 / 504」，或实现改成 `status >= 500`（若 501/505 不属于可重试，就在文档里点名排除）。补一条 501/507 的测试。
- 复现数据：本地探针 `findings_test.dart` 的「README 说默认重试 5xx：501 是否重试」；实际 calls=1，期望 2。
- 验证（2026-11-23 复测，6.4.0）：已修复（文档口径）；README/类注释列明 500/502/503/504，501/507 默认不重试。
- 状态变更：2026-11-23 待处理

### [待处理] api: DioRegistry 对 validateStatus 按引用比较，语义相同的闭包被判为不同配置

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / unit test
- 命令 / 输入：下面片段（两次 forBaseUrl，语义相同的自定义 validateStatus）。

```dart
final first = DioRegistry.forBaseUrl(
  'https://validate.example.com',
  options: BaseOptions(validateStatus: (_) => true),
);
DioRegistry.forBaseUrl(
  'https://validate.example.com',
  options: BaseOptions(validateStatus: (_) => true),
);
// 期望：语义相同，命中缓存；实际：ArgumentError
// DioRegistry 已存在同一 baseUrl 的不同 BaseOptions
```

- 期望：相同语义的配置命中缓存；或文档/错误信息明确说明 `validateStatus`（以及 `requestEncoder` / `responseDecoder`）按**函数实例引用**比较，必须复用同一个函数实例，否则要 `replace`。
- 实际：`_sameOptions` 用 `identical(a.validateStatus, b.validateStatus)`（`packages/api/lib/src/dio_registry.dart:216`），两个新闭包即使行为相同也判冲突，抛 `ArgumentError`。`_sameOptions` 的代码注释提了「按引用比较」，但公开的 `forBaseUrl` 文档和 README 没写。
- 影响（我因此做错了什么 / 多花了什么）：自定义 `validateStatus` 接受 409 / 304 是很常见的 dio 配置；在测试 / 多模块工厂里两次构造等价 options 就会炸，只能先 dispose/`replace`，而错误信息只说「不同 BaseOptions」，排查成本高。本项目目前只用默认 validateStatus，所以没踩到。
- 建议：在 `forBaseUrl` / README 里写明函数类字段的引用比较规则（并说明复用同一实例或 `replace: true`）；错误信息把「函数字段按引用比较」带出来；如果可行，对自定义函数字段跳过内容比较但要求显式 `replace`，避免假冲突。
- 复现数据：本地探针 `findings2_test.dart` 的「DioRegistry 相同语义但不同实例的 validateStatus 是否算冲突」；实际抛 `ArgumentError`。
- 验证（2026-11-23 复测，6.4.0）：已修复（文档/错误信息）；仍按函数实例比较，错误信息说明规则和 `replace: true`。
- 状态变更：2026-11-23 待处理

### [待处理] api: WApiBody.bytes 省略 contentType 时请求没有 Content-Type

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test + mock HttpClientAdapter
- 命令 / 输入：下面的 put 请求（省略 contentType）。

```dart
await WApiClient(dio).put<void>(
  '/blob',
  body: WApiBody.bytes([1, 2, 3]),   // 省略 contentType
  decode: WApiDecoders.none,
);
// adapter 收到的 requestOptions：
// contentType = null
// headers = {content-length: 3}   // 没有 content-type
```

- 期望：`WApiBody.bytes` 省略 `contentType` 时有可用的默认值（通常 `application/octet-stream`），或者把 `contentType` 改成必填并在 dartdoc / README 写清「不传就没有 Content-Type」。
- 实际：`WApiBody.bytes` 的 `contentType` 是可选 nullable，省略时 `WApiClient` 传 `Options(contentType: null)`，请求没有任何 Content-Type。`WApiBody.json` / `form` 都有默认类型，只有 bytes 没有。
- 影响（我因此做错了什么 / 多花了什么）：二进制上传（protobuf / 图片 / 文件）省略 contentType 时，服务端常按 `application/octet-stream` 或明确类型校验；没有头会被 415 / 静默拒绝。README 的示例总是显式传，容易以为构造器会自动兜底。
- 建议：`WApiBody.bytes` 默认 `contentType = 'application/octet-stream'`，或在 dartdoc 明确「必须显式传 contentType」并给出示例；补一条「省略 contentType 的请求头」测试。
- 复现数据：本地探针 `findings_test.dart` 的「WApiBody.bytes 省略 contentType 时应有可用的默认值」；adapter 的 `contentType=null`、headers 只有 `content-length`。
- 验证（2026-11-23 复测，6.4.0）：已修复；`WApiBody.bytes` / 裸 `Uint8List` 在 WApiClient 下兜底 `application/octet-stream`。
- 状态变更：2026-11-23 待处理

### [待处理] api: 拦截器接线/顺序未讲清：retry 未绑定 Dio 静默不重试、log 在 token 前看不到 Authorization

- 包/版本：w_tools_api 6.3.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test + mock HttpClientAdapter
- 命令 / 输入：两个接线/顺序场景。

```dart
// A. 裸 Dio + retry，未传 dio:
final dio = Dio(BaseOptions(baseUrl: 'https://unbound.example.com'))
  ..httpClientAdapter = adapter;                 // 500
dio.interceptors.add(WRetryInterceptor(
  maxRetries: 2, baseDelay: Duration.zero, jitter: false,
));                                              // 没有 dio: / registry
await WApiClient(dio).get<dynamic>('/x');
// 实际 calls == 1，不重试；只有 WApiSettings.logErrorHandler 非空时才会看到
// 「WRetryInterceptor 未绑定 Dio」

// B. 按 README「带 Token 时」示例顺序：log 在 token 前
dio.interceptors.add(WLogInterceptor());        // 默认包含 requestHeader
dio.interceptors.add(WTokenInterceptor(dio: dio, tokenGetter: () => 'abc'));
// 日志 headers 里没有 Authorization；把 token 放前面才能看到 Authorization: ***
```

- 期望：README / 构造器文档把「拦截器绑定与顺序」讲清：retry 需要 `DioRegistry.forBaseUrl` 自动绑定或构造传 `dio:`；log 想记录注入后的 Authorization 要放在 token 后面。
- 实际：`WRetryInterceptor` 未绑定 Dio 且没有 registry 时只 `log_support.logError('...未绑定 Dio')` 后放弃重试；默认 `WApiSettings.logErrorHandler == null`，用户完全无感。README 的 token 示例把 `WLogInterceptor` 放在 `WTokenInterceptor` 前面（`README.md:268-278`），如果打开 `requestHeader`（或使用默认 parts），看不到 token 注入后的 Authorization。
- 影响（我因此做错了什么 / 多花了什么）：裸 Dio 用户以为加了 retry 就生效；排查 401 时按示例顺序打开 header 日志，却看不到 Authorization，误以为 token 没注入。本项目 `app_repository.dart` 自己用了 token→log 的正确顺序，但 README 的示例没有把这个经验固化。
- 建议：在 README 加一小节「拦截器顺序与绑定」：`DioRegistry` 会自动 bind；裸 Dio 必须 `dio: dio`；请求日志放 token 之后；并把 token 示例的顺序改成 `WTokenInterceptor` → `WLogInterceptor`。`WRetryInterceptor` 构造器的 `dio` 参数补 dartdoc。
- 复现数据：本地探针 `findings2_test.dart` 的「未绑定 Dio 的 WRetryInterceptor 是否静默不重试」、`findings_test.dart` 的「README 的 token 示例顺序」；后者日志只有 `*** Request ***` + 空 headers。
- 验证（2026-11-23 复测，6.4.0）：已修复（文档）；README 补「拦截器顺序与绑定」，token→log 可记录脱敏后的 Authorization。
- 状态变更：2026-11-23 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | `WApiConfig.baseOptions` / `DioRegistry.dio` 公开了 dio 类型，但 barrel 未重导出，消费方必须额外依赖 dio 才能配置 | ✅ 2.0.0（a71e023）：重导出 `BaseOptions` / `Dio` / `Response` / `Options` / `Interceptor` 等 |
