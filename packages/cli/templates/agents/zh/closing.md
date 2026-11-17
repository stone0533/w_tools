## 完成前

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error；规则清单与启用状态（R1~R9）也在这里看。
- `{{analyze}}`、`{{test}}`；跑不了就明确说没跑，不要贴假输出。
- w_tools 提供的能力 / 配置无法按文档或合理预期工作，或设置项不生效、
  无法实现对应功能时：先查重；仅当 `.w_tools_doctor.yaml` 的
  `feedback.enabled: true` 时才提交：
  `dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>` → `feedback submit ...`。
  也包括文档 / 迁移误导、公共能力缺口导致重复绕路。
  业务代码、环境权限、一次性问题、纯项目偏好不要记；反馈不是每个任务都必须提交。
  默认关闭时跳过（不写文件、不建 Issue、不加 `--issue`）；完整流程见 `.w_tools/AI_PROMPTS.md` 的 L-1。
<!-- w_tools:end -->
