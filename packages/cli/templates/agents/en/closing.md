## Hard rules

- Depend on subpackages, never the aggregate `w_tools`.
- Business code imports only the toolkit entry, never `package:w_tools_*` directly.

## Checks

> R6 must be enabled in `.w_tools_doctor.yaml`; R9 requires `banned`.
> The project config is the source of truth for activation.

{{doctorRules}}

## Before done

- `dart run w_tools_cli:doctor --json` → 0 error (warnings are contextual)
- `flutter analyze`, `flutter test`
<!-- w_tools:end -->
