# ADR 0001：子包独立版本与 semver 规则

- 状态：已采纳（2026-10-24）
- 相关：`docs/releasing.md`、`scripts/publish_package.sh`、`scripts/release_check.sh`

## 背景

`w_tools` 是 8 个 Flutter 子包 + 1 个纯 Dart 工具包（`w_tools_cli`）+ 1 个聚合包。首发时所有子包都是 1.0.0
（2026-10-19），之后各包按自己的节奏发版，于是出现 `w_tools_ui 1.1.0`、
`w_tools_map 1.2.0`、`w_tools_core 1.0.1` 并存的情况。

期间发生过一次 semver 偏差：`w_tools_ui 1.1.0` 删除了公开组件
`WNetworkImageWithRetry`，按 semver 应为 2.0.0。

## 决策

1. **子包独立发版，版本号不互相对齐**；聚合包按自己的版本独立发布。
   版本号不同是预期状态，不要为了“看起来一致”给没有改动的包 bump。
2. **版本语义**：
   - `Fixed` → patch
   - `Added` / 兼容的 `Changed` → minor
   - `Removed` / 破坏性行为变更 → **major**
3. **聚合包约束**：对各子包的 caret 下界取子包当前版本（如 `^1.2.0`），
   否则已有 lockfile 的用户不会自动升级。
4. **已发布版本不回滚、不重发**：
   - 有外部使用者时，破坏性改动发错版本 → fix-forward：patch 版本恢复兼容
     （通常加 `@Deprecated` 垫片）→ 下个 major 再删。
   - 确认没有外部使用者时，不回滚、不加垫片，记录例外并保证后续按 major 发。
5. **发布必须走 `scripts/publish_package.sh`**：去掉仓库的 `workspace:` /
   `resolution: workspace`，默认发到 pub.dev，并在 `Removed`/breaking 配非 major
   版本时给出警告。

## 后果

- 子包版本会分叉（ui 1.1.0 / map 1.2.0 / core 1.0.1），这是预期状态。
- 每次子包 major 都需要评估聚合包是否跟着发 major。
- `release_check.sh` 负责版本、CHANGELOG、根约束与发布物的一致性。

## 例外

- `w_tools_ui 1.1.0` 删除了 `WNetworkImageWithRetry`，按 semver 应为 2.0.0。
  发布时没有外部使用者，因此未回滚、未提供兼容垫片；该组件自 1.1.0 起不再存在，
  后续破坏性改动一律按 major 发布。
