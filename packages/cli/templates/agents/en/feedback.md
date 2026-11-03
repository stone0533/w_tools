## Usage feedback (for AI)

When you hit a problem with `w_tools_*`, or a rule does not fit: **record it, do not patch the library**.

1. **Check for duplicates** first: `docs/agents/feedback.md` in this project (skip if absent);
   if the w_tools repo is available, also check `<repo>/docs/feedback/<package>.md`.
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
