# w_tools_figma 反馈

## 待处理

### [待处理] figma: init 生成的 token 模板填完后仍被判非法，首次本地配置必失败

- 包/版本：w_tools_figma 1.2.0（本机用 pubspec_overrides 指向 packages/figma）
- 环境：macOS 26.6.2 / Flutter 3.44.9 / Dart 3.12.2；HOME 指向全新临时目录，FIGMA_TOKEN 未设置
- 命令 / 输入：dart run w_tools_figma:figma init，填好 token 后 dart run w_tools_figma:figma me
  `dart run w_tools_figma:figma init`
  按提示把模板最后一行 `figd_REPLACE_ME` 替换成真实 `figd_` 令牌（其余 4 行 `#` 注释保留）
  `dart run w_tools_figma:figma me`
- 期望：按 init 的提示填好令牌后，本地 token 文件可直接使用；me 返回 0
- 实际：me exit 4，stderr：`<home>/.config/w_tools/figma-token 里的 token 需要 figd_ 开头`。init 生成的模板前 4 行是 `#` 注释，而 token_source.dart:19 读整个文件后 `trim()`、:30 要求 `startsWith('figd_')`；保留注释就一定失败，只有把注释全部删掉才通过。另外两个同源问题：1) 把 token 文件清空成 0 字节后再跑 init，init 只打印「已存在」，不重建模板（init_handler.dart:38 的 isTemplate 判断到了，但创建条件只在 force 时成立）；2) 已存在真实 token 但权限为 644 时，init 不做 chmod，仍是 644，与 README「权限 600」不一致。
- 影响：新机器 / 新项目按 README 的「5 分钟上手」走，本地 token 第一步就卡死；用户会以为令牌无效，只能用 FIGMA_TOKEN 或手工删注释绕过。空文件与 644 权限让恢复和凭据保护也不可靠。
- 建议：readToken 先按行过滤空行 / `#` 注释行，取第一个（或最后一个）非注释行再校验；`_validateToken` 只校验该行。或者 init 不再把说明写进 token 文件，只写 `figd_REPLACE_ME`。init 遇到空文件时重建模板；每次 init 都对已存在的 token 文件执行 chmod 600。
- 复现数据：模板 5 行（4 行 `#` 注释 + `figd_REPLACE_ME`）；替换最后一行为 `figd_…` 后 `me` exit 4；`wc -c` 显示空文件 0 字节；`stat -f '%Sp'` 显示 644。用 `dart run` 与编译后的 1.2.0 各复现一次。
- 状态变更：2026-11-21 待处理

### [待处理] figma: --root 未规范化，等价路径落到不同缓存目录

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2（/tmp 是 /private/tmp 的软链）/ Dart 3.12.2；临时 HOME 隔离
- 命令 / 输入：dart run w_tools_figma:figma cache stats --root=.（其余写法见下）
  `cd /tmp/fgtest/proj`（有 pubspec.yaml；默认缓存 id 为 proj-14cf4a1b）
  `dart run w_tools_figma:figma cache stats`                          → proj-14cf4a1b
  `dart run w_tools_figma:figma cache stats --root=.`                 → .-b4ca59f6
  `dart run w_tools_figma:figma cache stats --root=./`                → .-738b709b
  `dart run w_tools_figma:figma cache stats --root=/tmp/fgtest/proj`  → proj-98af72e3
  `dart run w_tools_figma:figma cache stats --root=../proj`           → proj-117a5d56
  `dart run w_tools_figma:figma spec 10:1 --root=.`                   → exit 1「没有 nodes-*.json」
  `dart run w_tools_figma:figma cache stats --root=`（空值）           → 另一个 id
- 期望：同一个项目目录用 `.` / `./` / 绝对路径 / 软链路径 / 空值（应报错）指定时，落到同一个 projectId；--root 是「指定项目根」，不是「另开一份缓存」
- 实际：CachePaths.projectId（cache_paths.dart:26）直接对 `root.absolute.path` 做 FNV-1a，没有 normalize / realpath：`--root=.` 的 path 以 `/.` 结尾，目录名变成 `.`；`/tmp/...` 与 `/private/tmp/...` 是两条不同字符串；`--root=` 空值也生成不同 hash。于是 spec/frames/cache stats 读到的是另一份空缓存，静默「找不到缓存」。
- 影响：脚本里的 `--root="$VAR"`、`--root=.`、macOS 上手写 `/tmp/...`、带尾斜杠的路径都会命中另一份空缓存；用户以为缓存丢了并重新 fetch，会再消耗 Tier 1，而且写到另一个目录。`figma --root=... frames`（选项放命令前）则被当成未知命令 exit 2，也容易误用。
- 建议：CachePaths 构造时对存在的 root 做 `resolveSymbolicLinksSync()`；至少 `p.normalize(p.absolute(path))` 并去掉尾斜杠，projectId / relativeToRoot 都用规范化后的路径；`--root` 为空或目录不存在时给出明确错误；文档说明 --root 必须放在命令之后。
- 复现数据：同一目录五种写法得到 5 个不同 projectId（上面已列）。临时 HOME 下复现，未动真实缓存。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec/tokens 默认选中 depth 裁剪缓存，JSON 看不到截断（同页 token 少 12 倍）

- 包/版本：w_tools_figma 1.2.0
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
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec 的 --skip-hidden / --skip-name-prefix 只过滤 Markdown，--json 的 node 未过滤

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2 / Dart 3.12.2；合成缓存 `10:1`
- 命令 / 输入：dart run w_tools_figma:figma spec 10:1 --skip-hidden --json
  `dart run w_tools_figma:figma spec 10:1 --skip-hidden --json`
  `dart run w_tools_figma:figma spec 10:1 --skip-name-prefix=標題 --json`
  缓存 `10:1` 里有一个 `visible: false` 的 TEXT「隱藏文字」，和一个名称以「標題」开头的 TEXT
- 期望：按 README / AGENTS 的说法「跳过 visible=false / opacity=0 的节点」「跳过名称以该前缀开头的节点」；`items[].node` 与 `markdown` 应是同一棵过滤后的树
- 实际：markdown 里两行都被跳过；`items[].node` 仍包含「隱藏文字」和「標題」节点。CLI help 写的是「markdown 跳过」，但 README「spec --skip-hidden」、packages/figma/AGENTS.md「spec --skip-name-prefix=<s> 跳过状态栏 mock」都没有说只影响 Markdown。JSON 消费方拿到的 node 与 markdown 不一致，flag 实际无效（spec_handler.dart:164 只 trimNode，过滤只进 renderer 的 markdown）。
- 影响：AI / 脚本走 `--json` 时无法用这两个 flag 去掉 iOS 状态栏 mock / 隐藏节点，只能自己再实现一遍过滤；与文档预期相反。
- 建议：把过滤同时应用到 `items[].node`（先 prune 再 trim，明确 `--node-depth` 的顺序），或在 JSON 增加 `skippedNodeIds`；如果确实只打算影响 markdown，就把 README / AGENTS / CLI help 统一改成「仅 Markdown」，并在 `--json` 时打印明确提示。
- 复现数据：`spec 10:1 --skip-hidden --json` 的 node 仍含 `隱藏文字`；`spec 10:1 --skip-name-prefix=標題 --json` 的 node 仍含 `標題`；同一输入的 markdown 都已过滤。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec 对 CANVAS/TEXT 根节点语义错误（首个子节点冒充根、文字填充写成背景）

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2 / Dart 3.12.2；真实缓存
- 命令 / 输入：dart run w_tools_figma:figma spec 0:1
  `dart run w_tools_figma:figma spec 0:1`
  `dart run w_tools_figma:figma spec 0:1 --json`
  `dart run w_tools_figma:figma spec I1992:61890;77:12596;1:279`
- 期望：`spec 0:1` 输出页面（CANVAS）本身或其 27 个子节点，标题用页面名，坐标相对页面原点；`spec I1992:61890;77:12596;1:279` 不要把文字填充色当成背景色
- 实际：`spec 0:1` 的 markdown 标题是 `# Table  (0:1)`，表格列的是首个子节点 TABLE 的 TABLE_CELL 子节点（坐标相对 TABLE）；同一个命令的 `--json` 里 `items[].node` 却是 id=0:1、type=CANVAS、name=`mockup（設計畫面看此頁面，供切版使用）TBC` 的页面节点（27 个 children）。markdown 与 node 完全不是同一棵子树。原因在 spec_renderer.dart:31-37：根节点没有 `absoluteBoundingBox` 时用 `children.first` 兜底，但标题仍用 targetId。`spec I1992:61890;77:12596;1:279` 输出 `画板 48×19，背景 #3F3F3F`，把 TEXT 的 fill 写成了「背景」。
- 影响：复制页面链接（node-id=0:1）或按文档对 canvasId 出规格时，拿到的是首个子节点的局部规格，标题和坐标都有误导性；TEXT 目标会被误读成有背景色的画板，容易把文字颜色实现成背景。
- 建议：根节点没有 bbox 时不要替换成 `children.first`；用页面自身的 name / type 做标题，输出「页面」而不是「画板」，坐标直接用子节点原始 `absoluteBoundingBox`（或明确说明相对页面原点）；TEXT 根节点把 fill 标成「文字色」，不要叫背景。
- 复现数据：真实缓存 `nodes-…-0-1.json`；`spec 0:1` 输出表头 `# Table  (0:1)` + TABLE_CELL 行，`--json` 的 node 是 CANVAS / 27 children；`spec I1992:61890;77:12596;1:279` 输出「画板 48×19，背景 #3F3F3F」。
- 状态变更：2026-11-21 待处理

### [待处理] figma: rich text 输出错误（spec 空字号出 px；tokens 丢 decoration/case 导致重复行）

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2 / Dart 3.12.2；真实缓存（富文本链接）
- 命令 / 输入：dart run w_tools_figma:figma spec 'I1992:61890;77:12596;1:279' --file=<完整缓存>
  `dart run w_tools_figma:figma spec 'I1992:61890;77:12596;1:279' --file=<完整缓存>`
  `dart run w_tools_figma:figma tokens 'I1992:61890;77:12596;1:279' --file=<完整缓存> --json --skip-markdown`
  `dart run w_tools_figma:figma tokens 'I1992:61890;77:12596;1:279' --file=<完整缓存> --json --skip-markdown --min=2`
- 期望：run 样式只输出实际存在的字段；只设了 textDecoration 的链接 run 显示 `deco=UNDERLINE`，不要出现空字号；tokens 的文字项能把 base 和链接 run 区分开，`--min` 不要因此把两处使用都过滤掉
- 实际：spec 该行输出 `runs: [0..15]='此為載入中gif動畫，點擊此可看' [16..17]='連結' px deco=UNDERLINE [18..31]='，動畫置中，以下圖檔為gif'`。override table 只给了 `textDecoration`，没有 `fontSize`，figma_node.dart:181 仍拼 `${fontSize}px`，产生孤立的 `px`。tokens 这边 TextStyleUsage.key 含 `_textCase` / `_textDecoration`，但 `_textsJson` 与 markdown 表都没有这两个字段，于是同一次输出两条除 samples 的 `[run]` 外完全相同的行（Noto Sans TC / 16 / 400 / Regular / 26 / 0 / LEFT / #344054 / count 1）。`--min=2` 时 counts 直接变成 `{colors:0,texts:0,...}`——两处使用被拆成各 1，全部被过滤。
- 影响：富文本链接 / 下划线是设计稿常见形态；`px` 是明显错误输出；tokens 的重复行会让用户误以为是重复数据或漏样式，AI 也可能当重复 token 删掉；`--min` 会把实际存在的样式整类丢掉。
- 建议：styleText 只在 fontSize 存在时拼 `px`（缺省回退 base style 或省略）；tokens 在 JSON 增加 `textCase` / `textDecoration` 字段，并在 markdown「样式」列合并显示；run 的样本标签用 run 文本而不是整段前缀；`--min` 的计数口径明确是「样式出现次数」还是「节点数」。
- 复现数据：节点 `I1992:61890;77:12596;1:279`（筆記內容；base 16/400；override table `{"3":{"textDecoration":"UNDERLINE"}}`）；tokens counts texts=2，但两行字段完全相同；`--min=2` 后为 0。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 缓存结构异常时未捕获异常，exit 255（不在文档退出码里）

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2 / Dart 3.12.2；合成缓存文件
- 命令 / 输入：dart run w_tools_figma:figma spec 1:1 --file=<bad1.json>
  `dart run w_tools_figma:figma spec 1:1 --file=<bad1.json>`（root 的 `absoluteBoundingBox` 缺 `x`）
  `dart run w_tools_figma:figma spec 1:1 --file=<bad2.json>`（TEXT 的 `style` 写成字符串）
- 期望：按 README「缓存损坏默认报错」给一条可读错误，退出码 1（或 2），不打印 Dart 栈
- 实际：exit 255，stderr 是 `Unhandled exception:` + 栈：`type 'Null' is not a subtype of type 'num' in type cast`（spec_renderer.dart:41）；另一例 `type 'String' is not a subtype of type 'Map<dynamic, dynamic>?' in type cast`（figma_node.dart:143）。run.dart 只 catch FigmaTokenException / StateError / FormatException / FigmaHttpException / Timeout / Http / Socket / FileSystemException，TypeError 直接穿透。
- 影响：缓存被手改、旧版本结构或部分字段缺失时 CLI 直接崩，退出码不在文档的 0~5 里；脚本会把它当成未知失败，而且看不到是哪份缓存 / 哪个节点的问题。
- 建议：run.dart 增加兜底 catch（打印「缓存结构异常：…」+ 缓存路径 + 建议 `--refresh` / `cache clean`，exit 1），或在 spec renderer 里对 bbox / style 做防御读取；退出码表补一个「内部错误」或复用 1。
- 复现数据：`bad1.json` 的 root 为 `{"id":"1:1","type":"FRAME","absoluteBoundingBox":{"y":0,"width":10,"height":10},"children":[]}`；`bad2.json` 的 node 含 `"style":"oops"`；两条命令均 exit 255，栈行如上。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 1.2.0 使用测试的低优先级问题清单（frames/tokens/cache/get/version）

- 包/版本：w_tools_figma 1.2.0
- 环境：macOS 26.6.2 / Dart 3.12.2；真实缓存 + 合成缓存
- 命令 / 输入：见下面清单，每条都可直接复制
- 期望：边界输入给出可预期的 exit 0 / 2 与不误导的输出
- 实际：
  1) `dart run w_tools_figma:figma frames --name=`（或 `--page=`，空值）：把 `includeNested` 强制为 true，输出 6768 条嵌套 FRAME（同一缓存默认是 23 条）；空过滤值应报参数错误，或等同不传。
  2) `dart run w_tools_figma:figma frames --file=<损坏/非 nodes 文件>`：stderr 提示「跳过损坏缓存」，stdout「（没有 FRAME）」，exit 0；同样输入给 `spec` 是 exit 1。显式 `--file` 解析失败应 exit 1，不要伪装成「没有画板」。
  3) `dart run w_tools_figma:figma tokens ','`：exit 0，输出空表（`数据源：``，节点 ``）；`spec ','` 是 exit 2。空 id 应统一 exit 2。
  4) `dart run w_tools_figma:figma tokens 10:1,10:1`：同一子树被统计两遍（colors count 8 vs 4），`nodeIds` 也保留重复；`fetch` 会去重排序，tokens 不一致。
  5) `dart run w_tools_figma:figma frames --page=-`：已经只列 page 为空的单节点缓存，仍打印「--page 可能漏掉它们」的警告，语义矛盾。
  6) `dart run w_tools_figma:figma cache clean --file=<cache>.json --yes`：输出 / JSON 的 path 是 `/private/tmp/...`（resolveSymbolicLinks 结果），而 `cache stats` / `cache clean` 其它分支用用户给的 `/tmp/...`；同一目录两种写法，脚本比较路径会失败。
  7) `dart run w_tools_figma:figma --version` / `-v`：exit 2 未知命令；只有 `figma version` 可用。建议加常见别名。
  8) `dart run w_tools_figma:figma get <404-url> out.png`：exit 1，消息只有「下载失败：HTTP 404」，不带 URL；批量下载时无法定位是哪个地址。
  9) `dart run w_tools_figma:figma fetch nodes <key> <id>` 缓存命中、但缓存里带 `missingNodeIds` 时，stderr 仍写「Figma 返回 null，已跳过」；这次并没有请求 Figma，文案应说明是「缓存记录的缺失」。
  10) `dart run w_tools_figma:figma tokens <id> --json --skip-markdown`：radii / spacings / text size 等数值是字符串（`"10.0"` / `"8.0"` / `"14"`），README 说「结构化数组，脚本不用解析人读文本」，但脚本仍要 parse；如果保持字符串是为了稳定，建议在 schema 明确，并补 number 字段（如 `valueNum`）。
  11) `dart run w_tools_figma:figma tokens <frameId>` 无法排除 iOS 状态栏 mock：真实页面 token 里会混入 `#000000` / `SF Pro Text`（`✏️ Time`、Wifi、Battery）；`spec` 有 `--skip-name-prefix`，tokens 没有对应能力，只能人工过滤或改缓存。建议加 `--skip-name-prefix`（复用 spec 的语义）。
- 影响：单条都不致命，但都在正常使用的边界上；1/2/3 会让脚本误判成功，6 会让路径比较失败，8 增加排查成本，11 让每个页面的 token 都混入系统控件值。
- 建议：按上面逐条修；至少 1/2/3 改成 exit 2 / exit 1，6 用规范化后的输入路径输出，11 补 `--skip-name-prefix`。
- 复现数据：1 的真实 default total=23 vs 空过滤 total=6768；3 的 `tokens ','` exit 0 空表；4 的 colors count 8 vs 4；其余均在临时 HOME / 合成缓存复现。
- 状态变更：2026-11-21 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
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
