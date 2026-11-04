## 使用反馈（默认关闭）

用 `w_tools_*` 撞到问题、或对能力有改进建议：**先查重；默认不提交，只有项目显式开启时才发。**

### 第一步：看项目是否开启

只有 `.w_tools_doctor.yaml` 里：

```yaml
feedback:
  issue: true
```

才允许创建 GitHub Issue。没有这个配置（或为 false）→ **什么都不做**，不要写本地文件、不要打开链接。

### 已开启时

1. **查重**

   ```bash
   dart run w_tools_cli:feedback search "<关键词>" --package=<包>
   ```

2. **写正文**（字段固定，缺字段会被拒绝；可先运行
   `dart run w_tools_cli:feedback submit --template` 打印骨架）

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

3. **提交**（`--issue` 可显式覆盖配置）

   ```bash
   dart run w_tools_cli:feedback submit \
     --package=<包> --title="<一句话现象>" --body-file=/tmp/w_tools_feedback.md --issue
   ```

   - 需要已安装 `gh`；gh 会读取 `GH_TOKEN` / `GITHUB_TOKEN`，或使用 `gh auth login`；
   - 提交成功会输出 issue URL；失败会明确报错，不生成人工链接。

### 边界

- 一次会话最多 3–5 条，只记**真正卡住你**的；
- 状态只写 `待处理`，**不要自己标「已修复」**；
- 不要把反馈写进业务代码或 `.w_tools/`；
- 维护者 triage 后才进入 `w_tools/docs/feedback/<包>.md`。
