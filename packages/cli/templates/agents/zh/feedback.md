## 使用反馈（默认关闭）

用 `w_tools_*` 撞到问题、或对能力有改进建议：**先查重；默认不提交，只有项目显式开启时才发。**

### 第一步：看项目是否开启

只有 `.w_tools_doctor.yaml` 里：

```yaml
feedback:
  enabled: true
```

才允许提交（旧键 `issue: true` 仍兼容）。没有这段配置（或为 false）→ **什么都不做**：
不写文件、不生成链接、不建 Issue；也不要加 `--issue` 试图绕过 —— 未开启时它会直接报错（exit 2）。

### 已开启时：本地台账优先

1. **查重**

   ```bash
   dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>
   ```

   本机有 w_tools 台账就搜台账；没有台账时加 `--gh` 搜 GitHub issues
   （`gh` 未安装 / 未登录会退出 3）。

2. **写正文**（字段固定，缺字段会被拒绝；可先运行
   `dart run w_tools_cli:w_tools feedback submit --template` 打印骨架）

   ```md
   - 包/版本：
   - 环境：
   - 命令 / 输入：
   - 期望：
   - 实际：
   - 影响：
   - 建议：
   - 复现数据：
   ```

   保存为 `/tmp/w_tools_feedback.md`。

3. **提交（默认路由：本地台账 → Issue）**

   ```bash
   dart run w_tools_cli:w_tools feedback submit \
     --package=<包> --title="<一句话现象>" --body-file=/tmp/w_tools_feedback.md
   ```

   - 本机有 w_tools 仓库检出（path / git 依赖）→ 写进该仓库 `docs/feedback/`，**不会建 Issue**；
   - 仓库 clone 在别处、依赖里解析不到 → 让项目加 `feedback.ledger: <仓库路径>`（相对项目根或绝对路径）；
   - 本机没有 w_tools 仓库 → 建 GitHub Issue（需已安装 `gh`；gh 读取 `GH_TOKEN` / `GITHUB_TOKEN`，或用 `gh auth login`）；
   - 两条都不成立 → 跳过并 **exit 4**，什么都没写；
   - 本机有台账、又确实要公开提 issue 时才加 `--issue`；`--ledger` 强制只写本地台账；
   - 公开 Issue 每个项目每天最多 5 条（`feedback.max_issues_per_day`，0 = 不限）；额度用完会 exit 2，
     本地台账不占额度。

### 边界

- 一次会话最多 3–5 条，只记**真正卡住你**的；
- 状态只写 `待处理`，**不要自己标「已修复」**；
- Issue 是公开的：不要贴密钥 / token / 业务敏感数据，日志先脱敏；
- 写本机台账会让 w_tools 工作区变脏：提交后提醒我 commit / discard，不要自己顺手提交别人的仓库；
- 不要把反馈写进业务代码或 `.w_tools/`；
- 维护者 triage 后才进入 `w_tools/docs/feedback/<包>.md`。
