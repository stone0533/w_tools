# w_tools_e2e

设备/集成验证用的**免登录入口**。编译期开关，凭证不进仓库，release 包天然失效。

```dart
// main.dart：app.start() 之后
if (E2eConfig.fromEnvironment().canAutoLogin) {
  await E2eLogin.run(
    login: (email, password) => repository.login({'email': email, 'password': password}),
    afterLogin: () => Get.offAllNamed(Routes.NAV),
  );
}
```

```bash
flutter run -d <device> \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

- 生效条件（三选三）：`E2E=1`（或 `true`）+ 账号/密码非空 + **非 release**
- `--dart-define` 会进入 debug/profile 构建产物；只用于测试账号，不要复用真实密码
- `run()` 失败只回调 `onError` / 打日志，不抛异常、不阻塞启动
- 默认超时 60s（UAT/弱网登录可能 40s 以上）
