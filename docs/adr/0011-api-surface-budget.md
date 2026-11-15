> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0011：公开面预算——深模块优先，按包类型计预算

- 状态：已采纳（2026-11-15）
- 相关：[`scripts/check_api_budget.py`](../../scripts/check_api_budget.py)、
  [`scripts/api_budget.yaml`](../../scripts/api_budget.yaml)、[`CONTRIBUTING.md`](../../CONTRIBUTING.md)、
  [`scripts/README.md`](../../scripts/README.md)、[`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md)

## 背景

7.0 的公开面收敛删掉了大量“补一致性 / 便利构造 / 包装原语”的 API，但一次大清理不能防止
它重新长回来。复盘下来，膨胀通常来自六种模式：

1. **补一致性**：每加一个派生状态就加一个公开 getter；
2. **命名构造函数矩阵**：两个正交维度被编码成构造函数笛卡尔积；
3. **包装原语**：`Future.wait` / `ValueListenableBuilder` / `List.unmodifiable` 再包一层；
4. **防御不存在的错误**：为架构上不会抛的回调增加错误通道；
5. **配置矩阵**：同一件事有主题 / 每实例 / 每视图多条定制路径；
6. **文档倒逼 API**：为了解释内部状态，把内部状态提升成公开契约。

同时，仓库里的包并不是同一种接口：多数库包有 barrel，`w_tools_cli` 没有 Dart 公开 API，
根包 `w_tools` 只做重导出。用同一套成员阈值会误伤 CLI、重复计算根包，也会对 ui / core
这类大包过严。

## 决策

1. **有 barrel 的库包按公开类型 / 成员计预算**：patch 不允许新增 / 删除公开 API；
   minor 成员净增不超过 `api_budget.yaml` 的预算；新增公开类型必须写 ADR，并在
   `exceptions` 里指向该 ADR；major 允许删除。
2. **`w_tools_cli` 不数成员**：它的 interface 是子命令、flag、catalog 条目和模板，
   走人工评审；成员计数对它没有意义。
3. **根包 `w_tools` 不参与成员预算**：它只做重导出，计入会重复计算同一 API。
4. **设计红线**：一个用户任务一个入口；不包装原语；状态只有一个真相；构造函数上限
   2 个/类型；主题只在根节点；别名最多活一个 major；没有真实消费者不加 API。
5. **每个公开新增都要过删除测试**：删掉它，哪个用户任务会坏？答不出就不加。
6. **预算例外必须可审计**：新增类型在 `scripts/api_budget.yaml` 登记 `package` / `type` /
   `adr` / `until`；类型进入已发布快照后删除例外。
7. **PR 模板 + 季度审计**：PR 填公开面变化、删除测试、两个消费者；季度审计做一次
   “删除测试 + 合并重复入口 + 收回派生状态”。

## 后果

正向：

- 公开面增长从“凭感觉”变成可执行的数字；
- 新增类型和预算例外留下 ADR 记录，未来能解释“为什么加”；
- CLI / 根包不被错误地套入库包的指标；
- 删除测试把“便利 API”挡在评审前，而不是发布后。

代价 / 已知局限：

- 预算需要按包维护，新增包要同步 `api_budget.yaml`；
- 成员计数是烟雾报警器，不是设计评审：签名变化、可选参数、配置对象仍需人工看；
- 新增类型要写 ADR + 例外，冷启动有一次性成本；
- 例外过期 / 清理需要季度审计兜底。

## 落地结果

- 状态：已完成
- 证据：[`scripts/check_api_budget.py`](../../scripts/check_api_budget.py) 已接入
  `preflight`；[`scripts/api_budget.yaml`](../../scripts/api_budget.yaml) 覆盖 manifest 的
  15 个包（`cli` 为 `mode: tool`）；当前 15 个包全部通过。
- 与决策的偏差：无。根包不在 manifest，按决策 3 不纳入脚本。

## 备选方案

1. **全包固定 `+5/ minor`**：拒绝。ui / core 过大，小包过松，会逼出无意义的豁免。
2. **只靠人工评审**：拒绝。7.0 已经证明“每加一个状态就加一个 API”会自然发生。
3. **把 CLI / 根包也按 Dart 成员计数**：拒绝。CLI 没有 barrel，根包只重导出。
4. **提供 `--force` 绕过预算**：拒绝。例外必须走 ADR + 配置，不能静默跳过。

## 重新评估的条件

- 预算连续多个 minor 误报，导致维护者习惯性加例外；
- 包角色变化（例如 CLI 长出稳定的 Dart API，或根包开始承载逻辑）；
- `api_surface` 的计数口径无法覆盖新的接口形态（例如大量扩展方法 / 宏）。
