## Usage feedback (off by default)

When `w_tools_*` blocks you, or a capability could be better: **search first; submit only if the project enables it.**

### Step 1: check whether it is enabled

Only when `.w_tools_doctor.yaml` contains:

```yaml
feedback:
  enabled: true
```

may you submit (the legacy key `issue: true` still works). Without it (or false) → **do nothing**:
no local file, no link, no Issue; do not try `--issue` to get around it — it fails with exit 2.

### When enabled: the local ledger wins

1. **Search**

   ```bash
   dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>
   ```

   Searches the local ledger when this machine has one; add `--gh` to search GitHub
   issues when it does not (exits 3 if `gh` is missing or logged out).

2. **Write the body** (fields are validated; run
   `dart run w_tools_cli:w_tools feedback submit --template` to print the skeleton)

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

3. **Submit** (default route: local ledger → Issue)

   ```bash
   dart run w_tools_cli:w_tools feedback submit \
     --package=<package> --title="<one-line symptom>" --body-file=/tmp/w_tools_feedback.md
   ```

   - A w_tools checkout on this machine (path / git dependency) → appends to **its** `docs/feedback/`;
     no Issue is created;
   - Checkout somewhere else that the dependency does not resolve → add
     `feedback.ledger: <path>` (relative to the project root, or absolute);
   - No local checkout → creates a GitHub Issue (requires `gh`; it reads `GH_TOKEN` /
     `GITHUB_TOKEN`, or use `gh auth login`);
   - Neither → skipped with **exit 4**, nothing is written;
   - Use `--issue` only when you have a local ledger but really want a public issue;
     `--ledger` forces the local ledger;
   - At most 5 public issues per project per day (`feedback.max_issues_per_day`, 0 = unlimited);
     once used up, submit exits 2. The local ledger does not count.

### Boundaries

- At most 3–5 entries per session, only what **actually blocked you**;
- Status is only `pending`; **never mark it fixed yourself**;
- Issues are public: no secrets, tokens or business-sensitive data; redact logs first;
- Writing the local ledger dirties the w_tools working tree: remind me to commit / discard afterwards;
  never commit someone else's repo on your own;
- Do not put feedback in business code or `.w_tools/`;
- Maintainers triage into `w_tools/docs/feedback/<package>.md`.
