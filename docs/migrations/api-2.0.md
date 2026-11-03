# api 2.0 迁移：日志片段 / 注册表配置冲突

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WLogInterceptor(request: true, requestBody: true, ...)` | `WLogInterceptor(parts: {...})` | 旧 bool 参数保留到 5.0；`parts` 非空时未列出的片段不输出 |
| `DioRegistry.forBaseUrl(url, options: ...)` 命中缓存时静默忽略 | 命中但配置不同 → `ArgumentError` | 需要换配置先 `DioRegistry.dispose(url)` |
| 同上，`interceptors` | 命中但拦截器不同 → `ArgumentError` | 同上 |

`WLogPart`：`request` / `requestHeader` / `requestBody` / `responseHeader` / `responseBody` /
`error` / `errorHint`。
