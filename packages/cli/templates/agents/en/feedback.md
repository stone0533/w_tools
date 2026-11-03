## Usage feedback (for AI)

When you hit a problem with `w_tools_*`, or a rule does not fit: **record it, do not patch the library**.

1. **Check for duplicates** first: `docs/agents/feedback.md` in this project (skip if absent).
   To check the library side, resolve its path first:

   ```bash
   dart run w_tools_cli:context --format=json | python3 -c \
     "import json,sys; print(json.load(sys.stdin)['install']['feedbackDir'] or '')"
   ```

   Empty output means this is not a repo checkout (e.g. pub cache): **local inbox only**.
2. **Append an entry** to `docs/agents/feedback.md` (create it if missing, first line
   `# w_tools usage feedback (local inbox)`):

   ```md
   ### [pending] <package>: <one-line symptom>
   - package/version:
   - environment:
   - command / input:
   - expected:
   - actual:
   - impact (what it cost you):
   - suggestion:
   - repro data:
   ```

3. Status is only `pending`; **never mark it fixed yourself** (the maintainer adds the version).
4. At most 3–5 entries per session; record only what **actually blocked you**.
5. The maintainer syncs entries into `w_tools/docs/feedback/<package>.md` (**single source of truth**).
   Feedback is knowledge: keep it under `docs/`, never in `.w_tools/` (machine state).
