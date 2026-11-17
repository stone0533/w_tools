## Before done

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error; the rule list and activation state (R1–R9) live there.
- `{{analyze}}`, `{{test}}`; if you cannot run them, say so — never paste fake output.
- If a w_tools capability/config is unusable or a setting has no effect: search first;
  submit when `.w_tools_doctor.yaml` has `feedback.enabled: true`:
  `dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>` → `feedback submit ...`.
  Business/environment/one-off/preference issues do not count.
  Skip when off (no `--issue`); details: `.w_tools/AI_PROMPTS.md` L-1.
<!-- w_tools:end -->
