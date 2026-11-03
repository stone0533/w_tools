## 使用反馈（给 AI）

用 `w_tools_*` 撞到问题、或某条规则不合用时：**记下来，不要改库**。

1. **先查重**：本项目 `docs/agents/feedback.md`（没有就跳过）。
   有 w_tools 仓库时再查库侧，先拿路径：

   ```bash
   dart run w_tools_cli:context --format=json | python3 -c \
     "import json,sys; print(json.load(sys.stdin)['install']['feedbackDir'] or '')"
   ```

   输出为空 = 当前不是仓库检出（如 pub cache），**只写本地收件箱**。
2. **追加一条**到 `docs/agents/feedback.md`（文件不存在就新建，第一行写
   `# w_tools 使用反馈（本地收件箱）`）：

   ```md
   ### [待处理] <包>: <一句话现象>
   - 包/版本：
   - 环境：
   - 命令 / 输入：
   - 期望：
   - 实际：
   - 影响（我因此做错了什么 / 多花了什么）：
   - 建议：
   - 复现数据：
   ```

3. 状态只写 `待处理`；**不要自己标「已修复」**（版本号由库维护者发布后补）。
4. 一次会话最多 3–5 条，只记**真正卡住你**的；「我觉得可以更好」不算。
5. 维护者会把条目同步到 `w_tools/docs/feedback/<包>.md`（**唯一真相**，含状态与版本）。
   反馈是知识产物，放 `docs/`；不要放 `.w_tools/`（那是机器本地状态）。
