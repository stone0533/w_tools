- **Device validation** (`w_tools_device`, optional): read `docs/agents/device-testing.md` first; never
  hand-roll adb / DeviceHub. Subcommands:
  `dart run w_tools_device:device list|boot|shot|calibrate|tap|drag|type|size|foreground|wait|verify`.
  Use `w_tools_e2e` for E2E login (keep it in `tool/main_e2e.dart`, test accounts only).
