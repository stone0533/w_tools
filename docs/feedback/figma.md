# w_tools_figma 反馈

## 待处理

### [待处理] figma: frames --all 缺少收窄手段：真实设计文件输出 6744 行，其中 96% 不是画板

- 包/版本：w_tools_figma 1.1.0（本地检出，待发布），以本地检出代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward，缓存含整份文件 dump 与多页节点树
- 命令 / 输入：`dart run w_tools_figma:figma frames --all`（目的是找画板 id）
- 期望：`--all` 的帮助写的是「连嵌套 FRAME 一起列」，用于找画板。真实设计文件里嵌套 frame 成千上万，需要能把结果收窄到「画板级」（深度 / 尺寸 / 条数任一维度），否则这个开关没法用
- 实际：本项目实测输出 6744 行；按宽度统计只有 327 行的宽度落在 350~400（画板宽度），其余 6416 行是内部布局 frame（例如 `Frame 15801`、`News Item Logo Container`、`News Item Title` 这类容器/元素）。`help frames` 只有 `--file` / `--json` / `--all` / `--name` / `--page` / `--verbose`，没有 `--depth`、`--min-width`、`--limit` 之类收窄手段
- 影响：项目文档 `docs/agents/design-fidelity.md` 明确写「本项目的画板挂在 TABLE/RECTANGLE 容器下，默认 `frames` 会显示（没有 FRAME），直接加 `--all`」——按这个指引执行会得到 6744 行，agent 读这一段既超上下文也找不到目标画板。补充：实测现在默认 `frames` 已能列出 15 条画板（其中有 2 条是嵌套 id），文档那句「默认会（没有 FRAME）」也已过时；但即使更新文档，`--all` 缺少收窄手段仍是缺口
- 建议：①增加 `--depth=<n>` 限制嵌套层级；②或增加 `--min-width=<px>` / 只列「页面宽度级」的画板；③或输出加一列 `depth` 并默认过滤到画板级，让 `--all` 真正可控；④至少在 README 与 `help frames` 里提示「真实设计文件 `--all` 可能有数千行，建议配合 `--name` / `--page`」
- 复现数据：`dart run w_tools_figma:figma frames --all | wc -l` → `6744`；按宽度统计 `awk -F'×' '{if ($1+0>=350 && $1+0<=400) a++; else b++} END {print a, b}'` → `327 6416`；抽样名称包括 `01.1優惠券-已使用`（画板）与 `Frame 15801`、`News Item Logo Container`（布局容器）；`dart run w_tools_figma:figma frames` 默认输出为 15 行
- 状态变更：2026-11-20 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-20 | `fetch nodes --scale=2` 未被拒绝；节点不存在也写缓存并污染索引 | ✅ 1.0.0：显式 `--scale` 一律 exit 2；全 null 不写缓存、不标 corrupt；部分 null 警告并列出缺失 id |
| 2026-11-20 | `spec --node-only` 不带 `--json` 时仍输出完整 markdown | ✅ 1.0.0：`--node-only` 必须配合 `--json`，否则 exit 2 |
| 2026-11-20 | `cache clean` 当前项目无确认，与 `--all` 的 `--yes` 策略不对称 | ✅ 1.0.0：`cache clean` 无论是否 `--all` 都必须带 `--yes`；拒绝时打印当前项目文件数 / 体积 |
| 2026-11-20 | `cache stats` 不区分历史 dump，且只能全删 | ✅ 1.0.0：`cache stats --files` 逐文件列出 bytes / kind / indexed；`cache clean --file=<path>` 可只删点名文件；`nodes-<key>-0-1` 是有效缓存，不自动判 orphan |
| 2026-11-20 | `spec` markdown 缺少子节点 nodeId | ✅ 1.0.0：`spec --with-id` 增加 id 列，默认关闭 |
| 2026-11-20 | `spec` markdown 缺少布局间距 / layoutMode | ✅ 1.0.0：`spec --with-layout` 增加布局列并显示根布局；`diff` 补 layoutMode / 轴对齐 |
| 2026-11-03 | 新旧 token 同时存在时，迁移跳过真 token（保留模板） | ✅ 0.8.0（feccfb1）：新位置是模板、旧位置是真 token 时用真 token 覆盖 |
| 2026-11-03 | 迁移把 `_usage.log` 搬进项目缓存目录，额度历史丢失 | ✅ 0.8.0（feccfb1）：用量并入账号级、`_budget.json` 只在账号级缺失时复制 |
| 2026-11-03 | `cache clean --all` 无确认，误删 59.7 MB 设计缓存 | ✅ 0.9.1（6349e4d）：`--all` 必须带 `--yes` |
| 2026-11-03 | 测试进程写真实额度日志（2 条被污染成 87 条） | ✅ 0.9.0（c6ba2d4）：测试注入 `homeOverride`，`diff_test` 补隔离；再跑测试用量不变 |
| 2026-11-03 | AGENTS 的 Figma 段仍指向 `.figma-token`（0.8.0 已改路径） | ✅ cli 1.9.0（feccfb1）：模板改为 `~/.config/w_tools/figma-token` |
| 2026-11-03 | `cache` / `usage` 帮助没有说明新路径与 `--yes` | ✅ 0.9.2（df77851 / c163022）：帮助与 `docs/figma-cli.md` 同步 |
| 2026-11-03 | `fetch nodes` 无深度限制，单页缓存 129 MB | ✅ 0.10.0（676d28b）：`--depth=<n>`；缓存按深度分文件 |
| 2026-11-02 | 管道截断（`| head`）崩 Broken pipe | ✅ 1.7.2 修复（`cli_io` 捕获 FileSystemException） |
| 2026-11-02 | `--figma` 片段被普通 `init` 静默删掉 | ✅ 1.7.2 修复（`ai.figma` 持久化 + 自动检测） |
| 2026-11-02 | `frames` 输出 4703 行 | ✅ 0.4.0 修好（只列顶层 FRAME，45 行） |
| 2026-11-02 | `diff` 不比位置/布局 | ✅ 0.3.0 修好（position / itemSpacing / padding） |
| 2026-11-02 | `spec` 找不到节点没提示 | ✅ 0.4.0 修好（提示先跑 `frames`） |
| 2026-11-02 | `spec` 不输出 `strokeAlign`（描边内/外） | ✅ 0.5.0：描边列带 `align=INSIDE|OUTSIDE|CENTER` |
| 2026-11-02 | `spec` 不输出节点级 `opacity` | ✅ 0.5.0：新增「透明度」列（`<1` 才显示） |
| 2026-11-02 | `spec` 不输出阴影 `spread` | ✅ 0.5.0：`DROP_SHADOW r=4.0 a=0.08 spread=3.0` |
| 2026-11-02 | `frames` 不显示页面（page）归属 | ✅ 0.5.0：帧列表新增 `page` 列 |
| 2026-11-02 | `tokens --map` 的语义名不在主表里 | ✅ 0.5.0：颜色主表新增「语义名」列 |
| 2026-11-02 | `spec`/`tokens` 默认挑最大缓存文件，多文件时找不到节点 | ✅ 0.6.0 修好（扫描所有缓存、选含目标 nodeId 的文件；找不到时提示 `frames --verbose`） |
| 2026-11-02 | 生成块写死 `^0.3.0`，与项目 pubspec 矛盾 | ✅ CLI 1.7.2 起沿用消费方约束（`figmaInstall`）；1.7.4 起无依赖时只写包名不带版本 |
| 2026-11-20 | `tokens --map` 在 `--json` 下不生效（误报） | ✅ 1.0.0：三组对照实测 `colors[].name` 正常（12 条里 10 条带映射），撤回该条 |
