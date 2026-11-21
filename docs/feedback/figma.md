# w_tools_figma 反馈

## 待处理









### [待处理] figma: spec 的渐变描边只输出类型，丢失 stop 颜色/角度

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：`dart run w_tools_figma:figma spec 1:2 --file=/tmp/grad_stroke_nodes.json`（一个 ELLIPSE，2px `GRADIENT_LINEAR` 描边，两个 stop：`#41627A` → `#81AECE`）
- 期望：描边列像填充一样给出渐变颜色与角度，例如 `GRAD(#41627A→#81AECE)@90° 2.0px align=INSIDE`；即使不展开角度，至少要看得到 stop 颜色。
- 实际：只输出 `GRADIENT_LINEAR 2.0px align=INSIDE`，没有任何颜色；`spec --json` 的原始 `node.strokes[0].gradientStops` 里有颜色，但人读的 Markdown 丢掉了。项目真实节点 `I2105:41663;221:7812`（Ellipse 12，44×44）也是同样输出。
- 影响：还原渐变描边时只能回 JSON 翻 `gradientStops`，人读 spec 会误以为描边是单色；Flutter 侧无法按 spec 直接实现渐变边框，容易还原成普通描边。
- 建议：把 `figmaFills` 的渐变格式化抽成共用函数给 `figmaStrokes` 复用（首/中/尾 stop、`@角度`、paint opacity）；`diff` 的可读输出也同步，避免只剩类型。
- 复现数据：/tmp/grad_stroke_nodes.json（最小 fixture，内容如下）；`spec` 输出片段：`画板 100×100，背景 -，描边 GRADIENT_LINEAR 2px align=INSIDE，阴影 -`。

```json
{"nodes":{"1:2":{"document":{"id":"1:2","type":"FRAME","name":"Gradient stroke demo","absoluteBoundingBox":{"x":0,"y":0,"width":100,"height":100},"children":[{"id":"1:3","type":"ELLIPSE","name":"Ring","absoluteBoundingBox":{"x":10,"y":10,"width":80,"height":80},"strokes":[{"type":"GRADIENT_LINEAR","gradientHandlePositions":[{"x":0.5,"y":0},{"x":0.5,"y":1},{"x":0,"y":0}],"gradientStops":[{"color":{"r":0.2549,"g":0.3451,"b":0.4078,"a":1},"position":0},{"color":{"r":0.5049,"g":0.6836,"b":0.8078,"a":1},"position":1}]}],"strokeWeight":2,"strokeAlign":"INSIDE"}]}}}}
```
- 状态变更：2026-11-21 待处理

### [待处理] figma: tokens 样例按 UTF-16 硬截 12 位，emoji 被截成孤立代理项且无省略号

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：fixture 里 TEXT 的 `characters` 为 `😀😀😀😀😀a😀`（7 个字符、13 个 UTF-16 code unit）；`dart run w_tools_figma:figma tokens 1:2 --file=/tmp/emoji_nodes.json --json --skip-markdown`
- 期望：样例是合法 Unicode；截断时带省略号（如 `「😀😀…😀」`），或者 JSON 保留完整 `characters`，只在 Markdown 里截断。
- 实际：JSON 的 `samples` 是 `「😀😀😀😀😀a\ud83d」 (1:3)`，含孤立高代理项 `\ud83d`；Markdown 里会显示替换字符/乱码。项目里更常见的截断是 `2025/10/03 20:00 到期` 被显示为 `「2025/10/03 2」`，既没有省略号，也看不出被截断。
- 影响：样例看起来像完整文案，AI/人会把它当真实内容；含 emoji 的设计稿会产出损坏的 JSON/Markdown 文本（`\ud83d` 不是合法字符）。
- 建议：按 `runes` / grapheme cluster 截断并补 `…`；JSON 的 `samples` 保留全文（或另加 `text` 字段），只对 Markdown 做视觉截断。
- 复现数据：/tmp/emoji_nodes.json（最小 fixture，TEXT characters 如上）；实际输出片段：`[["「😀😀😀😀😀a\ud83d」 (1:3)"]]`。

```json
{"nodes":{"1:2":{"document":{"id":"1:2","type":"FRAME","name":"Emoji","absoluteBoundingBox":{"x":0,"y":0,"width":100,"height":100},"children":[{"id":"1:3","type":"TEXT","name":"T","absoluteBoundingBox":{"x":0,"y":0,"width":10,"height":10},"characters":"😀😀😀😀😀a😀","style":{"fontFamily":"Noto Sans","fontWeight":400,"fontSize":14,"lineHeightPx":20,"letterSpacing":0,"textAlignHorizontal":"LEFT"},"fills":[{"type":"SOLID","color":{"r":0.2,"g":0.2,"b":0.2}}]}]}}}}
```
- 状态变更：2026-11-21 待处理

### [待处理] figma: diff 对不存在的 node 直接请求 Figma，静默消耗 1 次 Tier 1

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；项目按 Figma View seat 的 20 次/月管理额度
- 命令 / 输入：`dart run w_tools_figma:figma diff <fileKey> 9999:9999 --if-stale`；另一次 `dart run w_tools_figma:figma diff <fileKey> 9999:9999` 也同样消耗
- 期望：`--if-stale` 在没有本地基线时明确提示「无基线，首次拉取会消耗 1 次 Tier 1」；不存在的 node 至少要在错误里说明额度已被消耗，而不是让用户以为只是本地查找失败。
- 实际：两条命令各消耗 1 次 Tier 1。测试前 `usage --json` 是 `used:20, limit:20`；执行后变成 `used:22, remaining:-2`，`recent` 里多了两条 `kind:"nodes", cache:"-"`。之后才输出 `Figma 没有返回节点：9999:9999（nodeId 不存在或无权访问）`，exit 1，错误里完全不提额度。
- 影响：一个 nodeId 笔误消耗 5%–10% 的月度额度；额度用完后才发现，且错误信息看起来像纯本地失败，容易再次重试。
- 建议：先走 `findNodesCache`/索引；没有基线时在 stderr 打印「本地无缓存，将消耗 1 次 Tier 1」再请求；失败信息补「本次已消耗 1 次 Tier 1」；`--if-stale` 无基线时也明确说「需要首次拉取」。
- 复现数据：`usage --json` 前后对比（`used:20` → `used:22`，`remaining:-2`）；`recent` 两条 `2026-11-21T17:06:00 / 17:06:03 nodes -`。`9999:9999` 为不存在的 nodeId，可用任意 fileKey 复现。
- 状态变更：2026-11-21 待处理

### [待处理] figma: frames 只给 page 名不给 page id，fetch nodes <canvasId> 没有发现路径

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：`dart run w_tools_figma:figma frames --json`（项目里已有完整页面缓存和单节点缓存）
- 期望：`frames` 每行/JSON 带 `pageId`（至少在该行来自完整页面缓存时），这样可以直接 `fetch nodes <fileKey> <pageId>`；或者新增 `pages` 命令列出 `{id,name}`。
- 实际：`frames --json` 的行只有 `page` 名称，没有 page id；`frames --verbose` 只多给缓存文件路径。项目文档要求 `fetch nodes <fileKey> <canvasId>`，但 CLI 没有任何命令能列出 page id，只能回 Figma 页面复制链接。
- 影响：想只拉某一页（避免 100 MB+ 的整文件缓存）时，必须手工开 Figma 找该页链接；`--page` 只能按页面名过滤，不能拿到 id 去 fetch。
- 建议：索引里保存 CANVAS 的 id，`frames` 行增加 `pageId`（未知时 null）；或增加 `figma pages` 子命令输出 `{id,name}`，并让 `fetch nodes` 的 `--depth` 文档直接引用它。
- 复现数据：`frames --json` 的字段示例：`{"id":"1992:60055","page":"mockup（…）","cacheFile":"…-0-1-d2.json","cacheDepth":2}`，无 `pageId`；而 `spec 0:1` 能证明该页 id 是 `0:1`，说明信息就在缓存里，只是没暴露。
- 状态变更：2026-11-21 待处理

### [待处理] figma: README 说可从子目录运行，但 dart run 在子目录直接失败

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；Flutter 项目，`pubspec.yaml` 在仓库根
- 命令 / 输入：`cd lib/app && dart run w_tools_figma:figma frames`
- 期望：按 README「项目根默认从当前目录向上找 `pubspec.yaml` / `.git`，从子目录运行复用同一缓存」，应正常执行并复用根目录缓存。
- 实际：Dart 在 CLI 启动前就失败：`Could not find a file named "pubspec.yaml" in ".../lib/app".`，exit 255；在命令后加 `--root=<仓库根>` 也一样，因为 `dart run` 先按 cwd 找 pubspec，CLI 根本没被执行。
- 影响：文档承诺的子目录用法不可用；在页面目录临时查 `spec` 时只能先 `cd` 回仓库根，或改用其他入口。
- 建议：README 改成「`dart run` 必须在含 `pubspec.yaml` 的包根执行；`--root` 只用于指向另一个项目根」；如果确实要支持子目录，提供全局可执行入口/包装脚本，而不是 `dart run`。同时建议把 1.1.0 台账里「子目录运行换项目缓存 id」的闭环说明改成这个边界，避免读者以为已可用。
- 复现数据：上述命令的 stderr 原文；`pwd` 为仓库根下的 `lib/app`，其上一级存在 `pubspec.yaml`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: get 输出路径是目录时报临时文件 /tmp.tmp，错误不指向用户路径

- 包/版本：w_tools_figma 1.3.0
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：本地起 `python3 -m http.server 8765`（目录里有 `x.png`），再跑 `dart run w_tools_figma:figma get 'http://127.0.0.1:8765/x.png' /tmp`
- 期望：`get` 发现输出路径是目录时，明确报「输出路径是目录」并给出用户传入的路径；不要暴露内部临时文件名。
- 实际：`get ... /tmp` 报 `读取失败：Cannot open file（/tmp.tmp）`；换成 `get ... /tmp/getserve` 报 `读取失败：Cannot rename file to '/tmp/getserve'（/tmp/getserve.tmp）`。两条都是实现细节（`.tmp`），且第一条完全没提目标 `/tmp`。
- 影响：普通用户看到 `/tmp.tmp` 不知道是自己传了目录，也不知道该改成文件路径；两条分支文案还不一致，无法指导修复。
- 建议：写文件前检查 `File(outfile).exists && isDirectory`，报 `输出路径是目录：<outfile>`；临时文件路径只留在 debug/异常里，不进用户错误；`/tmp` 与 `/tmp/getserve` 两条分支统一文案。
- 复现数据：本地 server 日志 `/tmp/getserve.log`；`/tmp/getserve/x.png` 14 bytes；上述两条命令的 stderr 原文；传文件路径 `/tmp/getserve/out.png` 时正常输出 `saved:`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 1.3.1 的 tokens 样例截断仍会截错：内层 」 被当成结尾，ZWJ emoji 被切开

- 包/版本：w_tools_figma 1.3.1
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：`dart run w_tools_figma:figma tokens 1:2 --file=/tmp/quote_nodes.json`（TEXT characters 为 `1234567890123「引號」後續`）
- 期望：Markdown 样例只截显示文案，不破坏外层 `「…」` 包裹；文案内部的 `」` 不应被当成结尾；emoji 截断不切开 grapheme cluster，至少不在 ZWJ 序列中间下刀。
- 实际：输出 `「123456789012…」後續」 (1:3)`：把文案内部的 `」` 当成包裹结尾，丢掉 `「引號` 并多出一个 `」`。另一个 fixture（`👨‍👩‍👧‍👦` 重复 3 次 + `ABCDEF`）输出 `「👨‍👩‍👧‍👦👨‍👩‍👧…」`，第 12 个 rune 落在 ZWJ 序列中间，家庭 emoji 被切开。
- 影响：中文 UI 文案常用 `「」`，Markdown 样例会显示成错误文本；ZWJ emoji 截断后视觉上不完整，降低 token 表可信度。`tokens --json` 的 `samples` 全文是正确的，问题只在 Markdown 渲染层。
- 建议：不要在 `shortenSample` 里反解析已经包好的 `「...」`；让 collector 提供原始 characters 和 id，渲染层先截断原文再包引号。截断按 grapheme cluster（可用 `characters` 包）或至少在 ZWJ 序列边界回退；内层 `」` 不参与边界判断。
- 复现数据：/tmp/quote_nodes.json、/tmp/family_nodes.json；Markdown 输出片段 `「123456789012…」後續」 (1:3)` 与 `「👨‍👩‍👧‍👦👨‍👩‍👧…」 (1:3)`；`--json --skip-markdown` 的 samples 是完整原文。
- 状态变更：2026-11-21 待处理

### [待处理] figma: frames 对 DOCUMENT 根缓存没有按页拆分，page/pageId 全指向 DOCUMENT

- 包/版本：w_tools_figma 1.3.1
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：`dart run w_tools_figma:figma frames --file=/tmp/document_nodes.json --all --json`（fixture：DOCUMENT `0:0`，两个 CANVAS `0:1` Page One、`0:2` Page Two，各含一个 FRAME）
- 期望：按页拆分——Frame A 的 `page=Page One`、`pageId=0:1`；Frame B 的 `page=Page Two`、`pageId=0:2`。默认不加 `--all` 时至少能列出各页顶层 FRAME，或明确提示需要用 `--all` 并按页展示。
- 实际：`--all` 两行都是 `page=Doc`、`pageId=0:0`（DOCUMENT 的 id/name），不是各自的 CANVAS；默认 `frames --file=/tmp/document_nodes.json` 输出 `（没有 FRAME）`，尽管两个页面里都有 FRAME；`--page=Page One` 也筛不到。
- 影响：用 `fetch nodes <fileKey> 0:0` 拉整份文件后，`frames` 无法按页定位/过滤，新加的 `pageId` 还指错；用户会以为文件没有画板，或所有画板都在同一个叫 Doc 的页。
- 建议：`collectFrames` 对 `document.type == DOCUMENT` 单独处理：遍历 `children` 的 CANVAS，把每个 CANVAS 的 id/name 作为 pageId/page，再收集其顶层 FRAME；默认无 `--all` 时也至少输出各页顶层 FRAME（或增加 pages 列表）。
- 复现数据：/tmp/document_nodes.json；`frames --all --json` 输出 `[{id:1:2,page:Doc,pageId:0:0},{id:1:3,page:Doc,pageId:0:0}]`；默认输出 `（没有 FRAME）`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: get 对不存在的带尾斜杠输出仍报 /.tmp，未按目录意图处理

- 包/版本：w_tools_figma 1.3.1
- 环境：macOS 26.6.2 (arm64) / Flutter 3.44.9 / Dart 3.12.2；本地 CLI，无设备
- 命令 / 输入：本地 `python3 -m http.server 8765` 提供 `x.png`，再跑 `dart run w_tools_figma:figma get 'http://127.0.0.1:8765/x.png' /tmp/getnew2/`（目标目录不存在，带尾斜杠）
- 期望：按目录意图处理：报 `输出路径是目录`，或自动创建目录并写入；至少不要暴露内部 `.tmp` 文件名。
- 实际：`读取失败：Cannot open file（/tmp/getnew2/.tmp）`，exit 1。用户传的是 `/tmp/getnew2` 这个目录，错误却指向内部的 `/tmp/getnew2/.tmp`；1.3.1 的 `isDirectorySync` 检查对不存在的尾斜杠路径不生效。
- 影响：用户传一个尚不存在的目录（带尾斜杠）时，错误仍指向 `.tmp`，和上一轮 get 目录问题同类；看不出是要改成文件路径还是先建目录。
- 建议：`out.path` 以路径分隔符结尾时按目录处理；目录不存在时 `createSync(recursive: true)` 后写入，或明确报「目录不存在且未给文件名」。不要只依赖 `isDirectorySync`。
- 复现数据：/tmp/getnew2/（不存在）；上述命令的 stderr 原文；同一 server 传 `/tmp/getnew2/x.png` 时正常 `saved:`。
- 状态变更：2026-11-21 待处理

## 已闭环





| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-21 | stale / depth 提示未按 fileKey 过滤，可能指向别的 Figma 文件 | ✅ 1.3.0：staleDepthReport / fullCachePathsForDepth 按缓存文件名的 fileKey 过滤；JSON newerDepthAvailable 带 fileKey；跨文件不再误报/推荐 |
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
