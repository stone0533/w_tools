# w_tools_cli 反馈

## 待处理

### [待处理] cli: w_tools list 不传查询条件时内部错误（Cannot modify an unmodifiable list），退出 3

- 包/版本：w_tools_cli 2.9.2（本地 main 6e5423d；消费方 pubspec 约束 ^2.8.4，dependency_overrides 指本地）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；在 ureward 与 w_tools 仓库内都能复现
- 命令 / 输入：dart run w_tools_cli:w_tools list --format=prompt（无 query）

```bash
dart run w_tools_cli:w_tools list --format=prompt
# 不传 query；`list` 裸命令、`--format=text/json` 同样
```

- 期望：列出全部组件（catalog）。
- 实际：打印 `内部错误：Unsupported operation: Cannot modify an unmodifiable list`，退出码 3，没有任何组件输出。
- 影响：新项目 / agent 想一次浏览全部组件（而不是逐个关键词搜索）时直接失败；`context --format=prompt` 和其它查询都正常，很容易被误判为环境问题。
- 建议：`searchComponents('')` 现在直接 `return catalogEntries`（不可变列表），`list_command.dart` 随后 `results.sort(...)`；改成 `return List.of(catalogEntries)`（或 sort 前 `toList()`）。补一个「无 query 的 list 不抛异常」的 CLI 测试。
- 复现数据：内部错误：Cannot modify an unmodifiable list；exit=3

```text
$ dart run w_tools_cli:w_tools list --format=prompt
内部错误：Unsupported operation: Cannot modify an unmodifiable list
exit=3
```
源码位置：`packages/cli/lib/src/catalog/catalog.dart:28`（`if (q.isEmpty) return catalogEntries;`）与 `packages/cli/lib/src/catalog/list_command.dart:48`（`results.sort(...)`）。
- 状态变更：2026-11-23 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | `init --check` 会移动 `.w_tools_init.json`（check 写盘） | ✅ 1.9.0（feccfb1）：迁移只在非 check 模式执行 |
| 2026-11-03 | manifest 已存在且内容不同时永不更新（`--device` 记录不进去） | ✅ 1.8.1（bcde39d）：manifest 走 `metadata` 写，不受 `--force` 限制 |
| 2026-11-03 | 旧 toolkit（无标记块）迁移时丢掉项目追加的 export | ✅ 1.8.1（bcde39d）：自动迁移模板之外的 export，并提示条数 |
| 2026-11-03 | `--force` 覆盖 `.w_tools_doctor.yaml` 与 UI starters（丢了 12 条 banned） | ✅ 1.8.0（a9f9721）：`--force` 不再碰 starter；config 覆盖前备份 `.bak` |
| 2026-11-03 | R2 正则匹配不到带数字的包名（`w_tools_e2e`） | ✅ 1.8.0（936eaff）：`w_tools(?:_[a-z0-9_]+)?` |
| 2026-11-03 | `init --check` 与不带 `--device` 的 `init` 参数不一致会误报漂移 | ✅ 1.8.1（f962d2e）：manifest 回放上次 flags；本项目固定用 `init --device --no-map` |
