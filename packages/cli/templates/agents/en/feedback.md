## Usage feedback (off by default)

When `w_tools_*` blocks you, or a capability could be better: **search first; submit only if the project enables it.**

### Step 1: check whether it is enabled

Only when `.w_tools_doctor.yaml` contains:

```yaml
feedback:
  issue: true
```

may you create a GitHub Issue. Without it (or false) → **do nothing**: no local file, no link.

### When enabled

1. **Search**

   ```bash
   dart run w_tools_cli:feedback search "<keywords>" --package=<package>
   ```

2. **Write the body** (fields are validated; run
   `dart run w_tools_cli:feedback submit --template` to print the skeleton)

   ```md
   - package/version:
   - environment:
   - command / input:
   - expected:
   - actual:
   - impact:
   - suggestion:
   - repro data:
   ```

   Save it as `/tmp/w_tools_feedback.md`.

3. **Submit** (`--issue` explicitly overrides the config)

   ```bash
   dart run w_tools_cli:feedback submit \
     --package=<package> --title="<one-line symptom>" --body-file=/tmp/w_tools_feedback.md --issue
   ```

   - Requires `gh` installed; gh reads `GH_TOKEN` / `GITHUB_TOKEN` or uses `gh auth login`;
   - Prints the issue URL on success; fails loudly otherwise (no manual-link fallback).

### Boundaries

- At most 3–5 entries per session, only what **actually blocked you**;
- Status is only `pending`; **never mark it fixed yourself**;
- Do not put feedback in business code or `.w_tools/`;
- Maintainers triage into `w_tools/docs/feedback/<package>.md`.
