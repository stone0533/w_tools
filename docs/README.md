# 项目文档

| 目录 | 受众 | 内容 |
|------|------|------|
| [`modules/`](modules/README.md) | 使用者 | 11 个库子包索引、组件目录、依赖矩阵（9 份模块文档 + app_getx/map_google 用包 README） |
| [`agents/`](agents/README.md) | 仓库 AI / 维护者 | 包级首选入口、硬规则、禁止项、工具工作流 |
| [`recipes/`](recipes/README.md) | 使用者 | 跨包组合场景（分页 / 表单提交 / App 根装配…） |
| [`guides/`](guides/README.md) | 使用者 | 横向指南（测试策略等），不绑定单个包 |
| [`migrations/`](migrations/README.md) | 升级用户 | 各包历史版本迁移 |
| 本目录顶层 | 维护者 / agent | 命名规范、接入约定、文档地图、AI 契约、发版流程 |

> 本文件是**文档总索引**：`docs/` 下新增顶层文档、子目录 README 或 ADR 时必须在这里加一行
> （`scripts/check_docs_facts.py` 会检查漏链）。

## 使用者

- [模块文档索引](modules/README.md)：包职责、依赖矩阵、SDK 速查
- [组件目录](modules/components.md)：按用途找现成组件，含「不要用在哪」
- [组合用法](recipes/README.md)：几件事怎么拼起来（分页、表单提交、App 根装配…）
- [使用指南](guides/README.md)：测试策略等横向指南（白盒 / 黑盒 / 设备 / E2E）
- [文档地图](documentation-map.md)：每个文档写什么、AI 应该把信息放哪
- [接入约定](conventions.md)：包 / 暂存层 / 业务层的判定与 doctor 规则
- [新增/修改组件](../CONTRIBUTING.md)：四条硬性要求
- [CLI（init / doctor）](../packages/cli/README.md)
- [Figma agent 使用说明](agents/figma.md)
- [版本迁移索引](migrations/README.md)：升级前先读对应大版本条目

## 维护者 / agent

- [Agent 文档索引](agents/README.md)：各包首选入口、规则页、工具与仓库流程
- [conventions.md](conventions.md)：接入约定与 doctor 的 R1~R9
- [命名规范](naming.md)：包 / 文件 / 类型 / 成员 / 测试的命名规则与存量例外（唯一事实源）
- [AI 使用契约](ai-contract.md)：catalog / explain / AGENTS 四层、更新流程、完整性边界
- [维护者 AI 提示词](ai-maintainer-prompts.md)：按场景（A~N）复制
- [使用反馈](feedback/README.md)：消费方问题汇总与闭环状态（`docs/feedback/<包>.md`）
- [releasing.md](releasing.md)：发版流程、`publish_package.sh`、版本规则
- [scripts 运行手册](../scripts/README.md)：门禁清单的唯一来源（何时跑哪个脚本）

## 架构决策（ADR）

- [ADR 索引与模板](adr/README.md)：按主题分组的索引、状态词、模板、新增/取代规则
- [0001 子包独立版本](adr/0001-package-versioning.md)：独立 semver、不回滚（操作规则见 releasing.md）
- [0002 依赖子包而非聚合包](adr/0002-consumers-depend-on-subpackages.md)：消费方直接依赖子包
- [0003 子包排版不依赖 ui](adr/0003-subpackage-typography-without-ui.md)：用 `ThemeData.textTheme` 共享排版
- [0004 组件 config 模型](adr/0004-component-config-model.md)：Config 的边界与直接字段
- [0005 App options 与插件归属](adr/0005-app-options-and-plugin-ownership.md)：`WAppOptions` / `WAppPlugin` 的职责划分
- [0006 包拓扑](adr/0006-package-topology.md)：独立库包 + 契约/实现对，根包只聚合基础子包
- [0007 组件命名约定](adr/0007-component-naming-roles.md)：命名收敛为角色判断（规则正文见 naming.md）

## 评审记录

带日期的历史分析，**不是当前事实源**：

- [2026-11-03 修复路线图](analysis/2026-11-03-remediation-plan.md)
- [2026-11-06 文档 / 脚本体系审计](analysis/2026-11-06-docs-scripts-audit.md)
- [2026-11-06 UI 子包使用示例与选型分析](analysis/2026-11-06-ui-usage-examples.md)
- [2026-11-07 全流程审计：改动 → 门禁 → PR → 发布](analysis/2026-11-07-process-audit.md)
- [2026-11-07 全流程二轮审计：门禁假绿与发布断点](analysis/2026-11-07-process-audit-round2.md)

改完 `docs/` 后跑：

```bash
bash scripts/check_docs.sh
```
