# w_tools_e2e

设备/集成验证用的**免登录入口**。编译期开关，凭证不进仓库，release 包天然失效。

> **生产 `lib/main.dart` 不得 import `w_tools_e2e`**。CI 可加一行守卫：
> `grep -rn "w_tools_e2e" lib/ && exit 1 || true`。
> 它不是 E2E 框架：只负责登录种子，selectors / tap / 截图用 `integration_test` / `w_tools_device`。

## 安装

```yaml
dev_dependencies:
  w_tools_e2e: ^0.2.0
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
import 'package:w_tools_e2e/w_tools_e2e.dart';

Future<void> main() async {
  await bootstrap(
    afterStart: () async {
      final config = E2eConfig.fromEnvironment();
      if (!config.canAutoLogin) return;

      final ok = await E2eLogin.run(
        config: config,
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
- `run()` 返回 `false`：未启用 / 缺账号密码 / 登录失败 / 超时
- `afterLogin` 默认不阻塞 `run()` 的返回值
- 集成测试需要等导航完成时传 `awaitAfterLogin: true`（afterLogin 不 resolve 会一直等）
- `onError` 可同步或异步；回调自身抛错不会让 `run()` 抛出
- 默认超时 60s（UAT/弱网登录可能 40s 以上）

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
```

完整示例见 [`example/README.md`](example/README.md)。

## 不要这样做

```dart
// lib/main.dart 不要 import w_tools_e2e
```
