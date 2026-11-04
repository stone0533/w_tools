# E2E 免登录入口

`w_tools_e2e` 只负责“用测试账号登录”这一层，不是通用 E2E 框架。

- 包说明：[`packages/e2e/README.md`](../../packages/e2e/README.md)
- 依赖：`dev_dependencies` 加 `w_tools_e2e`
- 编译期开关：`E2E=1` + `E2E_EMAIL` + `E2E_PASSWORD`，release 不生效

推荐把测试入口与生产入口分开：

```text
lib/main.dart          -> 只调 bootstrap()，不 import w_tools_e2e
tool/main_e2e.dart     -> 唯一 import w_tools_e2e 的入口
```

`tool/main_e2e.dart` 根据项目实际结构调整：

```dart
import 'package:my_app/app/bootstrap.dart';
import 'package:my_app/features/auth/auth_repository.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

Future<void> main() async {
  await bootstrap(
    afterStart: () => E2eLogin.run(
      login: (email, password) => AuthRepository.login(email, password),
    ),
  );
}
```

注意：

- 测试账号只用于测试，不要复用真实密码；
- 登录后的导航不要让 `E2eLogin.run` 的返回值依赖；
- `Get.offAllNamed` 等导航调用可能不 resolve，属于项目侧实现细节；
- 凭证不要提交到仓库。
