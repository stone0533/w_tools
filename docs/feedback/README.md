# 使用反馈（库侧）

消费方用 `w_tools_*` 撞到的问题在这里汇总、定状态 —— **这里是唯一真相**。
默认**直接写这里**；只有拿不到本仓库时，才在消费方建本地日志做缓冲（事后同步进来）。

## 规则

1. **有反馈才建文件**：`docs/feedback/<包>.md`，没有反馈的包不要建空文件。
2. **消费方只追加 `待处理`**；`已确认` / `已修复` / `不修` 由维护者写。
3. `已修复` **必须带版本号**（最好再带 commit）；只写「修好了」等于没修。
4. 确认后**必须链 issue**（GitHub / GitLab），反馈日志不替代 issue tracker。
5. 已闭环条目压成表格一行，细节留在 CHANGELOG，**不做第二份 CHANGELOG**。
6. `待处理` 超过 30 天没动 → 标 `stale`（CI 会提示）。

## 目录约定

| 位置 | 放什么 |
| --- | --- |
| `docs/feedback/` | 反馈记录（**人读、需评审、不可再生成**） |
| `.w_tools/`（消费方项目） | 工具状态（manifest / 缓存，**删了能重建**） |

> 一句话：**`.w_tools/` 只放「删了能重建」的东西；反馈进 `docs/`。**

## 状态机

```
待处理 ──(维护者确认)──> 已确认(链 issue) ──(发布)──> 已修复(版本 + commit)
   └────────(不修)────> 不修(必须写理由)
```

## 怎么用（消费方）

> 装了 `w_tools_cli` 的项目，`init` 会把这段流程写进 AGENTS（「使用反馈（给 AI）」一节），
> 新项目不用手抄；默认不提交，只有项目显式开启 `feedback.issue` 才建 Issue。

**默认策略：本地台账优先；Issue 默认关闭；都不满足就跳过。**

- 在 w_tools 仓库检出内：`feedback submit` 自动写 `docs/feedback/<包>.md` 并更新索引；
- 消费方：只有 `.w_tools_doctor.yaml` 的 `feedback.issue: true` 时才创建 Issue；
- 没有本地台账且 Issue 未开启：**什么都不做**（不写本地收件箱、不生成链接）。

```bash
# 仓库内：直接维护台账
dart run w_tools_cli:w_tools feedback submit \
  --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md --ledger --linked-issue=123

# 消费方（已开启 feedback.issue）：
dart run w_tools_cli:w_tools feedback submit \
  --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md --issue
```

- `submit` 会校验必填字段；缺字段退出 2；
- `--issue` 需要已安装 `gh`；gh 会读取 `GH_TOKEN` / `GITHUB_TOKEN`，或使用 `gh auth login`；失败会明确报错；
- 维护者 triage 后才把外部 issue 写入台账；消费方不要直接改 `docs/feedback/`；
- Issue 模板：`.github/ISSUE_TEMPLATE/feedback.md`。

## 怎么用（维护者）

```bash
# 0. 在仓库内直接追加一条（自动建档 / 更新索引）
dart run w_tools_cli:w_tools feedback submit \
  --package=<包> --title="<一句话>" --body-file=/tmp/feedback.md --ledger --linked-issue=123

# 1. 看待处理
grep -rn "\[待处理\]" docs/feedback/

# 2. triage：改成 [已确认] + 链 issue，或 [不修] + 理由；补「状态变更：<日期> ...」

# 3. 修复发版后闭环：
#    条目补「状态变更：… 已修复（x.y.z，commit abc123）」
#    挪进该包「## 已闭环」表格（一行）
#    CHANGELOG 对应版本写一句（细节只写这里）
#    同步 docs/feedback/README.md 索引表的待处理数量

# 4. 提交前自检（CI 也会跑）
bash scripts/check_feedback.sh
```

## 一条反馈的完整生命周期

```md
# ① 消费方写（docs/feedback/figma.md）
### [待处理] figma: cache clean --all 没有确认，误删 59.7 MB 缓存
- 包/版本：w_tools_figma 0.9.0
- 环境：macOS 27.2 / Flutter 3.44
- 命令 / 输入：dart run w_tools_figma:figma cache clean --all
- 期望：破坏性操作需要确认
- 实际：直接删除，退出码 0
- 影响：重建缓存消耗 3 次 Figma 额度
- 建议：--all 必须配 --yes
- 复现数据：cache stats 显示 132.4 MB → 0
- 状态变更：2026-11-03 待处理

# ② 维护者确认后
- 状态变更：2026-11-03 已确认 → #46

# ③ 修复发版后：挪进已闭环表，只留一行
| 2026-11-03 | `cache clean --all` 无确认 | ✅ 0.9.1（6349e4d）：`--all` 必须带 `--yes` |
```

## 索引

| 包 | 待处理 | 最近更新 |
| --- | --- | --- |
| [figma](figma.md) | 0 | 2026-11-03 |
| [cli](cli.md) | 0 | 2026-11-03 |
| [device](device.md) | 0 | 2026-11-03 |
| [e2e](e2e.md) | 0 | 2026-11-04 |
| [api](api.md) | 0 | 2026-11-04 |
| [async](async.md) | 0 | 2026-11-04 |
| [map](map.md) | 0 | 2026-11-04 |
| [qr](qr.md) | 0 | 2026-11-04 |
| [ui](ui.md) | 2 | 2026-11-04 |

新增条目时**同步这张表**（CI 会核对数量）。未列出的包（core/ui/form/toast/app）首次用 `feedback submit --ledger` 建档时自动补索引；
消费方用默认 issue 入口，不要直接改这张表。

## 模板

复制 [TEMPLATE.md](TEMPLATE.md) 里的一段，按字段填。
