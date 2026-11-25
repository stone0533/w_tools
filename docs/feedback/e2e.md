# w_tools_e2e 反馈

## 待处理

（暂无）

## 已确认


### [已确认] e2e: 启用条件不满足时静默返回：不知道是没传 E2E=1、缺账号，还是 release 构建

- 包/版本：w_tools_e2e 0.2.0（本地检出 `packages/e2e`）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；iPhone 17 模拟器（iOS 26.2）+ Pixel 5；项目 ureward_member_app（`tool/main_e2e.dart` 入口）
- 命令 / 输入：
  ```bash
  # ① 忘了开开关
  flutter run -t tool/main_e2e.dart -d <udid>
  # ② 开了开关但漏了密码
  flutter run -t tool/main_e2e.dart -d <udid> --dart-define=E2E=1 --dart-define=E2E_EMAIL=qa@example.com
  ```
  项目侧接线（`tool/main_e2e.dart`）：
  ```dart
  final e2e = E2eConfig.fromEnvironment();
  if (!e2e.canAutoLogin) return;      // ← 静默 return
  await E2eLogin.run(config: e2e, login: ..., afterLogin: ...);
  ```
- 期望：启用条件不满足时，能区分**是哪一条不满足**（开关没开 / 缺 email / 缺 password / release 构建 / profile 未显式放行），并打一行说明；例如
  `[E2E] skip: flagOff` / `[E2E] skip: missingPassword`。
- 实际：`E2eConfig.canAutoLogin` 只返回 bool（`e2e_config.dart:48`），`E2eLogin.run` 在 `!canAutoLogin` 时直接 `return false`（`e2e_login.dart:35`），**没有任何日志**；项目侧又习惯写 `if (!canAutoLogin) return;`，于是 App 正常启动、停在游客态，日志里一句话都没有。
- 影响（我因此做错了什么 / 多花了什么）：每次设备验证「为什么没自动登录」都要把 `--dart-define` 逐个核对一遍，并且会先怀疑设备/网络/接口（今天实测就是这样：停在登录页，先查了 UAT 网络、账号、`pbeService.deviceId`，最后才发现是 `canAutoLogin == false`）。
- 建议：
  1. `E2eConfig` 增加 `E2eDisabledReason? disabledReason`（`flagOff` / `missingEmail` / `missingPassword` / `releaseBuild` / `profileNotAllowed`），`enabled` / `canAutoLogin` 由它推导；
  2. `E2eLogin.run` 在未启用时也打一行（默认 `debugPrint('[E2E] skip: $reason')`，与现有 `[E2E] auto login ok/failed` 风格一致）；
  3. README 加一节「为什么不自动登录 / 故障排查」，把 5 种原因列出来。
- 复现数据：
  - `packages/e2e/lib/src/e2e_config.dart:22-36`（enabled 判定）、`:48`（`canAutoLogin => enabled && email.isNotEmpty && password.isNotEmpty`）；
  - `packages/e2e/lib/src/e2e_login.dart:35`（`if (!cfg.canAutoLogin) return false;`，无日志）；
  - 本项目 `tool/main_e2e.dart`：`if (!e2e.canAutoLogin) return;`（同样静默）；
  - 现象：命令 ①② 都能正常启动到 nav，但停在游客态；`idea.log` / `flutter run` 输出里只有正常的启动日志，没有任何 `[E2E]` 行。
- 关联 issue：#408
- 状态变更：2026-11-25 已确认 → #408

### [已确认] e2e: 没有就绪信号与会话清理钩子：设备黑盒只能 sleep 猜时间，残留会话让结果不稳定

- 包/版本：w_tools_e2e 0.2.0（本地检出 `packages/e2e`）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26、UAT 接口（登录约 40s）；iPhone 17 模拟器 + Pixel 5；配合 `w_tools_device` 做设备黑盒冒烟
- 命令 / 输入：
  ```bash
  # 起 E2E 入口
  flutter run -t tool/main_e2e.dart -d <udid> \
    --dart-define=E2E=1 --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
  # 紧接着跑设备冒烟（此刻首页数据可能还没回来）
  dart run tool/device_smoke.dart --device=<udid>
  ```
- 期望：
  1. 有一个**稳定的就绪标记**：登录成功 **且** 首屏数据就绪之后打一行（例如 `[E2E] ready home`），黑盒脚本等这一行再开始点，而不是 `sleep` 猜时间；
  2. 有一个**登录前钩子**（例如 `E2eLogin.run(beforeLogin: ...)`），让调用方清掉残留会话 / token，保证每次从干净状态开始。
- 实际：
  1. 只有 `[E2E] auto login ok`，它在 `login()` 返回后立刻打印（`e2e_login.dart:37`），**不代表页面/数据就绪**；`afterLogin` 默认还是 fire-and-forget（`:47-53`），调用方没法从返回值判断「可以开始点了」；
  2. 没有 `beforeLogin` / 清会话能力，只能由 App 自己在 `afterLogin` 里补，或者手工 `simctl uninstall` / `pm clear`；
  3. README「集成测试」示例用的是 `pumpAndSettle` + 固定 `pump`，对真机黑盒不适用。
- 影响（我因此做错了什么 / 多花了什么）：UAT 慢的时候设备冒烟会「点早了」——首页还在 skeleton 就点 tab，`verify` 拿到 `changed:false`，看起来像「坐标失效 / tab 点不动」，实际只是没等数据；反过来 sleep 太长又白等。模拟器残留上一账号 token 时，结果还会不稳定（可能跳过登录、也可能登录后状态错位），排查成本高。
- 建议：
  1. 提供 `E2eSignals.ready([String detail = ''])`（内部 `debugPrint('[E2E] ready $detail')`），由 App 在「登录 + 首屏数据就绪」后调用一次；黑盒用日志管道等它（`flutter run` stdout / `adb logcat` / `xcrun simctl spawn <udid> log stream`）；
  2. `E2eLogin.run` 增加可选 `FutureOr<void> Function()? beforeLogin`，在 `login()` 之前 await；README 写一条「建议在此清会话 / 清 token」；
  3. 文档补一节「设备黑盒怎么配合」：等 `[E2E] ready` → 再 `device_smoke`；并写清残留会话的处理方式。
- 复现数据：
  - `packages/e2e/lib/src/e2e_login.dart:37`（登录成功即 `debugPrint('[E2E] auto login ok: ...')`）、`:47-53`（`afterLogin` 默认 `unawaited`）、`:27-33`（`run` 的参数里没有 beforeLogin）；
  - `packages/e2e/README.md` 的「集成测试」示例（`pumpAndSettle` + 固定 `pump`）；
  - 本项目：`tool/main_e2e.dart` 的 `afterLogin: () => Get.offAllNamed(Routes.NAV)` 之后没有任何「数据就绪」信号；`tool/device_smoke.dart` 目前只能靠固定等待/重试。
- 关联 issue：#408
- 状态变更：2026-11-25 已确认 → #408

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | `bool.fromEnvironment('E2E')` 只认 `true`，`--dart-define=E2E=1` 静默失效 | ✅ 0.1.0：按字符串解析，接受 `1` / `true` |
| 2026-11-03 | 登录成功但 `afterLogin`（导航）失败时被判成「登录失败」 | ✅ 0.1.0：登录成功即 true，导航错误单独上报 |
| 2026-11-03 | `Get.offAllNamed` 有时不 resolve，`await` 它导致成功日志永远打不出来 | ✅ 0.1.0：登录成功立即打日志，导航 `unawaited` |
| 2026-11-04 | 首个版本已发布后仍有 `afterLogin` / `onError` 修复，版本未抬导致再次发布失败 | ✅ 0.1.1（94ad2fb）：补版本与 CHANGELOG |
