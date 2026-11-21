# w_tools_figma 反馈

## 待处理














### [待处理] figma: fetch 单 id 合并缓存的回归：绕过 --check-stale、跨 depth 误标、漏用旧完整缓存

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存 `/tmp/figma-merge-home/.cache/w_tools/figma/figma-merge-root-f0273908` 中的 `nodes-K-1-1-2-2.json`、`nodes-K-9-9-d1.json`；`dart run w_tools_figma:figma fetch nodes K 1:1 --check-stale --json --root=/tmp/figma-merge-root`
- 期望：`--check-stale` 即使命中合并缓存也要访问 Tier 3 `/meta` 并返回 `cachedVersion` / `latestVersion`；`--depth=2` 不能用 `-d1` 缓存冒充；无 depth 请求应能复用旧的完整缓存
- 实际：1.1.0 新增的 `_mergedCachedNodes` 有 4 个问题：
  1. **绕过 `--check-stale`**：缓存命中走合并路径后直接返回，`latestVersion=null`、`cachedVersion=null`，但 stderr 仍打印 `# cache hit (checked /meta)`；假 client 记录 `/meta` 调用次数为 0（`/tmp/check_fetch2.dart`）。
  2. **跨 depth 误标**：只有 `nodes-K-9-9-d1.json` 时，`fetch nodes K 9:9 --depth=2` 返回 `fromCache=true`，把 d1 内容写成 `nodes-K-9-9-d2.json`；后续 spec 看到 `-d2` 不会再提示子节点缺失。
  3. **漏用旧完整缓存**：完整批量缓存 `nodes-K-1-1-2-2.json` 较旧、`nodes-K-1-1-d1.json` 较新时，`fetch nodes K 1:1` 因为 `resolveNodeCaches` 先取最新 d1、再被 `targetDepth == null` 拒绝，直接走网络（假 client calls=1，`/tmp/check_fetch5.dart`），明明完整缓存有该节点。
  4. 合并路径只在精确文件不存在时触发；精确文件已存在但只有部分 id 时不会合并其他缓存（有 `missingNodeIds`，不烧额度，但需要用户再拉一次）。
- 影响：`--check-stale` 静默失效；d2 缓存缺子节点却无警告；本可 0 次 Tier 1 的请求重新烧一次；在 20 次/月额度下影响直接。
- 建议：合并完成后照常调用 `_checkStale(updateMeta:false)` 并把版本字段写回；按 depth 选择源：`targetDepth == null` 只接受完整缓存（找不到再退回网络），`targetDepth = n` 只接受完整或同深度缓存，拒绝更浅的 `-dM`（M<n）；合并时把 `missingNodeIds` 一起带上。
- 复现数据：CLI 输出 `{"fromCache":true,"tierCalls":0,"stale":false,"cachedVersion":null,"latestVersion":null}`，同时 stderr 为 `# cache hit (checked /meta)`；`/tmp/check_fetch2.dart`（合并 check-stale）、`/tmp/check_fetch5.dart`（旧完整缓存被漏）、`/tmp/figma-merge-home`（depth 误标）均可重跑。
- 状态变更：2026-11-20 待处理

### [待处理] figma: 缓存按 nodeId 跨所有文件查找：fetch 会把别的 Figma 文件节点写成当前文件，diff 拿错基线

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存目录 `/tmp/figma-cross-home/.cache/w_tools/figma/figma-cross-root-89ed6470` 里只有 `nodes-OTHER-1-1.json`（node `1:1` name=`from-other-file`）；`dart run w_tools_figma:figma fetch nodes K 1:1 --root=/tmp/figma-cross-root --json`
- 期望：`fetch nodes <fileKey>` 只从 `<fileKey>` 自己的 nodes 缓存里复用；`diff <fileKey>` 的基线也只从该 fileKey 的缓存里找；找不到就拉取 / 建立基线
- 实际：
  1. **fetch 跨文件搬家**：`_mergedCachedNodes` 调 `resolveNodeCaches` 时没有 fileKey 参数，扫描项目下所有 `nodes-*.json`。上面的命令返回 `fromCache=true`，并写出 `nodes-K-1-1.json`，内容却是 OTHER 文件的 `from-other-file`；网络 0 次。
  2. **diff 拿错基线**：`findNodesCache` 同样只按 nodeId 找；只有 `nodes-OTHER-1-1.json` 时，`executeDiff(fileKey:'K', nodeId:'1:1')` 把 OTHER 的节点当 K 的基线，输出 `changes: [name: OTHER-OLD → K-NEW]`、`baselineCreated:false`（`/tmp/check_diff_cross.dart`）。
  3. `spec` / `tokens` 没有 fileKey 参数，多个 Figma 文件的 node id（如 `0:1`、`1:1`）碰撞时会选错缓存；目前只能靠用户手动 `--file`。
- 影响：项目同时缓存主设计稿 + 组件库/活动页时，`fetch` 会把别的文件的节点当成当前文件写进缓存，`diff` 会给出假的改版结果；这是静默的数据错误，比报错更难发现。
- 建议：缓存文件名已经带 fileKey；`fetch` / `diff` 查找时按 `nodes-<fileKey>-` 前缀过滤（或让 `resolveNodeCaches` / `findNodesCache` 接受 fileKey）。`spec` / `tokens` 若检测到同一 nodeId 出现在多个 fileKey 的缓存，给出「加 `--file=`」警告；文档补多文件场景。
- 复现数据：`fetch` 输出 `{"fromCache":true,"tierCalls":0}`，写入的 `nodes-K-1-1.json` 中 `1:1.document.name` 为 `from-other-file`；`/tmp/check_diff_cross.dart` 输出 `baselineCreated:false`、`changes: [name: OTHER-OLD → K-NEW]`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: tokens --json 的 sources 从缓存路径变成 basename，脚本无法定位文件

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma tokens 2105:41433 --json --skip-markdown`，以及 `dart run w_tools_figma:figma tokens 1:1 --file=/tmp/figma-repro/rich.json --json --skip-markdown`
- 期望：`sources` 仍然是可定位的缓存路径（绝对路径或相对项目根的路径），这样 `tokens --json` 的脚本可以打开/读取对应缓存；只有 markdown 里需要短文件名
- 实际：`tokens --json` 的 `sources` 从 1.0.0 的绝对路径变成 basename：前者只返回 `["nodes-UpyszH8lFtWYwrIXm1XAWw-2105-41433-2105-41664.json"]`，后者只返回 `["rich.json"]`。`buildTokensReport` 把 `relativeToRoot` 的结果直接塞进 `sources`，而 `relativeToRoot` 对 `~/.cache` 下的文件返回绝对路径，随后又被 `relative == cache.path ? cache.uri.pathSegments.last : relative` 换成 basename。
- 影响：任何用 `sources[0]` 打开缓存的脚本/agent 会拿到一个只存在于缓存目录里的文件名，无法定位；多个缓存 basename 相同时还会歧义。这是 1.1.0 的 JSON 行为变更，没有 schema 版本号变化提示。
- 建议：把「JSON 的 sources（路径）」和「markdown 的显示名（basename）」拆开；或让 `sources` 保持绝对/项目相对路径，另加 `sourceLabels`。若确定要改，请在 CHANGELOG / schema 里显式标 breaking。
- 复现数据：上述两条命令的 `sources` 输出；`schema/tokens.v1.json` 只声明 `sources: array<string>`，未说明已变成 basename。
- 状态变更：2026-11-20 待处理

### [待处理] figma: paint opacity 只修了 SOLID：图片/渐变填充仍丢透明度，diff 也漏图片 opacity

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro/image-opacity.json`、`gradient-opacity.json`；`dart --packages=/Users/lei0533/flutter/github_w_tools/.dart_tool/package_config.json /tmp/check_image_opacity.dart`
- 期望：paint 级 `opacity` 对 **所有** paint 类型生效；`spec` 的 `IMG` / `GRAD(...)` 标签带 `@0.50`，`diff` 能检测图片 fill 的 opacity 变化
- 实际：1.1.0 的 `figmaPaintHex` 只接入了 `figmaFills` / `figmaStrokes` 的 **SOLID** 分支：
  - 图片 fill `{"type":"IMAGE","opacity":0.5}` 输出 `IMG`，没有 `@0.50`；渐变 fill opacity 0.5 输出 `GRAD(#FF0000→#0000FF)@45°`，也没有 `@0.50`。
  - `SpecDiff._paintKey` 的 IMAGE 分支只写 `imageRef`，没有 `opacity`；脚本对 image opacity 1→0.5 返回空 changes（`[]`）。
  - 非 SOLID 的描边在 `figmaStrokes` 里也被替换成类型名，opacity 同样丢失。
- 影响：半透明图片/渐变底板会被实现成全不透明；只改图片透明度的设计改版，`diff` 仍报「没有变化」。本项目的设计稿缓存暂时没扫到 IMAGE/GRADIENT 的 opacity，但这是常见设计手法。
- 建议：`figmaFills` 对 IMAGE/GRADIENT 也把 `paint.opacity` 拼进标签（如 `IMG@0.50`、`GRAD(...)@0.50`）；`_paintKey` 的 IMAGE 分支加 `opacity=${paint['opacity'] ?? 1}`；`figmaStrokes` 的非 SOLID 分支保留 opacity。
- 复现数据：两个 fixture 的输出行；`/tmp/check_image_opacity.dart` 输出 `[]`；代码位置 `spec/figma_node.dart` 的 `figmaFills` / `figmaStrokes` / `SpecDiff._paintKey`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: 1.1.0 spec/diff 收尾项：scalar 0 圆角、clipsContent false、阴影 alpha 重复、decoration 双报

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro/zero-radius.json`、`clip.json`；`spec 2105:41433`；`/tmp/check_diff.dart`
- 期望：1.1.0 CHANGELOG 里写的「0 也显示」「clipsContent」在真实输出里无歧义，且没有重复字段
- 实际（低优先，都是 1.1.0 修复的收尾）：
  1. **scalar `cornerRadius: 0` 仍为空**：`_radiusText` 只在 `rectangleCornerRadii` 分支显示 0；只有 `cornerRadius: 0` 的节点圆角列仍空。CHANGELOG 写的是「0 也显示」，与实现不完全一致。
  2. **`clipsContent:false` 没有标记**：`_visualPrefix` 只在 true 时输出 `[clip]`，根头部只在 true 时输出 `裁切`；false 与字段缺失都无法区分。如果「只标 true」是刻意约定，请写进 spec 文档；否则建议输出 `[no-clip]` / `裁切=否`。
  3. **阴影颜色重复 alpha**：News Image 输出 `DROP_SHADOW #676767@0.08 r=4.0 a=0.08`，`@0.08` 和 `a=0.08` 是同一个值，读起来像两个不同透明度。
  4. **decoration 双报**：`/tmp/check_diff.dart` 把 `textDecoration: NONE → UNDERLINE` 同时报成 `textDecoration` 和 `text` 两条 changes（`figmaTextSpec` 也含 `deco=`）。
  5. **3+ stop 渐变丢中间色**：`/tmp/figma-repro/gradient-3stop.json`（红→绿→蓝）输出 `GRAD(#FF0000→#0000FF)@0°`，中间绿色 stop 被丢掉；1.1.0 只取了 `colors.first` / `colors.last`。
- 影响：低；主要是输出噪声、语义歧义和多 stop 渐变还原不完整，不影响取数正确性。
- 建议：scalar 0 显式显示；clip 明确 true/false 约定；`figmaEffects` 有颜色时不再追加 `a=`；`SpecDiff` 对 decoration/case 只报结构化字段（或 `text` 不再包含它们）。
- 复现数据：两个 fixture 的最后一行；`spec 2105:41433 | grep "News Image"`；`/tmp/check_diff.dart` 的 `text-decoration-only changes` 输出。
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec 根节点自身的圆角 / opacity 仍不输出，1.1.0 只修了子节点行

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823，缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma spec 'I2105:41650;497:15724;1562:38596;1:347'`
- 期望：根节点自身也有圆角信息（该节点 `rectangleCornerRadii=[4,0,0,4]`），例如头部出现 `圆角 4,0,0,4`
- 实际：1.1.0 只把 `_radiusText` 用在**子节点行**；根节点走 `rootExtras`，只加 rotation / clipsContent，头部是 `画板 18×12，背景 GRAD(#8DFC63→#97F5B4)@119°，描边 -，阴影 -，裁切`，没有圆角。该节点本身就是 root（FRAME），没有子行可承载半径，所以第一轮的真实 repro 仍未闭环。根节点的 `opacity` / `isMask` 也同样没有位置显示。
- 影响：`frames` 返回的 id 经常直接是 FRAME / RECTANGLE / 卡片；直接 `spec <该 id>` 时最外层的圆角会丢，照着输出实现就是直角。第一轮的合成样例（半径放在子 RECTANGLE 上）能过，但真实用法（root 是卡片）仍会漏。
- 建议：`rootExtras` 补 `_radiusText(frame)`（优先 `rectangleCornerRadii`，再 `cornerRadius`），顺带补 root `opacity`（<1 时）和 `isMask`；或在表格前单独输出一行「根节点：圆角 / 透明度 / mask」。
- 复现数据：上述命令的头部输出；该节点 raw `rectangleCornerRadii=[4,0,0,4]`、无 `cornerRadius`。合成 root 半径 fixture 也可复现（把 `/tmp/figma-repro/radius.json` 的 `rectangleCornerRadii` 移到 root `1:1` 上，头部仍无圆角）。
- 状态变更：2026-11-20 待处理

### [待处理] figma: 1.1.1 fetch/spec 收尾：合并后 missingNodeIds 未清、完整缓存满足 --depth 会假警告、渐变 opacity 双 @

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存 `/tmp/figma-stale-missing-home/.cache/w_tools/figma/figma-stale-missing-root-0022a650`；`dart run w_tools_figma:figma fetch nodes K 1:1,2:2 --root=/tmp/figma-stale-missing-root --json`；`dart run w_tools_figma:figma spec 9:9 --root=/tmp/figma-stale-missing-root`
- 期望：合并成功后缓存里的 `missingNodeIds` 应清掉；`fetch --depth=n` 用完整缓存满足时，不应把结果标成「depth 裁剪」并触发假的子节点缺失警告；渐变 opacity 的输出不要出现两个 `@`
- 实际：
  1. **合并后 missingNodeIds 未清理**：精确缓存 `nodes-K-1-1-2-2.json` 里原本 `missingNodeIds:["2:2"]`、nodes 只有 `1:1`；另一份 `nodes-K-2-2.json` 提供 `2:2`。`fetch nodes K 1:1,2:2` 合并成功、`--json` 的 `missingNodeIds:[]`，但写回的缓存仍是 `missingNodeIds:["2:2"]`（nodes 已含 2:2）；`FetchResult.json['missingNodeIds']` 也还是 `["2:2"]`。
  2. **完整缓存满足 --depth 被标成 dN**：只有完整批量缓存 `nodes-K-9-9-8-8.json`（含 9:9 的孙节点）时，`fetch nodes K 9:9 --depth=2` 返回 `fromCache=true`，把完整树写成 `nodes-K-9-9-d2.json`；随后 `spec 9:9` 打印 `# 数据源来自 --depth 裁剪缓存…子节点可能缺失`，但数据其实是完整的，且 `--depth` 并没有起到限制缓存大小的作用。
  3. **渐变 opacity 两个 @**：`spec 1:1 --file=/tmp/figma-repro/gradient-opacity.json` 输出 `GRAD(#FF0000→#0000FF)@45°@0.50`，角度和 opacity 都用 `@`，读起来容易把 `@45°` 当成颜色透明度。
- 影响：低。1 会让缓存元数据和 `FetchResult.json` 与实际 nodes 不一致，后续每次命中都会重复合并一次；2 只是假警告 + depth 缓存没有变小；3 是可读性。
- 建议：合并后从写回的缓存里移除已补齐的 id（没有剩余就删掉 `missingNodeIds` 字段），并让 `FetchResult.json` 同步；`targetDepth=n` 且源是完整缓存时，要么写入完整缓存名/加 `actualDepth` 元数据，要么不要复用完整缓存来满足 depth；渐变 output 用 `opacity=0.50` 或 `(@45°, @0.50)` 之类不歧义的形式。
- 复现数据：上述两条 CLI 输出；合并后缓存文件内容；`spec 9:9` 的 stderr 提示；`/tmp/figma-repro/gradient-opacity.json` 的输出行。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec 不输出 strokeCap / strokeJoin，可见 VECTOR 的圆头描边仍丢失

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:41433 --with-id`，看节点 `I2137:179640;2137:175177;269:16849`
- 期望：描边列能看到非默认的 `strokeCap` / `strokeJoin`（该节点 raw `strokeCap=ROUND`、`strokeJoin=ROUND`）
- 实际：输出行是 `| … | VECTOR | Vector | - | #545454 1.0px align=CENTER | - | … |`，没有 cap/join。该节点是 13.3×13.3 的可见 VECTOR，带 1px 圆头描边；当前 spec 只给了颜色、宽度、align，圆头/拐角信息丢失。缓存里还有 `strokeJoin=BEVEL` 的节点。
- 影响：低。图标/分隔线这类 1px 描边的端点形状会差；按像素还原时只能翻 JSON。不是本项目最大面积的问题，但属于「合理预期 spec 应覆盖」的视觉属性。
- 建议：描边列在非默认时追加 `cap=ROUND` / `join=ROUND|BEVEL`（至少 ROUND/BEVEL；默认 BUTT/MITER 可省略）；若担心表格变宽，用 `[cap=ROUND,join=ROUND]` 短标记。
- 复现数据：上述 `--with-id` 行；raw 节点 `strokeCap=ROUND`、`strokeJoin=ROUND`、`strokes=[SOLID #545454]`、bbox 13.333×13.333。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec 仍未输出 textAlignVertical / cornerSmoothing，垂直居中文本和 iOS 连续圆角会差

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 1992:78609`；`dart run w_tools_figma:figma spec 1992:98675 --with-id --file=$HOME/.cache/w_tools/figma/ureward-56cc5be6/nodes-UpyszH8lFtWYwrIXm1XAWw-0-1.json`
- 期望：文本样式输出 `textAlignVertical`（该节点 raw 是 `CENTER`，不是默认 TOP）；圆角/描边附近输出 `cornerSmoothing`（DatePicker 是 0.6，iOS 连续圆角）
- 实际：
  1. **textAlignVertical 未输出**：`1992:78609`（Frame 11286）里的 `1992:78610` `Cancel button`，raw `style.textAlignVertical=CENTER`，高度 535；spec 行只列 `Noto Sans · 400 · 16.0px · lh=25.6 · ls=0 · align=LEFT · #545454`，没有 `valign=CENTER`。
  2. **cornerSmoothing 未输出**：`1992:98914`（DatePicker INSTANCE）raw `cornerSmoothing=0.6`、`cornerRadius=13`；spec 行只有 `13.0` 圆角，没有平滑度，按输出实现会变成普通圆角而不是 iOS 连续圆角。
- 影响：低/中。垂直居中的大段文本会被默认按顶部实现，位置会整体偏；DatePicker 这类 iOS 风格卡片的圆角形状会差一点。不是本轮主路径阻塞，但属于像素还原会碰到的属性。
- 建议：`figmaTextSpec` 在 `textAlignVertical` 非默认（CENTER/BOTTOM）时追加 `valign=CENTER|BOTTOM`；`spec` 在 `cornerSmoothing > 0` 时追加 `smooth=0.60`（或 `cornerSmoothing`）。默认 TOP / 0 可省略。
- 复现数据：上述两条 spec 行；raw `1992:78610` style `textAlignVertical=CENTER`；`1992:98914` `cornerSmoothing=0.6`、`cornerRadius=13`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 有完整缓存时 fetch --depth=n 仍走网络，1.1.1 严格 depth 的额度代价

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存 `/tmp/figma-stale-missing-home/.cache/w_tools/figma/figma-stale-missing-root-0022a650` 里只有完整缓存 `nodes-K-9-9-8-8.json`（含 9:9），没有 `nodes-K-9-9-d2.json`；`dart run w_tools_figma:figma fetch nodes K 9:9 --depth=2 --root=/tmp/figma-stale-missing-root --json`；对照假 client `/tmp/check_depth_full.dart`
- 期望：完整缓存是 depth 请求的超集，可以 0 次 Tier 1 满足 `--depth=2`（直接返回完整缓存文件，或写 d2 时标记 actualDepth 并抑制假警告）
- 实际：`_pickNodesCache` 的 `targetDepth != null` 分支只接受 `depth == targetDepth`，`depth == null` 的完整缓存被跳过；命令没有命中缓存，直接走网络（隔离 HOME 的模板 token 下 exit 4；假 client calls=1）。CHANGELOG 已明确这是「只接受同深度缓存」的取舍。
- 影响：中。对 View/Collab 座位 20 次/月来说，先拉过完整页面、再想用 `--depth=2` 收窄缓存时会白烧 1 次 Tier 1；而完整缓存本来包含所需全部子节点。上一轮 low 条目的「完整缓存满足 depth 会假警告」修好后，代价从假警告变成了额度消耗。
- 建议：`targetDepth != null` 时也接受 `depth == null` 的完整缓存，但**返回完整缓存文件本身**（不要写成 `-dN`），并在 stderr 说明「完整缓存已满足 depth=2」；或者给完整缓存加 `actualDepth: null` 元数据，让 spec 不把 dN 当裁剪缓存。不要用完整树冒充 `-dN`，也不要直接跳过。
- 复现数据：上述命令 exit 4（未命中缓存）；`/tmp/check_depth_full.dart` 抛 `Bad state: NETWORK`、`calls=1`；缓存里只有 `nodes-K-9-9-8-8.json`，没有 d2。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 多个完整缓存分摊 ids 时 fetch --depth=n 仍走网络，_fullCacheForIds 只接受单文件

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存里 `nodes-K-1-1.json`（完整，含 1:1）和 `nodes-K-2-2.json`（完整，含 2:2）；`dart run w_tools_figma:figma fetch nodes K 1:1,2:2 --depth=2 --root=<tmp> --json`；对照假 client `/tmp/check_depth_split.dart`
- 期望：两个 id 都能由完整缓存满足，应 0 次 Tier 1 返回（合并成一份完整结果，或返回包含两者的缓存）
- 实际：`_fullCacheForIds` 只接受「所有 ids 都在同一个完整缓存文件」；这里 `files.length == 2`，返回 null。随后 `_mergedCachedNodes(targetDepth=2)` 只接受同深度 d2 缓存，没有，于是走网络（假 client calls=1）。
- 影响：低。单个完整页面缓存不受影响；但如果按画板分别拉过完整缓存（`nodes-K-1-1.json`、`nodes-K-2-2.json`），再对多个 id 用 `--depth=2`，会白烧 1 次 Tier 1；20 次/月下边缘但真实。
- 建议：`_fullCacheForIds` 不必要求单文件：若每个 id 都能在某个完整缓存里找到，可以合并成一份完整结果（写入一个 `nodes-K-<ids>.json` 或返回临时合并结果）再返回；或者退而求其次，在 stderr 提示「已分别命中完整缓存，但 depth 合并暂不支持」。
- 复现数据：`/tmp/check_depth_split.dart` 输出 `split full depth2 error=Bad state: NETWORK calls=1`；两个缓存均为 depth null 的完整文件。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 多个完整缓存合并 depth 结果会覆盖同名完整缓存，丢掉未请求节点

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存 `nodes-K-1-1-2-2.json`（完整，含 1:1、2:2、3:3）和更新的 `nodes-K-1-1.json`（完整，含 1:1）；`dart run w_tools_figma:figma fetch nodes K 1:1,2:2 --depth=2 --root=<tmp> --json`；对照 `/tmp/check_depth_overwrite.dart`
- 期望：合并完整缓存时保留已有缓存里未请求的节点（3:3），或不要覆盖同名完整缓存
- 实际：`_fullCacheForIds` 在 `files.length != 1` 时把请求的 id 拼成 `nodes-K-<ids>.json` 并直接 `store.write`，没有读已有目标文件；命令返回 `fromCache=true`、`calls=0`，但 `nodes-K-1-1-2-2.json` 被覆盖成只剩 `1:1,2:2`，原有的 `3:3` 丢失。
- 影响：中。缓存里的其他节点被静默删掉；后续 `spec`/`fetch` 3:3 会重新拉（消耗 Tier 1），或者误以为该节点不存在。不是设计源数据丢失，但属于缓存数据损坏。
- 建议：写合并结果前先 `store.read(full)`；若已有 nodes，用 `existing nodes + 新 nodes` 合并（新数据覆盖同名 id）再写，保留未请求 id；或者目标已存在且包含全部请求 id 时直接返回目标，不重建；也可以用不冲突的合并文件名，避免覆盖。
- 复现数据：上述命令后缓存节点 keys 从 `(1:1,2:2,3:3)` 变为 `(1:1,2:2)`；`/tmp/check_depth_overwrite.dart` 输出 `batch nodes after: (1:1, 2:2)`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: fetch --depth 命中完整缓存时 --check-stale 的 stderr 不再标 checked /meta

- 包/版本：w_tools_figma 1.1.1
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：临时缓存 `nodes-UpyszH8lFtWYwrIXm1XAWw-2105-41433-2105-41664.json`；`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 2105:41433,2105:41664 --depth=2 --check-stale --root=<tmp> --json`
- 期望：`--depth` 命中完整缓存且带 `--check-stale` 时，stderr 同时说明「完整缓存已满足 depth」和「checked /meta」；文档写的是缓存命中时仍会访问 `/meta` 并标 `checked /meta`
- 实际：stderr 只打印 `# cache hit (完整缓存已满足 --depth): …`；JSON 里 `latestVersion=2421134302405946194` 说明 `/meta` 确实调用了，但文本没有任何 `checked /meta` 标记。`fetch_handler.dart` 的 `depthSatisfiedByFull` 分支先命中，跳过了 `options.checkStale ? '# cache hit (checked /meta)'` 的 else 分支。
- 影响：低。只影响诊断/日志：用户从 stderr 看不出 stale 检查是否执行；JSON 消费者仍能拿到 `latestVersion`。和文档「缓存命中时输出标 checked /meta」不一致。
- 建议：`depthSatisfiedByFull` 分支在 `options.checkStale` 时追加 `（checked /meta）`，或统一输出 `# cache hit (完整缓存已满足 --depth; checked /meta): …`；也可以把 checked 状态放进 JSON 的显式字段。
- 复现数据：上述命令 stderr 一行；JSON `{"fromCache":true,"tierCalls":0,"cachedVersion":null,"latestVersion":"2421134302405946194"}`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: --check-stale / --if-stale 用 _meta 而不是缓存 version，旧缓存被判成最新

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区，含 1.1.1 未提交修复）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 0:1 --check-stale --json`；`dart run w_tools_figma:figma diff UpyszH8lFtWYwrIXm1XAWw 0:1 --if-stale --json`
- 期望：用缓存文件自己的 `version` 与 `/meta` 的最新版本比较。`nodes-...-0-1.json` 的 `version=2415310932909825311`（2026-10-28，缓存写于 11-03），线上是 `2421134302405946194`，应报 `stale:true`；`diff --if-stale` 应该继续拉取并比较。
- 实际：`fetch` 输出 `cachedVersion=2421134302405946194`、`latestVersion=2421134302405946194`、`stale:false`；`diff` 直接输出 `{"skipped":true,"changes":[],"nodes":[]}`。stderr 仍是 `# cache hit (checked /meta)`。也就是说，**10 月的缓存被当成 11 月的最新版本**。
- 原因：`FetchCommand._checkStale` 只读 `_meta-<fileKey>.json`，不读 cache JSON 顶层的 `version`；而任何一次同 fileKey 的 fetch（例如 11-20 拉 2105 画板）都会把 meta 写成 latest，之后所有旧缓存都被「洗白」。`_mergedCachedNodes` 写出的 `nodes-<key>-<id>.json` 又只写 `{nodes}`，顶层没有 `version`（真实 `nodes-...-2105-41433.json` 的 keys 是 `["nodes"]`；该测试生成文件已在 2026-11-21 08:06 清理，用单 id fetch 可重建），连兜底都没有。
- 影响：设计稿改版后按项目流程先跑 `--check-stale` 会看到「没变」，`diff --if-stale` 静默跳过；20 次/月额度下会漏掉改版，后面按旧缓存实现就是错的。0:1 缓存实际已落后两个版本。
- 建议：版本判断优先用 cache 顶层的 `version`（没有才退回 `_meta`，并明确标记 `cachedVersion:null`）；合并/拆分写缓存时保留源文件的 `name` / `version` / `lastModified`，或在 meta 里按 cache 文件记录 version。补一个「同 fileKey 两份不同 version 缓存」的单测。
- 复现数据：`/tmp/figma-repro-2026-11-21/stale.out`。当前有效 repro 是 `0:1`：cache `version=2415310932909825311`（10-28）、`_meta=2421134302405946194`（11-13），CLI 仍报 `{"fromCache":true,"tierCalls":0,"stale":false,"cachedVersion":"2421134302405946194","latestVersion":"2421134302405946194"}`，`diff --if-stale` 为 `skipped:true`。注意：`stale.out` 里的 `2137` 段是 08:10 刷新前的输出；`2137` 已在 2026-11-21 08:10 用 `--refresh` 更新到 `2421134`，现在不再是 repro；`2105-41433` 的合并测试文件也已在 08:06 清理。
- 复测（2026-11-21 09:10）：`0:1` 精确缓存与合并单 id 缓存均已修复；合并后的旧批量 repro 返回 `stale=true` 且保留顶层 `version`。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec 的目标本身是 TEXT 时 markdown 只有空表，文字/字体/字号/颜色全丢

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma spec 'I2137:180397;497:15727'`；`dart run w_tools_figma:figma spec 1:10 --file=/tmp/figma-repro-2026-11-21/text.json`
- 期望：目标节点本身是 TEXT 时，markdown 至少给出 `characters`、字体族、字重、字号、行高、字距、对齐、颜色（以及富文本 runs），例如 `Header title` 应输出 `“優惠券” Noto Sans · 700 · 18.0px · lh=25.2 · ls=0 · align=CENTER · #3F3F3F`。
- 实际：两条命令都只输出头部（`# Header title (…)` / `# Rich (…)` + `画板 …，背景 #…`）和一个空表；表里没有任何行，文字、字体、字号、颜色全丢。文字规格只在 spec 父节点、作为子行时才出现。`--json --node-only` 的 `node` 里有原始 style，但默认的 markdown 使用者拿不到。
- 影响：`spec --with-id` 刚把 text nodeId 暴露出来，直接 `spec <textId>` 反而得到空表；agent/人很容易以为这个节点没有文字，或者被迫再 spec 整个父画板找那一行。`spec` 作为「节点 → 规格」的入口，对 TEXT 这个最常用的叶子节点不成立。
- 建议：目标节点本身也渲染成一行（复用子行渲染逻辑），或在头部追加 `characters + figmaTextSpec(frame)`；leaf 节点（TEXT / RECTANGLE / VECTOR）都适用。补一个「spec TEXT id」的单测。
- 复现数据：真实输出见 `/tmp/figma-repro-2026-11-21/spec-text-target.txt`；synthetic 输出同文件。两个输出都只有表头 `| x,y | w×h | … |`，无数据行。
- 复测（2026-11-21 08:25）：TEXT 目标已输出 characters + 文字规格（真实 id 与 synthetic 都通过）。
- 状态变更：2026-11-21 待处理

### [待处理] figma: opacity=0 未按不可见处理：spec 不标隐藏、tokens 照常计入；也没有 --skip-hidden

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:41433`；`dart run w_tools_figma:figma tokens 2105:41433 --json --skip-markdown`；`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro-2026-11-21/text.json`
- 期望：节点自身或祖先 `opacity:0` 与 `visible:false` 一样属于「视觉不存在」：spec 应标 `**隐藏**` 或按开关跳过；tokens 不应统计其子树。
- 实际：
  1. **spec 不标 opacity 0**：`2105:41433` 里 3 个 `Frame 15768`（`opacity:0`）只显示 `0.00`，下面的「使用」按钮和文字行完全正常，没有 `**隐藏**`；`I2137:180397;497:15725`（Header content）里 `opacity:0` 的右侧 icon 也只靠 `0.00` 识别，下面的 VECTOR 行完全正常。synthetic `Opacity zero` 下的 `INVISIBLE` 文字同样正常输出。
  2. **tokens 照常计数**：`#409C35` count=4，samples 是 `button (I2137:179640;2137:175181)` 等 3 个藏在 `opacity:0` 下的按钮；文字样式 `「使用」` count=3 也全部来自这 3 个不可见按钮。synthetic 里 `#00FF00` 和 `INVISIBLE` 文字也被 tokens 收进去。
  3. **没有 `--skip-hidden`**：`2105:41433` 的 spec 共 483 行数据行，其中 288 行带 `**隐藏**`（一组隐藏插画的 Vector），占 60%；当前只能靠 `--skip-name-prefix` 按名字猜，无法按可见性过滤。
- 影响：不可见的重复按钮/状态栏/插画会被实现进页面；设计 token 被不可见内容污染（颜色次数、文字样式次数都偏大）；spec 输出一半以上是噪声，agent 读规格时容易漏掉真正的可见行。
- 建议：在 walk 里传 `effectiveOpacity`（祖先 opacity 连乘），`effectiveOpacity == 0` 与 `visible:false` 一样处理：spec 标隐藏，tokens 直接跳过；增加 `spec --skip-hidden`（可默认关闭以保持兼容），并同步修正 `tokens`。opacity 只到 0 才隐藏，`0.8` 这类仍应保留。
- 复现数据：`/tmp/figma-repro-2026-11-21/opacity.out`；真实 `spec 2105:41433` 的 `| 299.0,570.8 | 60.0×38.0 | FRAME |       Frame 15768 | - | - | - |  | 0.00 |  |` 后面紧跟 `“使用”` 的 TEXT 行；`spec I2137:180397;497:15725` 的 `I2137:180397;497:15730` icon 也是 `0.00` + 正常子行；`tokens` 的 `#409C35` / `「使用」` 输出见文件。
- 复测（2026-11-21 08:25）：opacity=0 已标 `**隐藏**`，tokens 已跳过，`--skip-hidden` 使 2105 从 483 行降到 179 行且无隐藏行。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 文字样式覆盖不全：斜体与 rich run 的字号/字体/字距丢失，tokens 漏 run 颜色

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro-2026-11-21/text.json`；`dart run w_tools_figma:figma tokens 1:1 --file=/tmp/figma-repro-2026-11-21/text.json --json --skip-markdown`；`dart /tmp/figma-repro-2026-11-21/diff_probe.dart`（SpecDiff.fontStyle Regular→Italic）
- 期望：
  - 斜体文字输出 `italic` / `fontStyle=Italic`；`textAutoResize`、`paragraphSpacing` 等非默认文字属性也应可见。
  - 富文本 run 的样式差量包含字号、字体、字距、大小写、装饰，而不只是 `fontWeight` + 颜色；例如 `＋HK$500 將於 …` 的金额段是 18px、700、`#C0061A`。
  - `tokens` 统计富文本 run 的颜色/字号；只在 run 里出现的 `#C0061A` 应出现在颜色表。
- 实际：
  1. `Italic` 节点的 style 是 `fontStyle:Italic`，spec 行只有 `Noto Sans · 400 · 14px · lh=22.4 · ls=0 · align=LEFT · #123456`，没有 italic；tokens 的 text key 也只按 family/size/weight/lineHeight/letterSpacing/align/color 分组，斜体和正常体合并成一条。`SpecDiff` 对 `fontStyle Regular→Italic` 返回 `[]`。
  2. `Rich` 节点的 run override 是 `{"fontWeight":700,"fontSize":18,"fills":[#C0061A]}`，spec 只输出 `[8..23]='將於 2026/10/03 到期' 700 #C0061A`，**没有 18px**；`styleText` 只拼 `fontWeight` 和 `color`，`styleKey` 也只比较这两个字段，所以 run 内字号/字体/字距变化会被合并掉。
  3. tokens 只统计 base style：颜色只有 `#123456`（count=3），没有 run 的 `#C0061A`；文字样式只有 `14/400/#123456`，没有 `18/700/#C0061A`。
- 影响：斜体被实现成正常体；富文本里的金额/强调字号被按正文实现；只出现在 run 里的品牌色不会进入设计 token 表；设计稿只改 run 字号时 diff 也看不到。
- 建议：`figmaTextSpec` 增加 `fontStyle`（非 Regular 时输出 `italic`）以及 `textAutoResize` / `paragraphSpacing`（非默认时）；run 的 `styleKey` / `styleText` 覆盖 fontSize/fontFamily/letterSpacing/textCase/textDecoration；`TokenCollector._collectText` 遍历 `characterStyleOverrides` + `styleOverrideTable`，把 run 的颜色/字号计入 token。diff 复用同一套 `figmaTextSpec` 后自动生效。
- 复现数据：`/tmp/figma-repro-2026-11-21/spec.txt`、`tokens.json`、`diff_probe.out`；关键行：`| … | TEXT | Rich | … | runs: [0..7]='＋HK$500 ' [8..23]='將於 2026/10/03 到期' 700 #C0061A |`（无 18px）；`Italic text` 行无 italic；tokens colors 只有 `#123456`。
- 复测（2026-11-21 09:40）：spec 的 italic / run 18px、tokens 的 `#C0061A` 与 run `18/700`、tokens 的 `fontStyle`（JSON + markdown）均已修复。
- 状态变更：2026-11-21 待处理

### [待处理] figma: --with-layout 的 padding 顺序有歧义，layoutSizing/positioning 未输出；diff 也漏这些布局变化

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 'I2137:180397;497:15725' --with-layout --with-id`；`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro-2026-11-21/text.json --with-layout --with-id`；`dart /tmp/figma-repro-2026-11-21/diff_probe.dart`
- 期望：
  - padding 四个值有明确顺序/标签；例如 `left=16,right=16,top=8,bottom=8` 应输出 `padding=(l:16,r:16,t:8,b:8)` 或 CSS 顺序，而不是裸 `16.0,16.0,8.0,8.0`。
  - `--with-layout` 同时覆盖 `layoutSizingHorizontal/Vertical`、`layoutGrow`、`layoutPositioning=ABSOLUTE`、`constraints`、`layoutWrap`、`counterAxisSpacing`；至少要能看出「这个是绝对定位 / 这个是 fill / hug」。
  - `diff` 能检测这些布局字段的变化，以及子节点顺序变化（z-order / 视觉顺序）。
- 实际：
  1. 真实 `I2137:180397;497:15725`（Header content，left/right=16、top/bottom=8）输出 `padding=16.0,16.0,8.0,8.0`。代码顺序是 left,right,top,bottom，但文档只写「padding」，没有标签；按 CSS `top,right,bottom,left` 或 Flutter `fromLTRB(left,top,right,bottom)` 都会读错。
  2. 真实 `I2137:180416;221:7811`（Group 21）和 `I2137:180413;269:17036`（News Item Logo Container）raw `layoutPositioning=ABSOLUTE`，`--with-layout` 的布局列是空的，看不到 ABSOLUTE；`layoutSizing*` / `layoutGrow` / `constraints` / `layoutWrap` / `counterAxisSpacing` 全部没有。synthetic `Padding test` 的 `layoutSizingVertical=HUG`、`layoutSizingHorizontal=FILL`、`layoutGrow=1` 也都不输出。
  3. `SpecDiff` 对这些字段全部 `MISSED`：`layoutSizingHorizontal FIXED→FILL`、`layoutGrow 0→1`、`layoutPositioning AUTO→ABSOLUTE`、`constraints LEFT→STRETCH`、`textAutoResize NONE→HEIGHT`、`paragraphSpacing 0→8`、`layoutWrap NO_WRAP→WRAP`、`counterAxisSpacing null→8` 都返回 `[]`；子节点 `A,B → B,A` 也返回 `changes=0 nodes=0`（代码注释说「顺序变化不计为改动」，但视觉顺序确实变了）。
- 影响：`16,16,8,8` 很容易被实现成上下 16、左右 8（或反过来）；绝对定位的卡片图标会进普通 Row；设计稿只改 fill/hug 或子项顺序时 diff 报「没有变化」，实现会按旧布局走。
- 建议：padding 输出带标签或采用 CSS 顺序并写进 README；`_layoutSpec` 增加上述字段；`SpecDiff._layout` 与单独的 `order` 比较（至少检测 children id 序列变化，或在文档里明确「不比较顺序」）。补一组「只改 layoutSizing」和「只交换两个 child」的 diff 单测。
- 复现数据：`/tmp/figma-repro-2026-11-21/spec-layout.txt`（`padding=8,12,4,20`、`Absolute child` 无 ABSOLUTE）与 `diff_probe.out`（9 个 MISSED + reorder 0）。
- 复测（2026-11-21 09:10）：padding 标签、auto-layout 与非 auto-layout 的 sizing/positioning/constraints、diff 字段与子节点 `order` 均已修复。
- 状态变更：2026-11-21 待处理

### [待处理] figma: individualStrokeWeights 只输出边字母，1px/2px 不可区分；diff 检测不到单边宽度变化

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 2137:180183 --with-id`；`dart /tmp/figma-repro-2026-11-21/diff_probe.dart`（individualStrokeWeights bottom 1→2）
- 期望：`individualStrokeWeights` 的**值**可见，例如 `#409C35 2.0px align=INSIDE [B=2.0]` 或 `insets=(t:0,r:0,b:2,l:0)`；`diff` 能检测单边宽度 1→2。
- 实际：真实节点 `I2137:180411;274:20309`（active tab 指示条）raw `individualStrokeWeights={"top":0,"right":0,"bottom":2,"left":0}`，spec 输出 `#409C35 1.0px align=INSIDE [B]`；旁边 1px 的 tab 也输出 `[B]`，两者无法区分。`figmaStrokes` 只把 key 的首字母拼成 `[B]`，值丢了；`SpecDiff` 对 bottom 1→2 返回 `[]`（`_strokeKey` 复用同一个 `figmaStrokes`）。
- 影响：本项目 active tab 的下划线设计是 2px，照 spec 实现会变 1px；设计稿只改单边宽度时 diff 看不到，像素还原会差。
- 建议：输出 `[B=2.0]`（或 `insets=(t:0,r:0,b:2,l:0)`），没有值的边可省略；`SpecDiff._strokeKey` 使用带值的描述。补「单边 1→2」的单测。
- 复现数据：`spec` 行见上；`diff_probe.out` 最后一行 `individualStroke bottom1->2 changes=0`；raw 值来自 `2137:180183` 缓存里的 `I2137:180411;274:20309`。
- 复测（2026-11-21 08:25）：spec 输出 `[B=2]`；diff 对 bottom 1→2 已返回 1 条 change。
- 状态变更：2026-11-21 待处理

### [待处理] figma: frames 只列 FRAME，SECTION/COMPONENT 无法发现；单节点缓存的 page 为空导致 --page 漏

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma frames --file=/tmp/figma-repro-2026-11-21/types.json`；`dart run w_tools_figma:figma frames --file=/tmp/figma-repro-2026-11-21/types.json --all`；真实缓存 `nodes-UpyszH8lFtWYwrIXm1XAWw-0-1-d2.json`（23 个 SECTION）
- 期望：`frames` 至少能发现设计稿里可当作「节点入口」的容器：SECTION、COMPONENT、COMPONENT_SET；或提供 `--types=FRAME,SECTION,COMPONENT` 之类的开关。`--page` 过滤也不应静默漏掉 `fetch nodes <frameId>` 拉下来的单节点缓存。
- 实际：
  1. synthetic `types.json` 的 CANVAS 下有 `SECTION Section A`、`COMPONENT Button Component`、`FRAME Top Frame`。默认 `frames` 只输出 `Top Frame`；`--all` 只多输出 section 里的 `Frame in section`，`Section A` 和 `Button Component` 都没有。
  2. 真实 `0-1-d2` 缓存里有 23 个 SECTION，`frames --all` 一个都不列；只有 FRAME 会被 `collectFrames` 收进去。
  3. `fetch nodes <frameId>` 拉下来的单节点缓存没有 CANVAS 父节点，`frames` 的 `page` 列是 `-`（例如 `2137:172367`、`2137:180183`）；`frames --page=…` 用 `page` 子串过滤，会静默漏掉这些本来就是按画板拉下来的缓存。
- 影响：SECTION / COMPONENT 页面无法通过 CLI 找 nodeId，只能回 Figma 里复制；`--page` 过滤对「按 nodeId 拉过」的缓存失效，用户会以为画板不在缓存里。
- 建议：`frames` 增加 `--types`（默认 FRAME 保持兼容），至少让 SECTION/COMPONENT/COMPONENT_SET 可作为入口；`page` 未知时显示 `(unknown)` 并在 `--page` 提示「有 N 个缓存缺少 page」，或把完整缓存里的 page 归属补进单节点缓存。
- 复现数据：`/tmp/figma-repro-2026-11-21/types.json` 的两条输出（默认 1 行、`--all` 2 行，缺 Section A / Button Component）；真实缓存类型统计 `SECTION=23`。
- 复测（2026-11-21 09:10）：frames 已列 SECTION/COMPONENT，JSON 有 `type`；`_indexVersion=7` 会重建旧索引，`--page` 提示正常。
- 状态变更：2026-11-21 待处理

### [待处理] figma: spec/tokens/fetch 的 ids 不 trim，写成 "1:1, 1:16" 会报找不到并可能白烧一次 Tier 1

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec '1:1, 1:16' --file=/tmp/figma-repro-2026-11-21/text.json`；`dart run w_tools_figma:figma tokens '1:1, 1:16' --file=/tmp/figma-repro-2026-11-21/text.json --json --skip-markdown`；`dart run w_tools_figma:figma fetch nodes <fileKey> '1:1, 1:16'`（缓存里有 1:1 和 1:16）
- 期望：逗号分隔的 ids 允许空格，等价于 `1:1,1:16`。
- 实际：`spec` / `tokens` 报「在缓存里找不到节点： 1:16」（带前导空格的 id 原样进查找）；`fetch` 也把 ` 1:16` 当成新 id，缓存命不中，会走网络；在真实 token 下就是一次白烧的 Tier 1（View/Collab 20 次/月）。
- 影响：用户/agent 按常见写法 `id1, id2` 输入就失败或烧额度；错误信息只显示带空格的 id，容易误以为节点不存在。
- 建议：把 ids 的解析收敛成一个 helper：`split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)`，`spec` / `tokens` / `fetch nodes` / `fetch images` 共用；缓存 key 也用 trim 后的 id。
- 复现数据：上述 `spec` / `tokens` 退出码 1，stderr 为 `在缓存里找不到节点： 1:16；…`；同一份文件用 `1:1,1:16` 正常。
- 复测（2026-11-21 08:25）：`spec` / `tokens` 的 `1:1, 1:16` 已正常命中。
- 状态变更：2026-11-21 待处理

### [待处理] figma: url 只用 contains('figma.com') 判域名且允许空 fileKey，notfigma.com 也会通过

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma url --json 'https://notfigma.com/design/KEY/x?node-id=1-2'`；`dart run w_tools_figma:figma url --json 'https://figma.com.evil.com/design/KEY/x?node-id=1-2'`；`dart run w_tools_figma:figma url --json 'https://www.figma.com/design//x?node-id=1-2'`；`dart run w_tools_figma:figma url --json 'https://www.figma.com/design/KEY/x?node-id='`
- 期望：只接受 Figma 域名的链接；`fileKey` 不能为空；空 `node-id` 视为没有 nodeId（`null`），而不是空字符串。
- 实际：前两条都返回 `fileKey=KEY, nodeId=1:2`；`/design//x` 返回 `fileKey=""`；`node-id=` 返回 `nodeId:""`。原因是 `parseFigmaUrl` 只做 `input.contains('figma.com')`，没有校验 `uri.host`，也没检查 `segments[keyIndex + 1]` 是否为空。
- 影响：把 `notfigma.com` / 子域伪装链接当成 Figma 链接，后续 `fetch` 会拿一个错的 fileKey 去请求；空 fileKey/空 nodeId 让 `url` 输出不可用的 `fileKey=` / `nodeId=`，脚本还要自己判空。
- 建议：用 `uri.host == 'figma.com' || uri.host.endsWith('.figma.com')`；`segments[keyIndex + 1].isNotEmpty` 才接受；`node-id` 为空时返回 `null`（JSON 输出 `nodeId: null`）。补 4 个解析单测。
- 复现数据：上述四条命令的 JSON 输出。
- 复测（2026-11-21 09:10）：host / 空 fileKey / 大写域名 / 空 nodeId 均已修复（空 nodeId 输出 `null`）。
- 状态变更：2026-11-21 待处理

### [待处理] figma: fetch 合并/重写缓存只写 {document}，丢掉 per-node components/componentSets/styles/schemaVersion

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 2105:41433`；`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 2105:41433,2105:41664 --depth=2`；`dart --packages=/Users/lei0533/Work/SamprasCN/Flutter/28_uReward/01_Git/ureward/.dart_tool/package_config.json /tmp/figma-repro-2026-11-21/merge_meta_probe.dart`
- 期望：`fetch` 命中/合并缓存写回时，每个 `nodes.<id>` 条目保持 Figma 返回的完整对象：`document` + `components` + `componentSets` + `schemaVersion` + `styles`；不要把已有完整条目降级成只有 `document`。
- 实际：
  1. 真实批量缓存 `nodes-UpyszH8lFtWYwrIXm1XAWw-2105-41433-2105-41664.json` 在本轮 `--depth=2` 命中后被重写（mtime 2026-11-21 07:45:03，size 2,289,599→2,264,278），两个节点的 keys 都只剩 `[document]`（2026-11-21 08:06 已用 `--refresh` 恢复；下面是恢复前实测，`merge_meta_probe.dart` 可重放）。
  2. 同期未被重写的 `nodes-UpyszH8lFtWYwrIXm1XAWw-2137-172367.json` 仍是 `[document, components, componentSets, schemaVersion, styles]`（components=23、styles=15）；`nodes-...-2105-41432.json` 也是完整 keys（components=40、styles=27）。说明不是 Figma 不返回，而是合并/重写路径丢的。
  3. 合成复现：`merge_meta_probe.dart` 用 fake client 返回完整 node；`fetch nodes K 1:1,2:2` 写入的批量缓存 keys 是完整的；再 `fetch nodes K 1:1` 命中合并后，`nodes-K-1-1.json` 的 `1:1` 只剩 `[document]`。
- 影响：缓存不再镜像 API，`components` / `styles` / `componentSets` / `schemaVersion` 静默丢失；当前 `spec`/`tokens`/`diff` 只读 `document`，所以暂时不影响输出，但任何后续用样式名/组件元数据的命令或外部缓存消费者都拿不到；同时 `--depth` 命中会重写完整缓存，造成 mtime/size churn，让 `frames --verbose` 的 `fetchedAt` 看起来像刚拉过。
- 建议：`_mergedCachedNodes` / `_fullCacheForIds` 不要构造 `{'document': doc}`，而是保留源条目 `{...sourceEntry, 'document': doc}`；合并多份来源时，如果新来源只有 `document`，不要覆盖已有的完整条目（或至少保留原 `components`/`styles`）。补「合并后 per-node keys 不减少」的单测。
- 复现数据：`/tmp/figma-repro-2026-11-21/merge_meta_probe.out`；真实缓存 keys 对照（恢复前）：`2105-41433` = `['document']`，`2137-172367` = `['document','components','componentSets','schemaVersion','styles']`；批量缓存重写前后 size 见上。
- 复测（2026-11-21 09:10）：per-node keys 与合并缓存顶层 `version` / `name` / `lastModified` 均已保留。
- 状态变更：2026-11-21 待处理

### [待处理] figma: fetch 合并单 id 仍只写 {nodes}；--check-stale 对合并缓存返回 cachedVersion:null/stale:false

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 08:25 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 2137:172367 --check-stale --json`；`dart --packages=/Users/lei0533/Work/SamprasCN/Flutter/28_uReward/01_Git/ureward/.dart_tool/package_config.json /tmp/figma-repro-2026-11-21/merged_stale_probe.dart`
- 期望：`fetch nodes K <单个 id>` 从批量缓存合并时，写出的单 id 缓存要保留批量的顶层 `version` / `name` / `lastModified`；`--check-stale` 用这个 version 比较，旧批量缓存应报 `stale:true`。没有 version 时至少应报「未知」，不能报 `stale:false`。
- 实际：
  1. 真实命令：`2137:172367` 的旧单 id 缓存已删除、只剩当前批量缓存；`fetch nodes ... 2137:172367 --check-stale` 走合并路径，创建 `nodes-UpyszH8lFtWYwrIXm1XAWw-2137-172367.json`，顶层 keys 只有 `['nodes']`，输出 `{"fromCache":true,"tierCalls":0,"stale":false,"cachedVersion":null,"latestVersion":"2421134302405946194"}`。
  2. 合成 repro：临时缓存里批量文件 `version=old`、`_meta` 是 `latest`；`fetch nodes K 1:1 --check-stale` 合并后输出 `stale:false cachedVersion:null latest=latest`，同时 `/meta` 确实调用了 1 次。也就是说，**旧批量 → 合并单 id 缓存后，stale 判定又失效了**。
- 原因：`FetchCommand._mergedCachedNodes` 仍返回 `{'nodes': nodes}`，没有顶层 version；`_fetch` 合并分支把 `cachedVersion: '${merged['version'] ?? ''}'`（空字符串）传给 `_checkStale`；`_checkStale` 里 `cached = cachedVersion ?? (previous == null ? '' : ...)` 把空字符串当成已知版本，既不回退 `_meta`，也永远算不出 stale。
- 影响：用户按单个 nodeId 拉过一次后，后续 `--check-stale` 在这个缓存上永远报「没变」；批量缓存变旧时会被静默漏掉。精确文件缓存（如 0:1）已修复，但合并路径没有覆盖，属于上一轮第 1 条的同根残留。
- 建议：`_mergedCachedNodes` 写回 `{...sourceTopLevel, 'nodes': nodes}`（至少 `version` / `name` / `lastModified`）；`_checkStale` 在 `cachedVersion` 为空时回退到 `_meta`（或返回 `stale:null` / `cachedVersion:null` 并明确「无法判断」），不要把空字符串当版本。补「旧批量 + 单 id 合并 + --check-stale」单测。
- 复现数据：`/tmp/figma-repro-2026-11-21/merged_stale_probe.out`；真实输出见上；合成输出 `fromCache=true tierCalls=0 stale=false cachedVersion=null latest=latest`，创建文件 top keys `[nodes]`。
- 复测（2026-11-21 09:10）：合并缓存已保留顶层 `name/version/lastModified`，旧批量 repro 返回 `stale=true`；本条已修复，待发版关闭。
- 状态变更：2026-11-21 待处理

### [待处理] figma: tokens 的 texts 仍未输出 fontStyle（斜体与正常体可能变成两条相同行）

- 包/版本：w_tools_figma 1.1.1（本机 path 检出，2026-11-21 08:25 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma frames --json --limit=3`；`dart run w_tools_figma:figma tokens 1:1 --file=/tmp/figma-repro-2026-11-21/text.json --json --skip-markdown`；`dart run w_tools_figma:figma spec 2137:180183 --with-layout --with-id`；`dart --packages=/Users/lei0533/Work/SamprasCN/Flutter/28_uReward/01_Git/ureward/.dart_tool/package_config.json /tmp/figma-repro-2026-11-21/diff_probe.dart`；`dart run w_tools_figma:figma url --json 'https://WWW.FIGMA.COM/design/KEY/x?node-id=1-2'`；`dart run w_tools_figma:figma spec 1:13 --file=/tmp/figma-repro-2026-11-21/text.json --skip-hidden`
- 期望：1.1.1 的收尾修复在升级路径和边界上也生效：旧 `_nodes-index` 也能产出 `frames --json` 的 `type`；tokens 的文字样式能区分斜体与 rich run 字号/字重；非 auto-layout 节点的 `position=ABSOLUTE` / constraints 也能显示；diff 能报子节点顺序变化；url 大小写不敏感且空 node-id 为 null；`--skip-hidden` 对显式指定的隐藏目标给出正确结果。
- 实际：
  1. **frames 旧索引没有 type**：真实 `frames --json --limit=3` 的行只有 `{id,name,depth,...}`，没有 `type`；`_nodes-index.json` 里已缓存的 frames 条目是旧格式，`_indexVersion` 仍是 6，升级后不会重建。用 `frames --file=/tmp/figma-repro-2026-11-21/types.json --all --json` 才有 `type`。（本机索引已在 2026-11-21 08:32 重建，现在 `type` 出现；上面是旧索引升级前的实测。）
  2. **tokens `fontStyle` 输出仍缺**：synthetic `tokens ... text.json` 的 `colors` 已包含 run 的 `#C0061A`，`texts` 也已有 run `18/700/#C0061A`；但 Rich 的 `14/400` 与 Italic 的 `14/400` 输出成两条**完全相同**的 `count=1` 行，因为 `TextStyleUsage._fontStyle` 只进了 key，`_textsJson` / markdown 都没有输出它。
  3. **非 auto-layout 的布局仍空**：真实 `I2137:180416;221:7811`（GROUP）raw `layoutPositioning=ABSOLUTE`，`--with-layout` 的布局列是空；synthetic `Absolute child`（FRAME，无 layoutMode，`layoutPositioning=ABSOLUTE`）同样空。原因是 `_layoutSpec` 在 `layoutMode` 不是 HORIZONTAL/VERTICAL 时直接 `return ''`，后面的 sizing / positioning / constraints 都不执行。
  4. **diff 仍不报子节点重排**：`diff_probe` 里 `A,B → B,A` 输出 `changes=0 nodes=0`；代码注释仍写「顺序变化不计为改动」。auto-layout / z-order 改变时，视觉顺序会变但 diff 报「没有变化」。
  5. **url 大小写 / 空 nodeId**：`https://WWW.FIGMA.COM/...` 被拒（`uri.host` 保留大写，检查是大小写敏感的）；`https://www.figma.com/design/KEY/x?node-id=` 返回 `{"fileKey":"KEY","nodeId":""}`，而不是 `nodeId:null`。
  6. **skip-hidden 对隐藏目标报找不到**：`spec 1:13 --file=text.json --skip-hidden`（1:13 是 opacity=0 子树里的 TEXT）exit 1，stderr `在缓存里找不到节点 1:13`；不加 `--skip-hidden` 能正常输出。`_pruneHidden` 把目标节点自身也剪掉了，错误信息误导为节点不存在。
- 影响：升级后 frames JSON 的 `type` 不可用（新 SECTION/COMPONENT 行无法区分）；tokens 仍无法从文字表看出斜体/强调字号；非 auto-layout 的绝对定位图标/分组仍会被当普通流布局；diff 漏重排；url 边界和 `--skip-hidden` 目标有误报/误错。
- 建议：1) 把 `_indexVersion` 升到 7（或检测 frames 条目缺 `type` 时重建）；2) `TextStyleUsage` 增加 `fontStyle`，并把 run 的 fontSize/fontWeight/family 计入 `texts`（或文档明确只收 run 颜色）；3) `_layoutSpec` 不要提前 return，改成按字段存在性拼接；4) diff 比较 children id 序列或明确文档化「不比较顺序」；5) `uri.host.toLowerCase()`，`node-id` 空串转 null；6) `_pruneHidden` 保留目标节点，或给「目标被隐藏」的明确错误。
- 复现数据：`/tmp/figma-repro-2026-11-21/diff_probe.out`、`/tmp/figma-repro-2026-11-21/text.json`；真实 frames/tokens/spec/url 输出见上。
- 复测（2026-11-21 09:40）：其余 5 项（frames type、非 auto-layout、diff order、url、skip-hidden）已修复；本条 `fontStyle` 的 JSON + markdown 输出也已修复，重复行消失。
- 状态变更：2026-11-21 待处理

### [待处理] figma: 无 version 的旧缓存 --check-stale 仍把 _meta 当缓存版本，报 cachedVersion:latest/stale:false

- 包/版本：w_tools_figma 1.2.0（本机 path 检出，2026-11-21 09:40 工作区）
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823；`~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart --packages=/Users/lei0533/Work/SamprasCN/Flutter/28_uReward/01_Git/ureward/.dart_tool/package_config.json /tmp/figma-repro-2026-11-21/versionless_stale_probe.dart`
- 期望：缓存顶层没有 `version` 时，`--check-stale` 不能声称缓存就是最新；应返回 `cachedVersion:null` / `stale:null`（或明确的「缓存版本缺失，无法判断」），让用户知道需要 `--refresh`。
- 实际：临时缓存 `nodes-K-1-1.json` 只有 `{nodes}`、没有 version；`_meta` 是 `latest`；fake `/meta` 返回 `latest`。命令输出 `fromCache=true stale=false cachedVersion=latest latest=latest`，顶层 keys 仍是 `[nodes]`。也就是说，**无 version 的旧缓存被直接当成 latest**。
- 原因：`_checkStale` 在 `cachedVersion` 为空时回退到 `_meta`，并把回退值当作 `cachedVersion` 返回；`stale = cached != latest`，于是必然 `false`。1.1.1 之前合并出来的单 id 缓存就是没有顶层 version 的。
- 影响：升级到 1.2.0 后，旧的合并缓存仍会被 `--check-stale` 判成最新；用户可能继续按旧数据实现，直到手动 `--refresh`。新合并缓存已保留 version，但旧缓存没有迁移路径。
- 建议：区分「缓存版本未知」和「缓存是最新」：无 version 时返回 `cachedVersion:null`、`stale:false` 之外再给 `unknown:true` / stderr 警告，或直接提示先 `--refresh`；也可以把 `_meta` 的 `lastTouchedAt` 和缓存文件的 `lastModified` 比较，但不要把 meta version 冒充成 cache version。
- 复现数据：`/tmp/figma-repro-2026-11-21/versionless_stale_probe.out`；输出 `fromCache=true stale=false cachedVersion=latest latest=latest topKeys=[nodes]`。
- 复测（2026-11-21 10:20）：1.2.0 已输出 `versionUnknown:true`、`cachedVersion:null`，stderr 提示需要 `--refresh`；本条已修复，待发版关闭。
- 状态变更：2026-11-21 待处理

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
