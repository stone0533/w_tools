# w_tools_figma 反馈

## 待处理

### [待处理] figma: stale / depth 提示未按 fileKey 过滤，可能指向别的 Figma 文件

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 / Dart 3.12.2；同一项目里同时缓存 FILEA 完整树与 FILEB 的 `-d2` 树（node id 都是 `10:1`）
- 命令 / 输入：`dart run w_tools_figma:figma tokens 10:1 --json --skip-markdown`；`dart run w_tools_figma:figma tokens 10:1 --allow-depth --json --skip-markdown`；`dart run w_tools_figma:figma spec 10:1 --json`
- 期望：stale 检查和 depth 警告只引用同一 fileKey 的缓存；同一 nodeId 出现在多个文件时，保留 multiFileKey 警告并让用户用 `--file=` 指定，不要把 FILEB 的 dN 当成 FILEA 完整缓存的新版本，也不要把 FILEA 完整缓存推荐给 FILEB 的 dN
- 实际：默认选 FILEA 完整树时，JSON 输出 `staleAgainstDepth:true`、`newerDepthAvailable:[{"nodeId":"10:1","source":"…/nodes-FILEB-10-1-d2.json","depth":2,"version":"300"}]`；stderr 写「完整缓存可能陈旧：FILEA full → FILEB d2」。反过来 `--allow-depth` 选中 FILEB dN 时，depth 警告的「可用完整缓存」列出 FILEA full。`staleDepthReport` / `fullNodesCachePaths` 都有 `fileKey` 参数，但 spec/tokens 调用时没传，`_nodesCacheFiles` 扫描了所有 fileKey。
- 影响：主设计稿和组件库/活动页共用 node id（尤其 `0:1`）时，默认完整树会被另一文件的 dN 误标成陈旧，或 dN 警告推荐另一文件的完整缓存；agent 可能按 `newerDepthAvailable.source` / 推荐路径刷新错的文件，或改用不完整的 dN。multiFileKey 警告只说「可能选错文件」，没有解释这些字段来自另一文件。
- 建议：从选中的缓存文件名解析 `nodes-<fileKey>-`，把该 fileKey 传给 staleDepthReport / fullNodesCachePaths；只比较同一 fileKey 的 dN / 完整缓存；无法确定时跳过 stale 检查并保留 multiFileKey 警告。
- 复现数据：合成缓存 `nodes-FILEA-10-1.json`（version 100，完整）+ `nodes-FILEB-10-1-d2.json`（version 300，nodeId 10:1）；默认 tokens 的 `staleAgainstDepth:true` + `newerDepthAvailable.source` 指向 FILEB；`--allow-depth` 选 FILEB dN 时 warning 的可用完整缓存指向 FILEA；stderr 原文如上。
- 状态变更：2026-11-21 待处理

## 已闭环



| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-21 | 完整缓存 vs dN 的陈旧判断按 mtime 误报，JSON 也没有对应标记 | ✅ 1.3.0：按 version → lastModified → mtime；JSON staleAgainstDepth / newerDepthAvailable；同 version 不再误报 |
| 2026-11-21 | spec/tokens 默认仍选中 depth 裁剪缓存（JSON 已可发现，--prefer-full 为 opt-in） | ✅ 1.3.0：默认优先完整树，`--allow-depth` 才读 dN；JSON `depthLimited` / `sourceDepth(s)` 保留 |
| 2026-11-21 | tokens --out / spec stdout 把含本机绝对路径的 depth 警告写进 markdown | ✅ 1.3.0：depth 警告只写 stderr；`spec` stdout / `tokens --out` 文件不再含本机路径 |
| 2026-11-21 | 缓存结构异常时未捕获异常，exit 255 | ✅ 1.3.0：individualStrokeWeights 空 key 跳过；run.dart 兜底 Error，坏缓存 exit 1 |
| 2026-11-21 | init 无法恢复只剩注释的 token 文件 | ✅ 1.3.0：init 按「无有效 token 行」重建；--force 不再误报 |
| 2026-11-21 | cache clean --file 拒绝同一文件的 /tmp 路径 | ✅ 1.3.0：先解析软链再比较；/tmp 与 /private/tmp 均可，越界软链仍拒 |
| 2026-11-21 | spec/tokens --file=<dN> warning 误报没有完整缓存 | ✅ 1.3.0：显式 --file 也检查完整缓存并排除当前文件 |
| 2026-11-21 | init 生成的 token 模板填完后仍被判非法，首次本地配置必失败 | ✅ 1.3.0：readToken 取第一条非注释行；空文件重建；已存在 token 收紧到 600（仅注释文件另见新条目） |
| 2026-11-21 | --root 未规范化，等价路径落到不同缓存目录 | ✅ 1.3.0：canonicalDirectory 归一 `.` / `./` / 软链 / 尾斜杠；空/不存在 exit 2；选项前置提示（cache clean --file 回归另见新条目） |
| 2026-11-21 | spec 的 --skip-hidden / --skip-name-prefix 只过滤 Markdown | ✅ 1.3.0：node 与 markdown 同步剪枝，目标及祖先保留 |
| 2026-11-21 | spec 对 CANVAS/TEXT 根节点语义错误 | ✅ 1.3.0：CANVAS 按页面标题/子树输出；TEXT 标文字色 |
| 2026-11-21 | rich text 输出错误（spec 空字号出 px；tokens 丢 decoration/case） | ✅ 1.3.0：run 回退 base 字体/字号/字重；tokens 输出 textCase/deco 与 *Num |
| 2026-11-21 | 1.2.0 使用测试的低优先级问题清单 | ✅ 1.3.0：frames 空过滤/--file、tokens 空 id/去重/page=-、路径、--version、get URL、missing 文案、*Num、tokens --skip-name-prefix |
| 2026-11-21 | fetch 合并缓存绕过 check-stale / depth 误标 / 漏用旧完整缓存 / 精确 partial | ✅ 1.2.0：按 fileKey、depth、缓存 version 修正；合并命中执行 /meta |
| 2026-11-21 | 缓存按 nodeId 跨 fileKey 查找，fetch/diff 串文件 | ✅ 1.2.0：fetch/diff 按 fileKey 过滤；spec/tokens 多文件提示 --file= |
| 2026-11-21 | `tokens --json` 的 `sources` 变成 basename | ✅ 1.2.0：JSON 保留可定位路径；markdown 用短文件名 |
| 2026-11-21 | IMAGE / GRADIENT / 非 SOLID 描边丢 paint opacity | ✅ 1.2.0：补 IMG/GRAD/描边 opacity；diff 检测 IMAGE opacity |
| 2026-11-21 | 1.1.0 spec/diff 收尾（scalar 0 / clip false / 阴影 alpha / decoration / 3+ stop） | ✅ 1.2.0：逐项修正；clip/isMask 只标 true 已写文档 |
| 2026-11-21 | spec 根节点圆角 / opacity / isMask 缺失 | ✅ 1.2.0：rootExtras 补圆角、透明度、mask |
| 2026-11-21 | 1.1.1 fetch/spec 收尾（missingNodeIds / depth 假警告 / 渐变双 @） | ✅ 1.2.0：清理 missing、完整缓存满足 depth、opacity 格式去歧义 |
| 2026-11-21 | spec 缺 strokeCap / strokeJoin | ✅ 1.2.0：非默认 cap/join 输出 |
| 2026-11-21 | spec 缺 textAlignVertical / cornerSmoothing | ✅ 1.2.0：补 valign / smooth；diff 同步 smoothing |
| 2026-11-21 | 有完整缓存时 fetch --depth 仍走网络 | ✅ 1.2.0：完整缓存直接返回，不生成 dN；--refresh 才重拉 |
| 2026-11-21 | 多完整缓存分摊 ids 时 depth 仍走网络 | ✅ 1.2.0：多个完整缓存合并为完整结果 |
| 2026-11-21 | 多完整缓存合并覆盖同名缓存，丢未请求节点 | ✅ 1.2.0：合并前保留目标已有 nodes |
| 2026-11-21 | depth 命中完整缓存时 stderr 不标 checked /meta | ✅ 1.2.0：stderr 标注；JSON 增加 checkedMeta |
| 2026-11-21 | check-stale / if-stale 用 _meta 而非缓存 version | ✅ 1.2.0：优先缓存 version；旧缓存不再被 meta 洗白 |
| 2026-11-21 | spec 目标本身是 TEXT 时只有空表 | ✅ 1.2.0：输出目标文字与样式 |
| 2026-11-21 | opacity=0 未隐藏；无 --skip-hidden | ✅ 1.2.0：spec/tokens 跳过 opacity=0；新增 --skip-hidden |
| 2026-11-21 | 文字样式漏 italic / rich run 字号/字体/字距；tokens 漏 run 颜色 | ✅ 1.2.0：fontStyle + run 样式；tokens 收集 run 颜色/字号 |
| 2026-11-21 | layout padding 歧义；layoutSizing/positioning/constraints 缺失 | ✅ 1.2.0：padding=l/r/t/b；补 sizing/position/constraints/wrap；diff 同步 |
| 2026-11-21 | individualStrokeWeights 只输出字母，diff 漏单边宽度 | ✅ 1.2.0：输出 L=2,R=1；diff 用带宽度 key |
| 2026-11-21 | frames 只列 FRAME；单节点 page 为空 | ✅ 1.2.0：列 SECTION/COMPONENT/COMPONENT_SET；单节点 page 未知并警告，--page=- 可筛 |
| 2026-11-21 | spec/tokens/fetch ids 不 trim | ✅ 1.2.0：统一 trim |
| 2026-11-21 | url 用 contains(figma.com)，空 fileKey 通过 | ✅ 1.2.0：严格 host；空 fileKey 拒绝 |
| 2026-11-21 | fetch 合并只写 {document}，丢 per-node 元数据 | ✅ 1.2.0：保留完整 node 条目 |
| 2026-11-21 | 合并单 id 只写 {nodes}，stale 失效 | ✅ 1.2.0：保留顶层 version；空 version 报 unknown |
| 2026-11-21 | 1.1.1 复测收尾（旧索引 type / tokens italic/run / 非 auto layout / diff 重排 / url 大小写 / skip-hidden 目标） | ✅ 1.2.0：索引升 7；文字/布局/diff/url/skip-hidden 修正 |
| 2026-11-21 | tokens texts 不输出 fontStyle | ✅ 1.2.0：公开 getter + JSON/markdown 样式字段 |
| 2026-11-21 | 无 version 旧缓存仍把 _meta 当缓存版本 | ✅ 1.2.0：versionUnknown，提示 --refresh |
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
