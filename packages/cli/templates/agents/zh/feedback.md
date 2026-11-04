## 使用反馈（给 AI）

用 `w_tools_*` 撞到问题、或对能力有改进建议：**先查重，再提交，不要改库**。

### 什么算反馈

- 文档 / 示例照抄不能编译，或行为与文档不一致
- API 缺能力，导致你重复写 workaround
- 规则 / 组件明显不适配真实页面（不是个人风格偏好）

### 三步

1. **查重**

   ```bash
   dart run w_tools_cli:feedback search "<关键词>" --package=<包>
   # 有 gh 登录时可加 --gh 同时搜 GitHub issues
   ```

2. **写正文**（按 `docs/feedback/TEMPLATE.md` 的字段，存到临时文件；也可 `--stdin`）

3. **提交**

   ```bash
   dart run w_tools_cli:feedback submit \
     --package=<包> --title="<一句话现象>" --body-file=/tmp/feedback.md
   ```

   - 默认：打印 GitHub 预填 issue 链接，**不会自动上传**；
   - `--gh`：直接 `gh issue create`（需已登录）；
   - 离线：`--local` 写入本地 `docs/agents/feedback.md`，之后手动提交。

### 边界

- 状态只写 `待处理`；**不要自己标「已修复」**（版本号由维护者发布后补）；
- 一次会话最多 3–5 条，只记**真正卡住你**的；
- 不要把反馈写进业务代码或 `.w_tools/`；
- 维护者 triage 后才进入 `w_tools/docs/feedback/<包>.md`（唯一真相）。
