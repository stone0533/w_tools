# w_tools_api 反馈

## 待处理

（暂无）

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | `WApiConfig.baseOptions` / `DioRegistry.dio` 公开了 dio 类型，但 barrel 未重导出，消费方必须额外依赖 dio 才能配置 | ✅ 2.0.0（a71e023）：重导出 `BaseOptions` / `Dio` / `Response` / `Options` / `Interceptor` 等 |
| 2026-11-23 | WTokenInterceptor 把空/空白 refresh token 当成功，额外发一次必然 401 的请求 | ✅ 6.4.0：空串/纯空白按刷新失败（清 token + `onAuthFailure`，不重试）；token trim，`tokenGetter` 空白不注入 |
| 2026-11-23 | WApiClient 公开方法没有 Options/extra/validateStatus，README 的单条关闭重试只能绕过 client | ✅ 6.4.0：`send/get/post/.../upload/downloadResponse` 新增 `options:`；`extra` / `validateStatus` / `responseType` 可用，优先级有测试 |
| 2026-11-23 | README/类注释说默认重试 5xx，实际只重试 500/502/503/504 | ✅ 6.4.0：文档统一为 408 / 429 / 500 / 502 / 503 / 504，其他 5xx 用 `retryOnStatusCodes` 显式放行；补 501/507 测试 |
| 2026-11-23 | DioRegistry 对 validateStatus 按引用比较，语义相同的闭包被判为不同配置 | ✅ 6.4.0：dartdoc / README / modules / catalog 写明函数实例引用比较与 `replace: true`；错误信息带出规则 |
| 2026-11-23 | WApiBody.bytes 省略 contentType 时请求没有 Content-Type | ✅ 6.4.0：`WApiClient` 对 `Uint8List` body 兜底 `application/octet-stream`（`WApiBody.bytes` 签名不变） |
| 2026-11-23 | 拦截器接线/顺序未讲清：retry 未绑定 Dio 静默不重试、log 在 token 前看不到 Authorization | ✅ 6.4.0：README / modules 补「拦截器顺序与绑定」（请求/响应/错误 FIFO、裸 Dio 传 `dio:`），token 示例改为 token → log |
| 2026-11-25 | `DioRegistry` 以 baseUrl 为单 key：同一 baseUrl 无法承载第二套 options/拦截器 | ✅ 6.5.0：`key` 按 `(baseUrl, key)` 分桶；`dispose` / `replace` 作用域写清 |
