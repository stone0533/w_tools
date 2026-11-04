## Usage feedback (for AI)

When `w_tools_*` blocks you, or a capability could be better: **search first, submit, do not patch the library**.

### What counts

- Docs/examples do not compile, or behavior contradicts docs
- Missing API forces repeated workarounds
- A rule/component clearly does not fit real screens (not personal style)

### Three steps

1. **Search**

   ```bash
   dart run w_tools_cli:feedback search "<keywords>" --package=<package>
   # add --gh to also search GitHub issues when gh is authenticated
   ```

2. **Write the body** following `docs/feedback/TEMPLATE.md` fields into a temp file (or use `--stdin`).

3. **Submit**

   ```bash
   dart run w_tools_cli:feedback submit \
     --package=<package> --title="<one-line symptom>" --body-file=/tmp/feedback.md
   ```

   - Default: print a prefilled GitHub issue URL, **no automatic upload**;
   - `--gh`: create the issue via `gh` (must be logged in);
   - Offline: `--local` appends to `docs/agents/feedback.md` for later submission.

### Boundaries

- Status is only `pending`; **never mark it fixed yourself**;
- At most 3–5 entries per session, only what **actually blocked you**;
- Do not put feedback in business code or `.w_tools/`;
- Maintainers triage into `w_tools/docs/feedback/<package>.md` (single source of truth).
