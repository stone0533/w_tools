# w_tools_qr 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | Web 上 `pauseCamera()` 同步抛 `UnimplementedError`，异常绕过 `catchError`，默认单次扫码 `onScanned` 永不触发 | ✅ 1.1.0（49e07e0）：相机操作改闭包求值，同步/异步异常统一走 `onError` |
