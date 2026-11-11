## Before done

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error; the rule list and activation state (R1–R9) live there.
- `{{analyze}}`, `{{test}}`; if you cannot run them, say so — never paste fake output.
- If you hit a problem or have a suggestion while using w_tools: search first; submit only when
  `.w_tools_doctor.yaml` has `feedback.enabled: true`:
  `dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>` → `feedback submit ...`;
  skip when off (no files, no Issue, no `--issue`). Full flow: `.w_tools/AI_PROMPTS.md` L-1.
<!-- w_tools:end -->
