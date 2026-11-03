# w_tools_api 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | `WApiConfig.baseOptions` / `DioRegistry.dio` 公开了 dio 类型，但 barrel 未重导出，消费方必须额外依赖 dio 才能配置 | ✅ 2.0.0（a71e023）：重导出 `BaseOptions` / `Dio` / `Response` / `Options` / `Interceptor` 等 |
