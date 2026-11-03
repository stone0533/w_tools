# w_tools_figma 反馈

## 待处理

### [待处理] figma: `fetch nodes` 没有深度限制，单页缓存 129 MB

- 包/版本：w_tools_figma 0.9.2
- 环境：macOS 27.2 / Flutter 3.44
- 命令 / 输入：`dart run w_tools_figma:figma fetch nodes <fileKey> 0:1`
- 期望：能限制子树深度（像 `fetch file --depth=3` 那样）
- 实际：一次拉整页子树，单文件 129 MB；`cache stats` 显示 132 MB
- 影响（我因此做错了什么 / 多花了什么）：误删缓存后重建一次就占了 129 MB；
  磁盘/备份/CI 缓存都变重，且 `spec` 读大文件更慢
- 建议：`fetch nodes --depth=<n>`（默认不限），或文档提醒「只拉需要的子节点」
- 复现数据：`nodes-<fileKey>-0-1.json` 129 MB（页面 27 个顶层容器）
- 状态变更：2026-11-03 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | 新旧 token 同时存在时，迁移跳过真 token（保留模板） | ✅ 0.8.0（feccfb1）：新位置是模板、旧位置是真 token 时用真 token 覆盖 |
| 2026-11-03 | 迁移把 `_usage.log` 搬进项目缓存目录，额度历史丢失 | ✅ 0.8.0（feccfb1）：用量并入账号级、`_budget.json` 只在账号级缺失时复制 |
| 2026-11-03 | `cache clean --all` 无确认，误删 59.7 MB 设计缓存 | ✅ 0.9.1（6349e4d）：`--all` 必须带 `--yes` |
| 2026-11-03 | 测试进程写真实额度日志（2 条被污染成 87 条） | ✅ 0.9.0（c6ba2d4）：测试注入 `homeOverride`，`diff_test` 补隔离；再跑测试用量不变 |
| 2026-11-03 | AGENTS 的 Figma 段仍指向 `.figma-token`（0.8.0 已改路径） | ✅ cli 1.9.0（feccfb1）：模板改为 `~/.config/w_tools/figma-token` |
| 2026-11-03 | `cache` / `usage` 帮助没有说明新路径与 `--yes` | ✅ 0.9.2（df77851 / c163022）：帮助与 `docs/figma-cli.md` 同步 |
