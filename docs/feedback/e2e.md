# w_tools_e2e 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | `bool.fromEnvironment('E2E')` 只认 `true`，`--dart-define=E2E=1` 静默失效 | ✅ 0.1.0：按字符串解析，接受 `1` / `true` |
| 2026-11-03 | 登录成功但 `afterLogin`（导航）失败时被判成「登录失败」 | ✅ 0.1.0：登录成功即 true，导航错误单独上报 |
| 2026-11-03 | `Get.offAllNamed` 有时不 resolve，`await` 它导致成功日志永远打不出来 | ✅ 0.1.0：登录成功立即打日志，导航 `unawaited` |
| 2026-11-04 | 首个版本已发布后仍有 `afterLogin` / `onError` 修复，版本未抬导致再次发布失败 | ✅ 0.1.1（94ad2fb）：补版本与 CHANGELOG |
