# w_tools_e2e example

This is an integration snippet, not a standalone app.

Put the import and call in `tool/main_e2e.dart`; production `lib/main.dart` must not import `w_tools_e2e`.

```dart
import 'package:w_tools_e2e/w_tools_e2e.dart';

// 不要提前 if (!config.canAutoLogin) return;：run() 会打 [E2E] skip: <reason>。
await E2eLogin.run(
  config: E2eConfig.fromEnvironment(),
  beforeLogin: () => repository.clearSession(),
  login: (email, password) => repository.login(email, password),
  afterLogin: () => router.go('/home'),
  onError: (error, stack) => logger.warning('E2E failed: $error'),
);

// 首页首屏数据就绪后，再给设备黑盒一个稳定的等待点。
E2eSignals.ready('home');
```

Run the host app with:

```bash
flutter run -d <device> \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

The host app owns `repository`, `router`, and `logger`; this package only
guards the compile-time switch and runs the login callback.
