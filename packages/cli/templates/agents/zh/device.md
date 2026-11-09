- **设备 / 真机验证**（`w_tools_device`，可选）：先读 `docs/agents/device-testing.md`，不要手写 adb / DeviceHub。
  子命令：`dart run w_tools_device:device list|boot|shot|calibrate|tap|drag|type|size|foreground|wait|verify`。
  E2E 自动登录用 `w_tools_e2e`（只放 `tool/main_e2e.dart`，凭证只用测试账号）。
