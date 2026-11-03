# core 2.3 迁移：防抖 / 节流 / 倒计时

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WUx().debounce(fn, duration: 300)` | `WDebounce(fn, duration: Duration(milliseconds: 300))` | 新增 `isPending`；3.0 移除 WUx 版本 |
| `WUx().throttle(fn, duration: 300)` | `WThrottle(fn, duration: Duration(milliseconds: 300))` | 新增 `isThrottled`；3.0 移除 WUx 版本 |
| `WCountdown.remainingSeconds` 轮询 | `WCountdown.remaining`（`ValueListenable<int>`） | 每秒通知，可 `addListener`；`remainingSeconds` 保留 |

`WDebounce` / `WThrottle` 的 `cancel()` 语义与旧 `WCancellableAction.cancel()` 一致；
`WCountdown.dispose()` 会释放监听视图，再次 `start` 会自动重建。
