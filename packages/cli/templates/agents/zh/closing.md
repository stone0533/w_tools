## 完成前

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error；规则清单与启用状态（R1~R9）也在这里看。
- `{{analyze}}`、`{{test}}`；跑不了就明确说没跑，不要贴假输出。
- 用了 `w_tools_*` 被卡住？`.w_tools_doctor.yaml` 的 `feedback.enabled: true` 才提交：
  `dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>` → `feedback submit ...`；
  默认关闭时跳过（不写文件、不建 Issue、不加 `--issue`）；完整流程见 `.w_tools/AI_PROMPTS.md` 的 L-1。
<!-- w_tools:end -->
