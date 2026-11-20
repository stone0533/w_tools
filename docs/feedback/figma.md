# w_tools_figma 反馈

## 待处理







### [待处理] figma: fetch nodes：--scale=2 未被拒绝，节点不存在时也返回成功并污染缓存

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path；pub.dev 最新仍是 0.13.3），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；真实项目 ureward，Figma fileKey `UpyszH8lFtWYwrIXm1XAWw`，缓存目录 `~/.cache/w_tools/figma/ureward-56cc5be6/`
- 命令 / 输入：①`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 1:2 --scale=2`（1:2 是不存在的节点，仅用于验证参数校验）；②`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 1:2`（不带 flag，验证节点不存在的处理）
- 期望：按 README 的参数边界「`fetch nodes` 不接受 `--scale`」，①应 exit 2 并提示；按 README 退出码表「1 一般错误 / 节点不存在」，②应 exit 1、不写缓存。参照：`fetch images` 对 Figma 返回 null 的节点会警告「⚠️ 有节点没有导出图片（Figma 返回 null）」
- 实际：①`--scale=2` 被静默接受，命令照常发请求并 exit 0（只有 `--scale=3` 这类非默认值才会被拒）；②节点不存在时同样 exit 0，打印 `# fetched: <cache path>`，把 Figma 的 `{"nodes": {"1:2": null}}` 原样写成缓存文件 `nodes-UpyszH8lFtWYwrIXm1XAWw-1-2.json`，并消耗 1 次 Tier 1；③该文件之后让同项目所有 `spec` 调用的「找不到节点」提示多出一句「另有 1 个缓存文件解析失败（该文件路径）」，而文件本身是合法 JSON、只是节点为 null，文案把排查方向指向了错误的结论
- 影响：实测当月 Tier 1 用量从 14/20 变成 15/20（一次无效 nodeId 白烧 1 次额度，而 1.0.0 的 README 已写明 fetch 不做本地额度拦截，额度只能靠服务端 429 兜底）；一次错误 nodeId 就会污染该项目的缓存索引，让后续所有 spec 输出带上误导性的「缓存文件解析失败」，必须手动 `cache clean` 才能恢复；`--scale=2` 静默放行会让人误以为 fetch nodes 支持倍率
- 建议：①把 `fetch nodes` 的 `--scale` 校验从「与默认值比较」改成「是否显式传了该参数」（例如 `wasProvided('scale')`），与 `fetch images --refresh/--depth` 的拒绝方式保持一致；②`FetchCommand.nodes` 返回后检查每个 id 对应的 node 是否为 null：全部为 null → exit 1 且不落缓存；部分为 null → 保留成功节点并像 images 那样给出警告；③`nodes_index` 的「解析失败」文案区分「JSON 损坏」与「节点为 null」，避免误导
- 复现数据：源码位置 `packages/figma/lib/src/cli/fetch_handler.dart:43-44`（`if (kind == 'nodes' && options.scale != 2)`）与 `packages/figma/lib/src/cli/args.dart:25`（`int get scale => intOption('scale') ?? 2`）——传显式 2 时两者相等，条件恒为假；`packages/figma/lib/src/cli/fetch_handler.dart` 的 images 分支有 null 警告、nodes 分支没有。实测：①命令输出仅 `# fetched: /Users/lei0533/.cache/w_tools/figma/ureward-56cc5be6/nodes-UpyszH8lFtWYwrIXm1XAWw-1-2.json`，exit 0；②缓存文件内容为 `{"name": "uReward", "version": "2421134302405946194", "nodes": {"1:2": null}}`；③随后 `dart run w_tools_figma:figma usage` 显示 `Tier 1 calls this month (2026-11): 15 / 20`；④随后 `dart run w_tools_figma:figma spec 99999:1` 输出含「另有 1 个缓存文件解析失败（/Users/lei0533/.cache/w_tools/figma/ureward-56cc5be6/nodes-UpyszH8lFtWYwrIXm1XAWw-1-2.json）」；删除该文件后同一命令恢复正常提示
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec --node-only 的 help/README 与实现口径不一致：不带 --json 时仍输出完整 markdown

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward，缓存目录 `~/.cache/w_tools/figma/ureward-56cc5be6/`
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:42140 --node-only`（不带 `--json`）
- 期望：按 `help spec` 的「`--node-only` 只输出 node，不带 markdown」与 README:197「`spec --node-only` 只返回结构化 `node`（不生成 markdown）」，应只输出结构化的 node；若该开关必须配合 `--json`，应明确拒绝或提示
- 实际：输出完整 Markdown（先一行 `> 数据源：<缓存路径>`，再 `# 01優惠券-可使用  (2105:42140)` 和 471 行属性表），exit 0。实现注释写的是相反的口径：「`--node-only` 只影响 `--json`：文本模式的输出本身就是 markdown，必须照常渲染」
- 影响：按文档写脚本或 agent 提示词的人会以为 `--node-only` 能拿到结构化节点，实际拿到 46 KB 的 Markdown 文本，只能再改命令重跑；文档、`help spec`、代码注释三方口径不一致，排查时容易怀疑参数没生效
- 建议：二选一即可——①让 `--node-only` 隐含 `--json`，或在不带 `--json` 时 exit 2 并提示「`--node-only` 需要 `--json`」；②把 README:197 与 `help spec` 的文案改成「`--node-only` 仅在 `--json` 下生效，文本模式仍输出 markdown」
- 复现数据：源码 `packages/figma/lib/src/cli/spec_handler.dart:33-34`（注释与 `final includeMarkdown = !options.json || !options.nodeOnly;`）；README 第 197 行；`dart run w_tools_figma:figma help spec` 输出「--node-only  只输出 node，不带 markdown」；实测输出前 3 行为 `> 数据源：/Users/lei0533/.cache/w_tools/figma/ureward-56cc5be6/nodes-UpyszH8lFtWYwrIXm1XAWw-2105-41432.json`、`# 01優惠券-可使用  (2105:42140)`、`画板 375×996，背景 #F8F8F5，描边 -，阴影 -`，exit 0
- 状态变更：2026-11-20 待处理

### [待处理] figma: cache clean（不带 --all）无确认即删除当前项目缓存，与 --all 的 --yes 策略不对称

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward
- 命令 / 输入：`dart run w_tools_figma:figma cache clean`（不带 `--all`，也不带 `--yes`）
- 期望：删除当前项目缓存同样需要一次确认（`--yes` 或交互确认），并与 `--all` 的既有策略保持一致；该命令的结果是重新 fetch，会消耗 Tier 1 额度
- 实际：直接删除当前项目缓存并打印「已清理 N 个项目缓存（X MB）：<缓存目录>」，没有任何确认；只有 `cache clean --all` 要求 `--yes`（缺 `--yes` 时 exit 2）
- 影响：本项目 `cache stats --json` 实测为 13 个文件 / 146.4 MB，一次误触就要全部重拉，直接消耗月度 Tier 1 额度（上限 20，本月已用 16）；这与 2026-11-03 已闭环的「`cache clean --all` 无确认，误删 59.7 MB 缓存」是同一类风险，只是作用域从"所有项目"缩小到"当前项目"，但代价一样
- 建议：给不带 `--all` 的 `cache clean` 也加 `--yes`（缺失时 exit 2，并先打印将删除的文件数与体积），或改为交互确认；`--all` 的既有行为保持不变。若刻意保留"当前项目免确认"，请在 README 的 `cache clean` 说明里写明这一点，别只写 `--all` 需要 `--yes`
- 复现数据：源码 `packages/figma/lib/src/cli/cache_handler.dart` 中仅对 `options.all && !options.yes` 做拦截（`清理所有项目缓存需要 --yes 确认`），无 `--all` 时直接走删除分支并打印「已清理」；README:200 只写「`cache clean --all` 必须同时给 `--yes`」；`dart run w_tools_figma:figma cache stats --json` 输出 `{"schema":"w_tools_figma.cache/1","files":13,"bytes":153513008,"megabytes":146.4}`；`dart run w_tools_figma:figma usage` 显示 `Tier 1 calls this month (2026-11): 16 / 20`
- 状态变更：2026-11-20 待处理

### [待处理] figma: cache stats 不区分历史全量 dump：129 MB 死重被计入缓存体积，且只能靠 cache clean 全删

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward，缓存目录 `~/.cache/w_tools/figma/ureward-56cc5be6/`
- 命令 / 输入：`dart run w_tools_figma:figma cache stats --json`，配合 `ls -lhS` 查看同一目录
- 期望：`cache stats` 能区分「仍被索引 / 当前版本仍在用的缓存」与「历史遗留、已不再读取的文件」，或者提供只清历史遗留的入口；体积统计应能反映可回收部分
- 实际：统计为 13 个文件 / 146.4 MB，其中 `nodes-UpyszH8lFtWYwrIXm1XAWw-0-1.json` 单文件 129 MB（整份 document 根节点 dump），`file-UpyszH8lFtWYwrIXm1XAWw-d2.json` 与 `-d3.json` 合计 3.2 MB 是旧格式；`frames` 实测 0.6 秒完成、读的是 2.2 MB 的 `_nodes-index.json`，那份 129 MB 的 dump 并没有被用上。README 只写了「旧版本按 `file-<key>-s<depth>.json` 存过的文件缓存不会再被读取，升级后可清理一次」，没有覆盖这类 `nodes-<key>-0-1` 全量 dump，也没有命令能列出「哪些文件是死的」
- 影响：本项目缓存的约 88% 是死重；`cache stats` 只有一个总体积，会让人以为「缓存本来就该这么大」，从而误判是否需要 `--depth`；而唯一的清理手段 `cache clean` 又会连活跃缓存一起删掉（见另一条关于确认的反馈），于是用户只能在「留着 129 MB 死重」和「全删重拉烧额度」之间二选一
- 建议：①`cache stats` 输出每个文件的体积与状态（indexed / orphan），或至少给出「可回收体积」；②`cache clean` 增加 `--orphans` 只清未被索引的文件；③README 把「`nodes-<key>-0-1` 这种历史全量 dump 也算旧格式、可清理」写清楚
- 复现数据：同一目录 `ls -lhS` 输出 `129M nodes-UpyszH8lFtWYwrIXm1XAWw-0-1.json`、`10M nodes-UpyszH8lFtWYwrIXm1XAWw-2105-41432.json`、`2.9M file-UpyszH8lFtWYwrIXm1XAWw-d3.json`、`2.2M _nodes-index.json`、`314K file-UpyszH8lFtWYwrIXm1XAWw-d2.json`；`cache stats --json` 输出 `{"schema":"w_tools_figma.cache/1","files":13,"bytes":153513008,"megabytes":146.4}`；`time dart run w_tools_figma:figma frames` 实测 `real 0m0.621s`
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec 的 markdown 规格表缺少子节点 nodeId，读规格后无法直接切图或单独复查

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward，缓存目录 `~/.cache/w_tools/figma/ureward-56cc5be6/`
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:42140`（markdown，日常读规格的默认方式）；随后想对表里某个节点执行 `fetch images <fileKey> <ids>` 切图，或 `diff <fileKey> <nodeId>` 单独复查
- 期望：markdown 规格表能给出每个节点的 nodeId（新增一列 id，或提供 `--with-id` 之类的开关），这样从表里挑出元素后能直接拿到 id 去切图 / 复查
- 实际：表格列是 `x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 透明度 | 文字`，没有 id 列；只有标题行带根节点 id（`# 01優惠券-可使用  (2105:42140)`）。子节点 id 只能通过 `spec --json --node-only` 或 `frames --json` 拿到
- 影响：日常流程「读 markdown 找到元素 → 切图 / 单独复查」在最后一步断掉，必须切到 `--json` 再按名字 grep；而设计稿里同名节点很多（spec 表里大量 `Vector`、`Frame 15xxx`，`frames` 里 `01優惠券-可使用` 就出现 3 次），按名字匹配并不可靠。agent 场景更明显：模型先读 markdown 理解结构，再要切图时拿不到 id，只能重跑一次 --json
- 建议：①markdown 表格加一列 `id`（默认关、`--with-id` 开，避免表格过宽）；②或另给一份「名称 → id」的轻量清单（例如 `--id-map`）；③至少在 README 的「输出」一节写明「markdown 不含子节点 id，需要 id 请用 `--json`」，别让人先踩一次
- 复现数据：`spec 2105:42140` 表头原文 `| x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 透明度 | 文字 |`，正文行形如 `| 0.0,0.0 | 375.0×380.0 | GROUP | **隐藏** Mask group | - | - | - |  |  |  |`（无 id）；同名现象：`frames` 输出里 `01優惠券-可使用` 有 2105:42140、2137:172367、2137:180183 三条；spec 表里 `Vector` 与 `Frame 15xxx` 重复出现
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec 的 markdown 规格里完全没有布局间距（padding/itemSpacing/layoutMode），但 diff 却在比这些字段

- 包/版本：w_tools_figma 1.0.0（本地检出，pubspec.lock 指向 path），以本地代码为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；项目 ureward，节点 2105:42140（375×996 的优惠券页）
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:42140`（markdown，日常读规格的默认方式），用来还原卡片的内边距与列表间距
- 期望：规格里能读到布局信息（`layoutMode` / `paddingTop-Right-Bottom-Left` / `itemSpacing` / 主轴对齐），因为还原设计稿时这些是必须值；同一个包在 `diff` 里已经把 `itemSpacing` 与 `padding*` 纳入比较，说明它自己也认为这些属性会变、需要关注
- 实际：markdown 规格表固定 10 列（x,y / w×h / 类型 / 名称 / 填充 / 描边 / 阴影 / 圆角 / 透明度 / 文字），布局信息一处都没有：`grep -icE "padding|itemSpacing|layoutMode|gap"` 命中 0。这些字段只存在于 `--json` 的原始 node 里，或 `tokens` 的聚合 `spacings` 统计（例如 8.0 出现 40 次），无法定位到具体节点
- 影响：还原卡片 16/10 的内边距、8 的 itemSpacing 时，markdown 里没有依据，只能拿子节点的 x,y 相减反推，容易把 16 算成 15 或 17；设计改版时 `diff` 会报 `itemSpacing: 8 → 10`，但 `spec` 里看不到当前值，两个命令对不上，排查要多开一次 `--json`。这与「看设计稿不许只看坐标」的项目实践直接冲突
- 建议：①表格增加一列「布局」（例如 `V gap=8 pad=16,16,10,10`，无布局时留空）；②或对带 auto-layout 的节点在表后追加一个缩进的「布局」小节；③若短期不做，至少在 README 的「输出」一节写明「间距 / 布局不在 markdown 里，需要 `--json` 或 `tokens`」
- 复现数据：`spec 2105:42140` 表头原文 `| x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 透明度 | 文字 |`；`dart run w_tools_figma:figma spec 2105:42140 | grep -icE "padding|itemSpacing|layoutMode|gap"` → `0`；同节点 `spec 2105:42140 --json --node-only` 的 node 里存在 `layoutMode`、`itemSpacing`、`paddingLeft/Right/Top/Bottom` 字段；`tokens 2105:42140 --json --skip-markdown` 的 `spacings` 只有 `{"value":"8.0","count":40}` 这类聚合值
- 状态变更：2026-11-20 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
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
