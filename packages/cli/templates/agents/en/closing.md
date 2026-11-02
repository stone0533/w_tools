## Hard rules

- Depend on subpackages, never the aggregate `w_tools`.
- Business code imports only the toolkit entry, never `package:w_tools_*` directly.

## Before done

- `dart run w_tools_cli:doctor --json` → 0 error (warnings are contextual)
- `flutter analyze`, `flutter test`
<!-- w_tools:end -->
