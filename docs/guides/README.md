# 使用指南（Guides）

这里放**面向使用方的横向指南**：不绑定某一个包，也不是「几个包怎么拼」，而是「一类事情该怎么做」。

| 目录 | 回答的问题 |
|---|---|
| [`docs/modules/`](../modules/README.md) | 这个包有哪些 API、怎么用 |
| [`docs/recipes/`](../recipes/README.md) | 几个包怎么拼起来（分页、表单提交、根装配） |
| **`docs/guides/`** | 一类工程问题怎么做（测试策略、迁移、性能…） |

## 索引

- [Flutter 项目测试策略：白盒 / 黑盒](testing.md)：测试金字塔、widget / 集成测试、
  `w_tools_device` 设备黑盒、`w_tools_e2e` 免登录、CI 建议与反模式

> 新增指南时：文件放本目录，并在上表加一行；`docs/README.md` 不需要逐个列出，
> 只索引本文件（`scripts/check_docs_facts.py` 会检查索引完整性）。
