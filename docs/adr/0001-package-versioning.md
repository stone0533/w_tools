> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0001：子包独立版本与 semver 规则

- 状态：已采纳（2026-10-24）
- 相关：操作规则与检查项见 [`docs/releasing.md`](../releasing.md)；
  `scripts/release_check.sh`、`scripts/publish_package.sh`
- 适用范围：`packages/*` 下的库包与工具包；数量以各自 `pubspec.yaml` 为准

## 背景

多包 monorepo：库包、工具包、聚合包共享一个 workspace，但交付节奏不同。首发时全部为 1.0.0
（2026-10-19），之后各包按自己的节奏发版，`w_tools_ui`、`w_tools_map`、`w_tools_core`
的版本很快分叉。

期间发生过一次 semver 偏差：`w_tools_ui 1.1.0` 删除了公开组件 `WNetworkImageWithRetry`，
按 semver 应为 2.0.0。偏差本身不致命，但它暴露了「版本号只写在 pubspec、没人对语义负责」的问题。

## 决策

1. **子包独立发版，版本号不互相对齐**；聚合包按自己的版本独立发布。
   版本不同是预期状态，不要为了「看起来一致」给没有改动的包 bump。
2. **版本语义**：`Fixed` → patch；`Added` / 兼容的 `Changed` → minor；
   `Removed` / 破坏性行为变更 → **major**。
3. **聚合包约束**：caret 下界取子包当前版本（如 `^1.2.0`），否则已有 lockfile 的用户不会自动升级。
4. **已发布版本不回滚、不重发**：有外部使用者时 fix-forward —— patch 恢复兼容
   （通常加 `@Deprecated` 垫片），下个 major 再删；确认没有外部使用者时记录例外，不加重发。
5. **发布必须走 `scripts/publish_package.sh`**：仓库的 `workspace:` / `resolution: workspace`
   不能原样发给消费方。

具体发版步骤、检查项与常见坑统一维护在 [`docs/releasing.md`](../releasing.md)，
本 ADR 只记录决策与理由，不复制操作手册。

## 后果

- 子包版本分叉是预期状态；每次子包 major 都要评估聚合包是否跟着 major；
- 版本 ↔ CHANGELOG ↔ 根约束 ↔ 发布物的一致性由 `release_check.sh` 守；
- 消费方升级时看的是自己依赖的那几个包，而不是「仓库版本」。

## 备选方案

- **所有子包版本对齐（单一版本号）**：否决 —— 改一个包也要全量发版，消费方被迫升级无关包。
- **每个包一个仓库**：否决 —— 共享 workspace、统一门禁与模板的收益更大，拆仓会让检查成本翻倍。
- **按 CHANGELOG 自动推导版本**：暂不采纳 —— 版本是发布决策，脚本只做校验不做判断。

## 重新评估的条件

- pub 支持 monorepo 的变更检测 / 原子发布；
- 包数量明显收敛，独立发版的收益不再明显；
- 出现必须跨包同步 breaking（例如统一大版本宣传）的场景。

## 历史例外

- `w_tools_ui 1.1.0` 删除了 `WNetworkImageWithRetry`，按 semver 应为 2.0.0。
  发布时没有外部使用者，因此未回滚、未提供兼容垫片；该组件自 1.1.0 起不再存在，
  后续破坏性改动一律按 major 发布。
