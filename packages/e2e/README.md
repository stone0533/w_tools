# w_tools_e2e

设备/集成验证用的**免登录入口**。编译期开关，凭证不进仓库，release 包天然失效。

> **生产 `lib/main.dart` 不得 import `w_tools_e2e`**。CI 可加一行守卫：
> `grep -rn "w_tools_e2e" lib/ && exit 1 || true`。
> 它不是 E2E 框架：只负责登录种子，selectors / tap / 截图用 `integration_test` / `w_tools_device`。

## 安装

```yaml
dev_dependencies:
  w_tools_e2e: ^0.3.0
```

或：

```bash
flutter pub add dev:w_tools_e2e
```

## 5 分钟上手

1. `dev_dependencies` 加 `w_tools_e2e`；
2. 按下面的「推荐结构」建 `tool/main_e2e.dart`（唯一 import 入口）；
3. `flutter run -t tool/main_e2e.dart --dart-define=E2E=1 --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...`。

## 推荐结构

```text
lib/main.dart              → bootstrap()，不 import w_tools_e2e
lib/app/bootstrap.dart     → 提供 afterStart 钩子
tool/main_e2e.dart         → 唯一 import w_tools_e2e 的入口
```

不要把 `w_tools_e2e` import 到生产 `lib/main.dart`。

`tool/main_e2e.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:my_app/app/bootstrap.dart';
import 'package:my_app/app/router.dart';
import 'package:my_app/features/auth/auth_repository.dart';
import 'package:my_app/features/home/home_controller.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

Future<void> main() async {
  await bootstrap(
    afterStart: () async {
      // 不要写 if (!config.canAutoLogin) return; —— run() 会打 [E2E] skip: <reason>。
      final ok = await E2eLogin.run(
        config: E2eConfig.fromEnvironment(),
        // 清残留会话 / token，保证每次从干净状态开始。
        beforeLogin: () => AuthRepository.instance.clearSession(),
        login: (email, password) async {
          await AuthRepository.instance.login(email, password);
        },
        afterLogin: () async {
          await AppRouter.instance.goHome();
        },
        onError: (error, stack) async {
          debugPrint('[E2E] $error\n$stack');
        },
      );
      debugPrint('[E2E] login ok: $ok');
    },
  );
}
```

就绪信号要放在**首页首屏数据加载完成**的位置，而不是登录成功那一刻：

```dart
// 首页 controller / repository 的“首屏数据就绪”回调里
E2eSignals.ready('home');   // 输出：[E2E] ready home
```

```bash
flutter run -d <device> -t tool/main_e2e.dart \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

## 行为

- 生效条件：`E2E=1`（或 `true`）+ 账号/密码非空 + **debug**
- profile 默认不生效；确实要做 profile E2E 时显式加 `--dart-define=E2E_PROFILE=1`
- release 永远不生效；`--dart-define` 会进入 debug/profile 构建产物，只用于测试账号
- 条件不满足时 `run()` 返回 `false` 并打一行 `[E2E] skip: <reason>`；不再静默返回
- `run()` 返回 `false`：条件不满足 / 登录失败 / 超时
- `beforeLogin` 在 `login` 之前 await；它抛错时返回 `false`，不会继续登录
- `afterLogin` 默认不阻塞 `run()` 的返回值
- 集成测试需要等导航完成时传 `awaitAfterLogin: true`（afterLogin 不 resolve 会一直等）
- `onError` 可同步或异步；回调自身抛错不会让 `run()` 抛出
- 默认超时 60s（UAT/弱网登录可能 40s 以上）

## 为什么不自动登录（故障排查）

先看日志里的 `[E2E] skip: <reason>`：

| reason | 含义 | 修复 |
| --- | --- | --- |
| `releaseBuild` | release 构建永远不生效 | 用 debug 构建 |
| `flagOff` | 没传 `--dart-define=E2E=1`（或 `true`） | 补开关 |
| `profileNotAllowed` | profile 构建没显式放行 | 加 `--dart-define=E2E_PROFILE=1` |
| `missingEmail` | 缺 `E2E_EMAIL` | 补账号 |
| `missingPassword` | 缺 `E2E_PASSWORD` | 补密码 |
| `disabled` | 手工构造的 `E2eConfig(enabled: false)` | 检查构造参数 |

`[E2E] auto login ok` 只代表**登录接口返回**，不代表页面 / 首屏数据就绪。

## 设备黑盒怎么配合

黑盒脚本不要 `sleep` 猜时间，等 `[E2E] ready` 再开始点击：

```bash
# 1) 起 App，日志落盘
flutter run -d <udid> -t tool/main_e2e.dart \
  --dart-define=E2E=1 --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=... \
  | tee /tmp/e2e.log &

# 2) 等到就绪行（超时自己控制）
until grep -q '\[E2E\] ready' /tmp/e2e.log; do sleep 1; done

# 3) 再跑设备冒烟（等画面稳定，再点/verify）
dart run w_tools_device:device wait --device=<udid>
dart run w_tools_device:device verify <x> <y> --device=<udid>
```

- Android：`adb logcat` 里 grep `[E2E] ready`；
- iOS 模拟器：`xcrun simctl spawn <udid> log stream`（或 `flutter run` stdout）。

登录前要清残留会话时用 `beforeLogin`，不要手工 `simctl uninstall` / `pm clear`。

## 集成测试

`tool/main_e2e.dart` 里可以传 `awaitAfterLogin: true`，保证导航完成后再返回：

```dart
final ok = await E2eLogin.run(
  login: (email, password) => AuthRepository.login(email, password),
  afterLogin: () => router.goHome(),
  awaitAfterLogin: true,
);
```

```dart
testWidgets('E2E auto login reaches home', (tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.text('Home'), findsOneWidget);
});
```

```bash
flutter test integration_test/app_test.dart \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

完整示例见 [`example/README.md`](example/README.md)。

## 不要这样做

```dart
// lib/main.dart 不要 import w_tools_e2e
```
