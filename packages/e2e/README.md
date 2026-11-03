# w_tools_e2e

设备/集成验证用的**免登录入口**。编译期开关，凭证不进仓库，release 包天然失效。

## 安装

```yaml
dev_dependencies:
  w_tools_e2e: ^0.1.0
```

或：

```bash
flutter pub add dev:w_tools_e2e
```

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

- 生效条件：`E2E=1`（或 `true`）+ 账号/密码非空 + **非 release**
- `--dart-define` 会进入 debug/profile 构建产物；只用于测试账号，不要复用真实密码
- `run()` 返回 `false`：未启用 / 缺账号密码 / 登录失败 / 超时
- `afterLogin` 不阻塞 `run()` 的返回值
- `onError` 可同步或异步；回调自身抛错不会让 `run()` 抛出
- 默认超时 60s（UAT/弱网登录可能 40s 以上）

## 集成测试

```dart
testWidgets('E2E auto login reaches home', (tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.text('Home'), findsOneWidget);
});
```

完整示例见 [`example/README.md`](example/README.md)。

## 不要这样做

```dart
// lib/main.dart 不要 import w_tools_e2e
```
