# form 自定义校验：处理方案与提示词

> 背景：`w_tools_form` 8.0.0 删除了 `WFormCustomValidator`（[PR #234](https://github.com/stone0533/w_tools/pull/234)），
> 自定义校验能力本身没有丢失：字段 `validator:` 直接接收 `FormFieldValidator`，空值以 `null` 传入。
> 本文记录「不改公开 API、先补教学与迁移说明」这一处理方案（对应分析里的 P0），以及执行用的提示词。
> 历史分析，不是当前事实源。

## 固定前缀（同 `docs/ai-maintainer-prompts.md` §0）

```text
你是 w_tools 的维护者，先读 docs/ai-contract.md、AGENTS.md 和
packages/<pkg>/README.md（存在时），再开始；改具体包时按 docs/agents/README.md 的索引
读规则页（app_getx → app.md、map_google → map.md、device / e2e → device-testing.md）；
新增 / 修改公开类型时，
再读 CONTRIBUTING.md 与 docs/naming.md。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 命令在正确目录跑：`dart run tool/*`、`dart test test/*` 只在 `packages/cli` 下成立；
   `scripts/*.sh` 会自己 cd 到仓库根。贴命令时带上 cd，别让下一个人复现失败。
7. 不要改无关包、无关文档、无关测试。
8. 默认只改工作区：不要 commit / push / 开 PR / 合并，除非任务块明确要求（如 K-2 / K-2M）；
   不要用 `git reset --hard` / `git clean` 清理未提交内容。
9. 公开变化：抬子包版本 + 在当前版本 CHANGELOG 段写变更；所有库子包都要同步
   `packages/cli/lib/src/init/versions.dart` 的 `subpackageConstraints`（工具包
   cli / figma / device / e2e 除外），聚合子包（core / async / ui / form / api / toast）
   还要抬根 pubspec 的 `^x.y.z` 下界 —— `check_versions.py` 要求下界 == 当前版本。
   根 pubspec 变了但根包版本没抬时，根 `CHANGELOG.md` 必须有非空 `## Unreleased`
   （CI 的 check_pr_scope 强制，K-2 折叠成版本段）。
   PR 正文保留「## 改动类型」段并至少勾选一项；勾了公开类别（公开变化 / 删除废弃 / 新增包）时，
   每个改了公开代码的包都要改自己的 CHANGELOG（空 body 也会失败）。
10. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

## 任务块（场景 F：只整理 catalog / 文档）

```text
任务：为 form 8.0.0 的「自定义校验」补教学与迁移说明，不恢复 WFormCustomValidator、不改公开 API。

要求：
1. docs/migrations/form-8.0.md §4 补：
   - 旧 API 只是把函数包成 FormFieldValidator，并绕开 BaseValidator 的空值短路；
     直接闭包等价，value 可能是 null，必填规则要自己判。
   - 移除 form_builder_validators 依赖的连带影响：消费方若直接 import 该包，需要自己加依赖。
   - 字段级 / 表单级（WFormValidatorItem.field、validatorBuilder）两种写法与可复用规则示例。
2. packages/form/README.md 增加「自定义校验」小节（字段闭包、可复用函数、组合、表单级、异步）。
3. docs/modules/form_module.md §7 增加自定义校验说明；docs/agents/form.md 补一条路由。
4. catalog 只加正向指引（WFormTextField pitfalls / WFormValidatorItem pitfalls），不提旧名时
   必须写「8.0 已删除」；跑 gen_catalog.dart，不手改生成物。
5. catalog 属于 CLI 公开教学资产：抬 CLI patch 版本 + CHANGELOG + version.dart / versions.dart。
6. 跑 check_docs / check_removed_api / check_public_catalog / preflight --changed。
7. 报告 changed files、命令结果、explain 输出、剩余风险。
```

## 执行范围

- 不恢复 `WFormCustomValidator`（无真实需求；恢复需要 form 8.1.0 + root/CLI 连锁发布）。
- 文档 + catalog + CLI 1.22.1；`w_tools_form` 不改代码、不发布（等下次 form 版本带上 README）。
- 项目侧的处理方式：字段 `validator:` 闭包；可复用规则放项目 `AppValidators`；
  表单级动态规则用 `WFormValidatorItem(fieldName:, validatorBuilder:)`；
  复用字段强类型 validator 用 `WFormValidatorItem.field(name)`。

状态：完成（2026-11-14）。
