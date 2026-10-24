# Agent instructions

## Agent skills

### Issue tracker

GitHub Issues in `stone0533/w_tools`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

single-context — one root `GLOSSARY.md` shared by the app and all packages, with architecture decisions in `docs/adr/`. See `docs/agents/domain.md`.

### Tests

每个子包的行为测试放在 `packages/<pkg>/test/`，并在该包的 `dev_dependencies` 里声明所需依赖 —— 子包要能脱离仓库根独立 `flutter test` / 发布。根 `test/` 只留聚合契约（`w.dart` 的重导出、`WConfig` 兼容层）。CI 用矩阵逐包跑 analyze / test / `pub publish --dry-run`。

### Release

改版本号 / CHANGELOG / 根包依赖约束后跑 `bash scripts/release_check.sh`（CI 也会跑）；发布流程见 `docs/releasing.md`。子包与聚合包版本独立，根包的 `^x.y.z` 约束必须覆盖子包当前版本。

实际发布必须用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），不要在包目录直接 `flutter pub publish`：仓库的 `workspace:` / `resolution: workspace` 会被原样发布，消费方 `dart pub deps` 会因此失败（2.0.0 踩过）。

