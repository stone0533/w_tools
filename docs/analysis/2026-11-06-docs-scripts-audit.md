> 分析记录：带日期的历史评审，不代表当前状态。

# 文档 / 脚本体系审计（2026-11-06）

> 范围：根 `README.md`、`AGENTS.md`、`CONTRIBUTING.md`、`docs/`、`scripts/`。
> 目标：判断这套「文档 + 门禁」体系是否合理、准确、有效、高效，并修掉能在本轮闭合的问题。
> 基线 `main @ 2c7a155`，审计时工作区干净。

## 结论

| 维度 | 评价 | 依据 |
| --- | --- | --- |
| 合理 | 较好 | 单一事实源 + 生成物 + `preflight` 单入口 + CI 同源校验，骨架成立；问题是规则散在三层文档、门禁清单实际有三份 |
| 准确 | 一般 | 根 README 有 5 处硬伤，且它恰好是唯一没被符号检查覆盖的主入口 |
| 有效 | 一般偏好 | 门禁拦过真实回归（CI 注释有记录），但存在若干「全绿但内容已错」的盲区 |
| 高效 | 中等 | 门禁本身很快（`check_docs` 约 1.1s，静态 `preflight` 约 2.4s）；成本在维护重复内容，不在跑检查 |

## 当时发现并已修

| 问题 | 处理 |
| --- | --- |
| `README` 写「基于 Config 开发」/「`WConfig` 已弃用」 | 改成子包拆分表述；`WConfig` 标注为 3.0 已删除 |
| `README` 配置示例重复赋值，且 `WFormIcons.check` 不存在 | 改成 `WFormTheme(icons: WFormIcons.defaults.copyWith(...))` |
| `README` 安装示例 `w_tools: ^7.0.0`（实际 9.x） | 改为当前约束，并加 caret 校验 |
| `CONTRIBUTING` / `docs/modules/README.md` 要求手改 `components.md` | 改成「改 catalog 源 + 跑生成器」 |
| 统计数字过期（8 个子包 / 13 个空文件） | 改为 6 个 / 不写死包数 |
| `docs/feedback/README.md` 内部矛盾（默认写这里 vs 消费方不要写） | 明确「仓库检出内直接写；消费方本地缓冲」 |
| 删除流程没要求登记 removed API 名单 | 写进 `AGENTS.md` / `docs/ai-contract.md` §7 / 脚本注释 |

## 本轮补的门禁

1. `check_doc_symbols.py` 纳入根 `README.md`（此前只扫 `AGENTS.md` 与子包 README）。
2. `check_package_docs.py` 校验根 README 的 `w_tools*: ^x.y.z`（caret 语义）。
3. `preflight.sh` 增加 `gen_catalog --check` / `gen_templates --check`（此前只在 `--with-tests` 的 CLI 测试里兜底）。
4. `check_docs_versions.py` 补「已发布 x.y.z」语序；`release_check.sh` 的 README 提示不再暗示所有版本都已被校验。
5. 顺手修了 `preflight.sh --help` 会打印 `set -uo pipefail` 的问题。

反向验证：临时把根 README 改回 `^7.0.0` 与 `WFormIcons.check`，两条新门禁分别报错后恢复。

## 同日后续（2026-11-06）

- 根包已备好 9.0.2：4 条 caret 下界抬到已发布的 patch；`release_check --strict` 开始把「下界落后」判成失败（日常 preflight 仍只提醒）。
- `AGENTS.md` 的「先读」改为任务路由表；维护者提示词手册标注为「给人」。
- `preflight.sh` 增加 `--package <pkg>`；CI 增加 `changes` job，纯文档改动不再跑 16 个装 Flutter 的 job。
- 新增 `check_docs_duplicates.py`（modules 与包 README 的重复示例）并接入 `check_docs`；`check_agents_consistency.py` 增加「入口符号必须出现在 AGENTS.md」。
- **发布完成（2026-11-06）**：`w_tools_app_getx 1.0.1` 与 `w_tools 9.0.2` 已上线，
  `release_check --online` 16 个包全部 `✓`、0 提醒。当时本机到 pub.dev 上传端点不可达
  （`Uploading...` 卡在 `SYN_SENT`），最终在网络可达的环境完成发布。

## 未闭环（审计当时，保留为历史）

- 根包 4 条 caret 下界低于子包当前版本（`core` / `async` / `ui` / `form`）：要抬约束并配根包发版，不能混在文档修复里。
- `docs/releasing.md` 把「下界取子包当前版本」写成硬要求，但 `release_check` 只给提醒：要么抬版本，要么把文档改成建议。
- 规则存在三份副本（`AGENTS.md` / `docs/agents/` / `packages/cli/templates/agents/`），目前只校验入口名，不校验语义。
- `AGENTS.md` 的「先读」包含 1,223 行维护者提示词手册；对写代码的 agent 过重。
- `docs/modules/*.md` 与 `packages/*/README.md` 职责重叠，同一事实两处手写。
- CI 没有 `paths` 过滤，纯文档改动也会起约 18 个 job；本地 `preflight --with-tests` 串行跑 15 个包。

## 审计方法

```bash
bash scripts/check_docs.sh
bash scripts/preflight.sh
cd packages/cli && dart run tool/gen_catalog.dart --check
cd packages/cli && dart run tool/gen_templates.dart --check
python3 scripts/ci_matrix.py --check
```

`flutter analyze` 在审计环境里因无法写 Flutter engine cache（`Operation not permitted`）失败，未计入仓库缺陷；
完整测试套件也未在该环境执行。

## 同日修复（第二轮）

- **链接门禁**：`check_docs.sh` 的 python 输出补尾换行，读取循环加 `|| [ -n "$line" ]`。
  此前「恰好一条坏链」会被整步吞掉；反向验证：只加一条坏链现在会失败。顺带修了 ADR-0004
  指向 `../scripts/naming_baseline.yaml` 的坏链（应为 `../../scripts/...`）。
- **CI 覆盖**：`docs` job 增加 `release_check.sh`（只改 CHANGELOG 的 PR 也校验版本 / 物料）；
  `static` 过滤加入 `docs/feedback/**`（反馈台账不再只在本地校验）；`umbrella` 显式安装 PyYAML。
- **退出码契约**：`check_feedback.sh` 的 `Unhandled exception` / `FileSystemException` 归 1（真失败），
  exit 2 只留「dart 起不来 / 包未解析」。
- **manifest 同源**：`root_aggregate` 列真正生效 —— `release_check.sh` 按列判断是否聚合，
  `ci_matrix.py --check` 校验取值并与根 pubspec 依赖双向对齐。
- **脚本健壮性**：`check_removed_api` 修 `WApp()` 死正则并补登 `WRow` / `WAsync*` / `WRegExp*` /
  `WTextConfig`；`check_doc_symbols` 的 import 边界改为 barrel 粒度、拒绝未导出内部类型、
  纳入 `packages/*/AGENTS.md`；`check_package_docs` 拒绝非 caret 写法；`check_prompt_docs` flag
  改为整 token；`check_public_catalog` 回收失效基线；`check_style_literals` /
  `check_docs_duplicates` / `check_docs_snippets` 不再「零输入即通过」；`check_agents_consistency`
  遇到悬空链接不再崩溃。
- **文档事实**：根 README（`WRichText` / `WFormFieldButton` / 配置驱动 / 错字）、`example/README`
  的聚合范围、`modules/README` 的 figma 依赖与 SDK 表、`CONTRIBUTING` 的 toast 反例、
  `docs/agents/cli.md` 的旧命令形式；zh async 模板补上 `WAsyncPagedController`。

仍未覆盖：`check_doc_symbols` 只扫代码块，正文 / 行内 `` `WXxx` `` 的旧名字不在门禁内
（`WRichText` 这类就是从这里漏掉的）；`check_agents_consistency` 只比 6 组高频短语，规则语义仍靠 review。
