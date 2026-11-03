# w_tools_e2e example

This is an integration snippet, not a standalone app.

```dart
import 'package:w_tools_e2e/w_tools_e2e.dart';

final config = E2eConfig.fromEnvironment();
if (config.canAutoLogin) {
  await E2eLogin.run(
    config: config,
    login: (email, password) => repository.login(email, password),
    afterLogin: () => router.go('/home'),
    onError: (error, stack) => logger.warning('E2E failed: $error'),
  );
}
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
