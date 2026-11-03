# api 5.0 迁移

`WLogInterceptor` 的 6 个旧 bool 参数已删除，只用 `parts`：

| 旧 | 新 |
| --- | --- |
| `request: true` | `parts: {WLogPart.request}` |
| `requestHeader: true` | `parts: {WLogPart.requestHeader}` |
| `requestBody: true` | `parts: {WLogPart.requestBody}` |
| `responseHeader: true` | `parts: {WLogPart.responseHeader}` |
| `responseBody: true` | `parts: {WLogPart.responseBody}` |
| `error: true` | `parts: {WLogPart.error}`（友好提示另加 `errorHint`） |

不传 `parts` 时使用包内默认值；传空集合表示全部关闭。
