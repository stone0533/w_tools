## Hard rules

- Depend on subpackages, never the aggregate `w_tools`.
- Business code imports only the toolkit entry, never `package:w_tools_*` directly.

## Checks

> R6 must be enabled in `.w_tools_doctor.yaml`; R9 requires `banned`.
> The project config is the source of truth for activation.

{{doctorRules}}

## Before done

- `dart run w_tools_cli:w_tools doctor --json` → 0 error (warnings are contextual)
- `flutter analyze`, `flutter test`
- Used `w_tools_*` and got blocked? → check `feedback.issue` in `.w_tools_doctor.yaml`;
  if off, skip (default); if on, follow "Usage feedback" (search → submit).
<!-- w_tools:end -->
