# w_tools_figma 反馈

## 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-20 | `spec` 不输出 `rectangleCornerRadii` | ✅ 1.1.0：圆角列优先逐角输出，0 也显示 |
| 2026-11-20 | `spec` / `tokens` 忽略 paint 级 opacity | ✅ 1.1.0：`figmaPaintHex` 乘 paint opacity；spec/tokens/diff 都生效 |
| 2026-11-20 | `spec` 缺 rotation / isMask / clipsContent / 阴影颜色 / decoration / 渐变 | ✅ 1.1.0：补这些属性；渐变输出首尾色 + 角度 |
| 2026-11-20 | `diff` 漏 rotation / isMask / clipsContent / decoration | ✅ 1.1.0：`SpecDiff` 增加对应字段及 paint opacity |
| 2026-11-20 | `spec` / `tokens` 选旧完整缓存而非新 depth 缓存 | ✅ 1.1.0：取最新缓存；depth 命中时提示子节点可能缺失 |
| 2026-11-20 | `frames --name` 只查顶层，嵌套命中静默空 | ✅ 1.1.0：`--name` / `--page` 搜索全部 FRAME（含嵌套） |
| 2026-11-20 | 子目录运行换项目缓存 id | ✅ 1.1.0：默认向上找 `pubspec.yaml` / `.git`；错误带 cache 路径 |
| 2026-11-20 | `/meta` 不读 `last_touched_at` | ✅ 1.1.0：支持 snake_case + camelCase fallback |
| 2026-11-20 | `fetch` 只按整串 ids 命中；损坏/部分缺失 | ✅ 1.1.0：按单 id 合并缓存；损坏报错；`missingNodeIds` 持久化并在命中时返回 |
| 2026-11-20 | `usage` limit=1 时 0 次也报警 | ✅ 1.1.0：阈值改为 `used > 0` 且按比例判断 |
| 2026-11-20 | `cache clean --file=./x` 误判；`--all` 只统计当前项目 | ✅ 1.1.0：路径规范化；`--all` 统计所有项目 |
| 2026-11-20 | `frames` 中文列错位 / 无拉取时间 / 错误无路径 | ✅ 1.1.0：显示宽度补齐；JSON/verbose 带 `fetchedAt`；错误带路径 |
| 2026-11-20 | `tokens` 样例不可定位 / 绝对路径 / `--min` 文案 | ✅ 1.1.0：samples 带 nodeId；数据源相对/文件名；文案修正 |
| 2026-11-20 | `diff` 首次无基线输出「没有变化」 | ✅ 1.1.0：`baselineCreated` / `firstBaseline`；文本输出已建立基线 |
| 2026-11-20 | `spec` / `tokens` Markdown 未转义 / runs 逐字符 | ✅ 1.1.0：转义 `|` / 换行；runs 合并区间；text 分隔改 ` · ` |
| 2026-11-20 | `frames --all` 缺少收窄手段，真实文件输出 6744 行 | ✅ 1.1.0（commit f042640d）：新增 `frames --depth` / `--limit`；`frames/1` 增加 `total` / `truncated` / `depth`；`--all` 可限深度或条数 |
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
