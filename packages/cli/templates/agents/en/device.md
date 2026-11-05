## Device validation (optional)

When you need simulator / Android / real-device screenshots, taps, stability waits, or E2E auto-login, read `docs/agents/device-testing.md` first.

- Use `w_tools_device`; do not hand-roll adb or DeviceHub calibration.
- Use `w_tools_e2e` for E2E auto-login; test accounts only, never real passwords.
- Keep `w_tools_e2e` in `tool/main_e2e.dart`; never import test dependencies into production `lib/main.dart`.

Common commands (full flags: `docs/agents/device-testing.md`):

```bash
dart run w_tools_device:device list
dart run w_tools_device:device boot "<name|udid>"
dart run w_tools_device:device shot --out=/tmp/a.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device type "hello"
dart run w_tools_device:device size
dart run w_tools_device:device foreground --android
dart run w_tools_device:device wait
dart run w_tools_device:device verify <x> <y>
```
