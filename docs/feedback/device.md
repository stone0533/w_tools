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
| 2026-11-24 | iOS 模拟器 tap/verify 坐标偏移 DeviceHub 窗口原点，点击落到空白处仍报成功 | ✅ 0.4.0：`deviceRect` 加回窗口原点（屏幕坐标）；新增 `screen` 落在 `deviceRect` 内的断言 |
| 2026-11-24 | `size` 的 `scaleSource` 永远是 fallback（deviceType 标识符被当目录名） | ✅ 0.4.0：走 `simctl list devicetypes` 的 `bundlePath` 读真实密度；iPad mini 744×1133 / 2x |
| 2026-11-24 | `--region` 改成截图像素后旧 smoke 假失败、README 自相矛盾 | ✅ 0.4.0：`--region` 与 tap 同坐标系（iOS point / Android px）；新增 `regionPixels` 便于核对 |
| 2026-11-24 | `list --real --json` 的 `"null"` / 空 `bootState` / 空括号 | ✅ 0.4.0：缺失字段省略、`state` 回落 `tunnelState`、`shot --real` 错误带 `state=` |
| 2026-11-24 | Device Hub 显示的不是目标设备时静默点错 / 误报遮挡 | ✅ 0.4.0：窗口标题软校验（不一致 exit 3）、`windowTitle`、遮挡提示区分「被遮挡 / 选中设备已关机」 |
| 2026-11-24 | 宿主左键被留在按下状态时 tap/verify 全部静默失效 | ✅ 0.4.0：`tap` / `drag` 默认 `du:.`；`--no-release-mouse`；`verify` 探针输出 `mouseButtonDown` / `releasedMouse` / `hint`，5s 超时 |
