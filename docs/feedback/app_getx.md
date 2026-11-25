# w_tools_app_getx 反馈

## 待处理

（暂无）

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-25 | `WAppTheme.systemUiOverlayStyle` 只在启动时设置一次，浅色状态栏页面返回后不恢复 | ✅ 3.2.0：根级 `AnnotatedRegion` 兜底；页面标注优先，pop 后恢复 |
| 2026-11-25 | 启动期没有可观测性：插件耗时 / 顺序无日志 | ✅ 3.2.0：`WAppStartupReport` + `startupLog`；逐插件耗时 / 失败 / 首帧日志 |
| 2026-11-25 | 插件 `onInit` 无超时 / 关键性标记，启动失败直接白屏 | ✅ 4.1.0 / 3.2.0：`timeout` / `critical` + `WAppPluginInitException`；`start()` 可重试；README 兜底页配方 |
| 2026-11-25 | 缺测试宿主：49 个测试文件各自手搭 `ScreenUtilInit` + `MaterialApp` | ✅ 3.2.0：`WApp.buildRoot()` 复用运行时装配，测试只写业务 |
