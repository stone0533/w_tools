# w_tools_device 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | 设备预览被其它窗口遮挡时，标定算出错误坐标（不报错） | ✅ 0.1.0：先 `activate` DeviceHub；识别高度明显偏小直接报「被遮挡」 |
| 2026-11-03 | `shot --real` 锁屏时返回全黑 PNG，退出码 0 | ✅ 0.1.0：`ScreenStats.isMostlyDark` 检测并给 warning |
| 2026-11-03 | 多设备（真机 + 模拟器）时 `verify` 未透传 `--device`，点到另一台 | ✅ 0.1.1：`--device` 全链路透传 |
| 2026-11-03 | Android 首次启动弹通知权限框，`foreground` 校验失败但没有说明 | ✅ 0.1.0：冒烟要求 `--package` 并提示先 `pm grant`（文档已写） |
