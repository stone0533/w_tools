## 设备验证（可选）

需要模拟器 / Android / 真机截图、点击、等待稳定或 E2E 自动登录时，先读 `docs/agents/device-testing.md`。

- 设备操作使用 `w_tools_device`；不要手写 adb / DeviceHub 标定。
- E2E 自动登录使用 `w_tools_e2e`；只使用测试账号，凭证不要复用真实密码。
- `w_tools_e2e` 只能放 `tool/main_e2e.dart`；不要把测试依赖 import 到生产 `lib/main.dart`。
