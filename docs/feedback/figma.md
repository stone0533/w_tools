# w_tools_figma 反馈

## 待处理

### [待处理] figma: spec/tokens 默认仍选中 depth 裁剪缓存（JSON 已可发现，--prefer-full 为 opt-in）

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 / Dart 3.12.2；真实项目缓存（同一 nodeId 同时有完整缓存和更新的 `-d2` 缓存）
- 命令 / 输入：dart run w_tools_figma:figma tokens 0:1 --json --skip-markdown
  `dart run w_tools_figma:figma tokens 0:1 --json --skip-markdown`
  `dart run w_tools_figma:figma tokens 0:1 --file=<完整缓存> --json --skip-markdown`
  `dart run w_tools_figma:figma spec 0:1 --json`
  `dart run w_tools_figma:figma frames --all --depth=1`（只剩 dN 缓存时）
- 期望：spec / tokens 读设计事实时默认应优先完整树（或在 JSON 里明确标出 depthLimited / sourceDepth）；stderr 警告要能直接给出可用于 `--file=` 的完整缓存路径
- 实际：`resolveNodeCaches` 默认按 mtime 取最新（nodes_index.dart:13 `preferFullDepth = false`；spec_handler.dart:148 / tokens_handler.dart:111 没传该参数）。当 d2 缓存比完整缓存新时，同一页面：
  `tokens 0:1 --json` → colors 13 / texts 7 / radii 1 / spacings 3
  `tokens 0:1 --file=<完整缓存>` → colors 156 / texts 151 / radii 12 / spacings 32（约 12 倍差）
  stderr 只有一行「数据源来自 --depth 裁剪缓存…子节点可能缺失」，JSON 的 `items[].source` / `sources[]` 只有文件路径，没有 `depthLimited` 字段。agents 只读 stdout 时会把截断结果当完整结果。另外：warning 让用户「用 --file= 指定完整缓存」，但不打印完整缓存路径，`frames --verbose` 也只指向 dN 文件；当只剩 dN 缓存时，frames 把被裁剪掉的子节点数报成 0（合成节点 10:7 实际 2 个子节点 → frames 显示 children=0），没有截断标记。
- 影响：按项目文档「大页面只拉 2 层」后，spec / tokens 会静默给出严重不完整的设计事实；AI 直接拿 JSON 写页面会漏掉大部分 token / 子节点，且很难发现。tokens 的差值不是小幅偏差，而是 12 倍。
- 建议：spec / tokens 默认 `preferFullDepth: true`（在完整缓存里取最新），只有完全没有完整缓存时才回退 dN，并显式要求 `--allow-depth` 或在 JSON 标 `depthLimited: true` / `sourceDepth: n`；warning 打印完整缓存路径（或提示 `cache stats --files` 的文件名规则）；frames 对被裁剪节点的 children 输出 null 或加 truncated 标记，不要报 0。
- 复现数据：真实节点 `0:1`；完整缓存 `nodes-…-0-1.json`（129 MB，mtime 14:17）vs `nodes-…-0-1-d2.json`（401 KB，mtime 15:25）；tokens counts 13/156 如上；frames 合成缓存 `10:7`（自動佈局）2→0。

1.3.0 复测：JSON `depthLimited` / `sourceDepth`（tokens 为 `sourceDepths`）、命中裁剪缓存时列出完整缓存路径、`--prefer-full`、`frames --json cacheDepth` 都已加上。但默认仍按 mtime 取最新 `-dN`：普通 `tokens 0:1` 仍只读到 13/156 色，`--prefer-full` 是 opt-in；不看 stderr 的用户/AI 仍可能把截断结果当完整事实。建议默认 `prefer-full`，或至少要求显式 `--allow-depth` 才读 dN。

- 状态变更：2026-11-21 待处理

### [待处理] figma: 缓存结构异常时未捕获异常，exit 255（不在文档退出码里）

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 / Dart 3.12.2；合成缓存文件
- 命令 / 输入：dart run w_tools_figma:figma spec 1:1 --file=<bad1.json>
  `dart run w_tools_figma:figma spec 1:1 --file=<bad1.json>`（root 的 `absoluteBoundingBox` 缺 `x`）
  `dart run w_tools_figma:figma spec 1:1 --file=<bad2.json>`（TEXT 的 `style` 写成字符串）
- 期望：按 README「缓存损坏默认报错」给一条可读错误，退出码 1（或 2），不打印 Dart 栈
- 实际：exit 255，stderr 是 `Unhandled exception:` + 栈：`type 'Null' is not a subtype of type 'num' in type cast`（spec_renderer.dart:41）；另一例 `type 'String' is not a subtype of type 'Map<dynamic, dynamic>?' in type cast`（figma_node.dart:143）。run.dart 只 catch FigmaTokenException / StateError / FormatException / FigmaHttpException / Timeout / Http / Socket / FileSystemException，TypeError 直接穿透。
- 影响：缓存被手改、旧版本结构或部分字段缺失时 CLI 直接崩，退出码不在文档的 0~5 里；脚本会把它当成未知失败，而且看不到是哪份缓存 / 哪个节点的问题。
- 建议：run.dart 增加兜底 catch（打印「缓存结构异常：…」+ 缓存路径 + 建议 `--refresh` / `cache clean`，exit 1），或在 spec renderer 里对 bbox / style 做防御读取；退出码表补一个「内部错误」或复用 1。
- 复现数据：`bad1.json` 的 root 为 `{"id":"1:1","type":"FRAME","absoluteBoundingBox":{"y":0,"width":10,"height":10},"children":[]}`；`bad2.json` 的 node 含 `"style":"oops"`；两条命令均 exit 255，栈行如上。

1.3.0 复测：bbox 缺字段 / TEXT `style` 非对象的 `TypeError` 已修（exit 1 + 可读错误）；但 `individualStrokeWeights` 的 key 为空字符串时 `substring(0,1)` 仍抛 `RangeError`，exit 255（figma_node.dart:100）。`run.dart` 目前只 catch `TypeError`，建议兜底 `Error` 或校验 key 长度。新增复现：`{"individualStrokeWeights":{"":2}}`。

- 状态变更：2026-11-21 待处理

### [待处理] figma: init 无法恢复只剩注释的 token 文件，--force 误报「已有真实 token」

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 / Dart 3.12.2；临时 HOME
- 命令 / 输入：`printf '# only comments\n' > ~/.config/w_tools/figma-token`；`dart run w_tools_figma:figma init`；`dart run w_tools_figma:figma init --force`；`dart run w_tools_figma:figma me`
- 期望：没有有效非注释行就等同空/模板，init 应重建；--force 只在确实有真实 token 时拒绝
- 实际：init exit 0「已存在」，文件保持 16 字节；me exit 4「还是模板内容」；init --force exit 1「已有真实 token，--force 不会覆盖」（误报）。只有手动删除文件才能恢复。
- 影响：用户在编辑器里删掉 `figd_REPLACE_ME` 但保留注释后，init 不再是恢复入口；--force 的提示还会让人以为文件里有真 token。
- 建议：init 用与 readToken 相同的 `_tokenLine` 判断空/模板；没有有效非注释行时重建；--force 只对有效非模板行拒绝。
- 复现数据：文件内容 `# only comments\n`；init 后 16 字节；me / --force 输出如上。
- 状态变更：2026-11-21 待处理

### [待处理] figma: cache clean --file 拒绝同一文件的 /tmp 绝对路径（规范化回归）

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2（/tmp 是 /private/tmp 的软链）/ Dart 3.12.2；临时 HOME
- 命令 / 输入：`dart run w_tools_figma:figma cache clean --file=/tmp/<home>/.cache/w_tools/figma/<project>/nodes-….json --yes`；同一文件换成 `/private/tmp/<home>/…` 再执行
- 期望：同一文件的不同等价路径都应接受；仍只允许删当前项目缓存目录内的文件
- 实际：`/tmp/<home>/…` exit 2「--file 只能删当前项目缓存目录下的文件」；`/private/tmp/<home>/…` exit 0。1.3.0 把 store.dir 规范化成了 /private/tmp，但 cleanFile 仍用未规范化的 `candidate.parent.path` 与 canonical root 比较。
- 影响：macOS 脚本 / 旧输出里的 /tmp 路径无法清理；用户看到同一文件被拒绝，容易误以为权限或缓存损坏。
- 建议：cleanFile 先对 candidate 做 canonicalDirectory / resolveSymbolicLinks，再比较 parent；保留 symlink 越界防护。
- 复现数据：`cache stats` 输出 `/private/tmp/<home>/…`；`--file=/tmp/<home>/…` exit 2，`--file=/private/tmp/<home>/…` exit 0。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec/tokens --file=<dN> 的 warning 误报「没有其它完整缓存」

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 / Dart 3.12.2；合成缓存（同目录同时有完整树和 `-d1`）
- 命令 / 输入：`dart run w_tools_figma:figma spec 10:1 --file=<d1.json>`；`dart run w_tools_figma:figma tokens 10:1 --file=<d1.json> --json --skip-markdown`
- 期望：warning 应列出可用的完整缓存，至少不要声称「没有其它完整缓存」
- 实际：warning 结尾是「没有其它完整缓存，可重新 fetch nodes」，但同目录有 `nodes-FILEA-10-1.json` 完整缓存。`depthLimitedMessage` 的 `fullPaths` 只在 `options.file == null` 时计算，显式 `--file` 一给就被强制为空。
- 影响：用户可能因为这条警告重新 fetch，浪费 Tier 1；也误导对缓存状态的判断。
- 建议：`--file` 场景也调用 fullNodesCachePaths（排除当前文件），或在没有真正检查时删掉「没有其它完整缓存」的断言。
- 复现数据：`spec 10:1 --file=nodes-FILEA-10-1-d1.json` 的 stderr；完整文件同目录存在。
- 状态变更：2026-11-21 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
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
