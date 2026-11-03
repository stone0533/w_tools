## Device validation (optional)

When you need simulator / Android / real-device screenshots, taps, stability waits, or E2E auto-login, read `docs/agents/device-testing.md` first.

- Use `w_tools_device`; do not hand-roll adb or DeviceHub calibration.
- Use `w_tools_e2e` for E2E auto-login; test accounts only, never real passwords.
- Keep `w_tools_e2e` in `tool/main_e2e.dart`; never import test dependencies into production `lib/main.dart`.
