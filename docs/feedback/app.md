# w_tools_app 反馈

## 待处理

### [待处理] app: app 4.1：文档示例 onFirstFrame 里 remove 原生闪屏，post-frame 阶段 allowFirstFrame 不会再排帧，静态首屏会停在闪屏

- 包/版本：w_tools_app 4.1.0 / w_tools_app_getx 3.2.0（本地检出 + pub 4.1.0）
- 环境：Flutter 3.44.9 / iOS 模拟器；项目 ureward_member_app（flutter_native_splash 2.4.8 `preserve` 路径）
- 命令 / 输入：
  ```dart
  class SplashPlugin extends WAppPlugin {
    @override Future<void> onInit() async =>
        FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
    @override Future<void> onFirstFrame() async => FlutterNativeSplash.remove();
  }
  ```
  （文档示例：`docs/agents/app.md:70`、`packages/app_getx/README.md:94` 都是这一句）
- 期望：首帧后移除原生闪屏，稳定显示 App。
- 实际：首屏**没有动画 / 定时器在排帧**时会停在原生闪屏。
- 原因（读源码确认的调用链，不是猜测）：
  1. `WApp._doInit` 在 `addPostFrameCallback` 里调 `_pluginRunner.firstFrame()`（app_getx `lib/src/app.dart:149-157`）→ 回调跑在 `SchedulerPhase.postFrameCallbacks`；
  2. `onFirstFrame` 里 `FlutterNativeSplash.remove()` 只做 `allowFirstFrame()`；
  3. `RendererBinding.allowFirstFrame()` 里 `if (!_firstFrameSent) scheduleWarmUpFrame()`，而 `scheduleWarmUpFrame()` 第一行就是 `if (_warmUpFrame || schedulerPhase != SchedulerPhase.idle) return;` → 在 post-frame 阶段直接跳过；
  4. 本次 `drawFrame` 里因为 `sendFramesToEngine == false`，`compositeFrame()` 已经跳过；库之后也不再排帧 → 没有下一帧，帧永远送不到引擎。
- 影响 / 绕路：本项目现在在 `SplashPlugin.onFirstFrame` 里 `remove()` 之后补了一句
  `WidgetsBinding.instance.scheduleFrame()` 才不依赖「首屏恰好有动画」。
  实测带骨架动画的首页能显示（动画在排帧），但这是巧合，不是契约；静态首屏（登录页全缓存、纯静态页）有机会复现。
- 建议：`WApp` 的 post-frame 回调里 `unawaited(_pluginRunner.firstFrame())` 之后补一次
  `SchedulerBinding.instance.scheduleFrame()`（放在 `WAppPluginRunner.firstFrame()` 末尾也行，纯 app 壳也能受益）；
  或至少在 `onFirstFrame` 文档里写明「调用 `allowFirstFrame()` 的插件需自行再排一帧」。
- 备注：`flutter_native_splash.removeAfter` 也是 post-frame 里 `allowFirstFrame()`，同一个坑；区别是它是第三方包。
- 复现数据：代码路径证据（Flutter 3.44.9 源码）：`onFirstFrame` 跑在 `SchedulerPhase.postFrameCallbacks`（非 idle，`scheduleWarmUpFrame` 第一行直接 return）→ `allowFirstFrame()` 不排帧；同一帧的 `drawFrame` 因 `sendFramesToEngine == false` 跳过 `compositeFrame()`；`WApp` / runner 之后没有 `scheduleFrame()`。本项目 `SplashPlugin.onFirstFrame` 补 `WidgetsBinding.instance.scheduleFrame()` 后，iOS 模拟器上闪屏正常放行（`[WApp] first frame 2598ms`）。**未做**「静态首屏」设备复现（首页骨架动画一直在排帧），上述结论来自 SDK 源码与调用链，不是设备实测。
- 状态变更：2026-11-25 待处理

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-25 | `WAppPlugin` 没有首帧钩子，文档却写了 `onLazyInit`；插件无 timeout / critical | ✅ 4.1.0：新增 `onFirstFrame` / `timeout` / `critical`，失败抛 `WAppPluginInitException`；生命周期文档拆 App 级 / 插件级 |
