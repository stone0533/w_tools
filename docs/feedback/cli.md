# w_tools_cli 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | `init --check` 会移动 `.w_tools_init.json`（check 写盘） | ✅ 1.9.0（feccfb1）：迁移只在非 check 模式执行 |
| 2026-11-03 | manifest 已存在且内容不同时永不更新（`--device` 记录不进去） | ✅ 1.8.1（bcde39d）：manifest 走 `metadata` 写，不受 `--force` 限制 |
| 2026-11-03 | 旧 toolkit（无标记块）迁移时丢掉项目追加的 export | ✅ 1.8.1（bcde39d）：自动迁移模板之外的 export，并提示条数 |
| 2026-11-03 | `--force` 覆盖 `.w_tools_doctor.yaml` 与 UI starters（丢了 12 条 banned） | ✅ 1.8.0（a9f9721）：`--force` 不再碰 starter；config 覆盖前备份 `.bak` |
| 2026-11-03 | R2 正则匹配不到带数字的包名（`w_tools_e2e`） | ✅ 1.8.0（936eaff）：`w_tools(?:_[a-z0-9_]+)?` |
| 2026-11-03 | `init --check` 与不带 `--device` 的 `init` 参数不一致会误报漂移 | ✅ 1.8.1（f962d2e）：manifest 回放上次 flags；本项目固定用 `init --device --no-map` |
