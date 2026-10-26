# 项目文档

| 目录 | 受众 | 内容 |
|------|------|------|
| [`modules/`](modules/README.md) | 使用者 | 8 个 Flutter 子包的模块文档、组件目录、依赖矩阵 |
| 本目录顶层 | 维护者 / agent | 接入约定、发版流程、ADR、agent 指令 |

## 使用者

- [模块文档索引](modules/README.md)：包职责、依赖矩阵、SDK 速查
- [组件目录](modules/components.md)：按用途找现成组件，含「不要用在哪」
- [接入约定](conventions.md)：包 / 暂存层 / 业务层的判定与 doctor 规则
- [新增/修改组件](../CONTRIBUTING.md)：四条硬性要求
- [CLI（init / doctor）](../packages/cli/README.md)

## 维护者 / agent

- [conventions.md](conventions.md)：接入约定与 doctor 的 R1~R8
- [releasing.md](releasing.md)：发版流程、`publish_package.sh`、版本规则
- [adr/0001-package-versioning.md](adr/0001-package-versioning.md)：子包独立版本与 semver
- [adr/0002-consumers-depend-on-subpackages.md](adr/0002-consumers-depend-on-subpackages.md)：依赖子包而非聚合包
- [agents/](agents/)：issue tracker、triage labels、domain docs

改完 `docs/` 后跑：

```bash
bash scripts/check_docs.sh
```
