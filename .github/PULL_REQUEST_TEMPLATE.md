## 改动类型

- [ ] 内部重构（公开 API / 默认行为不变）
- [ ] 公开变化（API / 行为 / 新组件）
- [ ] 删除 / 废弃
- [ ] 新增包

## 命名（`docs/naming.md` §7）

- [ ] 新公开类型有且只有一个角色后缀（§3.3）
- [ ] 没有双角色名、`Config` 装行为、`Options` 装 UI
- [ ] 新增 `Config` 已登记 `scripts/naming_baseline.yaml`
- [ ] 公开 `build()` 只在 `*Builder` 上
- [ ] 改名 / 删除已同步 catalog、README、example、migration、baseline

## 公开变化的教学同步（有公开 API / 行为变化时）

- [ ] 已跑 J-4（AI 教学覆盖审计），结论贴在本 PR
- [ ] catalog 的 `usage` / `pitfalls` / `related` / `dontUseFor` 已同步
- [ ] `docs/agents/<pkg>.md` 与 `templates/agents/{zh,en}/<pkg>.md` 已同步
- [ ] README / example / migration 已同步
- [ ] `bash scripts/preflight.sh --with-tests` 通过

## 自检

- [ ] `bash scripts/preflight.sh --with-tests`（或说明未跑原因）
