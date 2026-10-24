# Agent instructions

## 组件约定

改动 `packages/*` 里的组件前：先读 [`CONTRIBUTING.md`](CONTRIBUTING.md)（新增组件的 4 条硬性要求），
再查 [`docs/modules/components.md`](docs/modules/components.md)（有没有现成的、别重复造），
接口设计原则见 [`docs/conventions.md`](docs/conventions.md) §6。

> 消费方项目的接入方式（聚合入口、暂存层、`AGENTS.md` 片段）**不要**写进本文件 ——
> 那些由 `dart run w_tools_cli:init` 生成到**对方**仓库里；本文件只管「在本仓库怎么改」。

## 工具（本仓库维护）

CLI 在 **`packages/cli/`（包名 `w_tools_cli`，纯 Dart）**：
`bin/init.dart`、`bin/doctor.dart`，实现分别在 `lib/src/init/`、`lib/src/doctor/`。

改动它们时必须同步：

- [`docs/conventions.md`](docs/conventions.md) §7 的规则表（doctor 的 R1~R6）
- [`docs/modules/components.md`](docs/modules/components.md)（若涉及组件建议）
- `packages/cli/test/init_test.dart` / `doctor_test.dart` 的用例
- `packages/cli/CHANGELOG.md`

**改了 `DoctorConfig` 的默认值**必须同步 `renderDefaultConfig()`（`doctor --print-config` 的输出），
`packages/cli/test/config_render_test.dart` 会挡住漂移。

**改了 `packages/cli/templates/` 下的模板文件后必须跑**（在 `packages/cli/` 下）：

```bash
dart run tool/gen_templates.dart
```

生成 `lib/src/init/templates.g.dart`，否则 `test/templates_fresh_test.dart` 会红 ——
这是有意的：模板只允许有一份来源（`templates/`）。

CLI 是纯 Dart 包：测试用 `dart test`，发布用 `dart pub publish`（`scripts/publish_package.sh` 会自动识别）。

## Agent skills

### Issue tracker

GitHub Issues in `stone0533/w_tools`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

single-context — one root `GLOSSARY.md` shared by the app and all packages, with architecture decisions in `docs/adr/`. See `docs/agents/domain.md`.

### Tests

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立 `flutter test` / 发布。根 `test/` 只留聚合契约（`w.dart` 的重导出、`WConfig` 兼容层）。`packages/cli` 是纯 Dart 包，用 `dart test`。CI 用矩阵逐包跑 analyze / test / `pub publish --dry-run`。

### 文档

改 `docs/` 后跑 `bash scripts/check_docs.sh`（检查相对链接、旧命令、包清单；CI 也会跑）。

### Release

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。子包与聚合包版本独立，根包的 `^x.y.z` 约束必须覆盖子包当前版本（`w_tools_cli` 是独立工具包，根包不依赖它，不在此列）。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。

