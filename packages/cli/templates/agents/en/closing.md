## Before done

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error; the rule list and activation state (R1–R9) live there.
- `{{analyze}}`, `{{test}}`; if you cannot run them, say so — never paste fake output.
- Used `w_tools_*` and got blocked? Submit only when `.w_tools_doctor.yaml` has `feedback.enabled: true`:
  `dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>` → `feedback submit ...`;
  when off (the default) skip it — no files, no Issue, no `--issue`. Full flow: `.w_tools/AI_PROMPTS.md` L-1.
<!-- w_tools:end -->
