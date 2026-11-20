# w_tools_figma 反馈

## 待处理

### [待处理] figma: spec 不输出 rectangleCornerRadii，逐角圆角被当成没有圆角

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823，缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma spec 'I2105:41650;497:15724;1562:38596;1:347'`
- 期望：圆角列显示 Figma 的逐角半径 `[4,0,0,4]`（TL/TR/BR/BL），或至少 `4,0,0,4`
- 实际：圆角列为空。`spec_renderer.dart:90` 只读 `cornerRadius`；该节点只有 `rectangleCornerRadii`，没有 `cornerRadius`。
- 影响：只有某两只角是圆的卡片（反向圆角）会被实现成四角直角；`diff` / `tokens` 都读逐角半径，只有 `spec` 漏，导致还原阶段返工。
- 建议：圆角列优先输出 `rectangleCornerRadii`（四个值按 TL/TR/BR/BL），没有时才用 `cornerRadius`；0 也显示，避免和「没有圆角」混淆。
- 复现数据：真实节点 I2105:41650;497:15724;1562:38596;1:347 与 /tmp/figma-repro/radius.json
  - 真实节点 `I2105:41650;497:15724;1562:38596;1:347`（Frame 2），`rectangleCornerRadii=[4,0,0,4]`，无 `cornerRadius`；spec 行尾为 `... | GRAD | - | - |  |  |  |`。
  - 最小复现 `/tmp/figma-repro/radius.json`：RECTANGLE，`rectangleCornerRadii=[8,8,0,0]`；`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro/radius.json` 圆角列为空。
  - 对照：`tokens 1:1 --file=/tmp/figma-repro/radius.json` 的「圆角」输出 `| 8 | 2 |`，说明数据在、只有 spec 没读。
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec / tokens 忽略 paint 级 opacity，半透明遮罩被输出成不透明；diff 也检测不到

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823，缓存 `~/.cache/w_tools/figma/ureward-56cc5be6`
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:42138`（同节点再跑 `tokens`）
- 期望：填充 / 描边的 paint 级 `opacity` 进入颜色输出（如 `#757575@0.80`），或至少单独标注；`tokens` 表头承诺「带透明度的色值以 @0.20 形式单列」也应当成立
- 实际：`figmaHex`（`spec/figma_node.dart:7`）只读 `color.a`，完全忽略 Paint 的 `opacity`。Frame 45 的 SOLID 填充 `#757575` + `opacity:0.8` 被输出成不透明 `#757575`；`tokens` 同样输出 `#757575`，没有 `@0.80`。描边同理（Ellipse 6 的 `opacity:0.4` 被输出为实色 `#71E582`）。
- 影响：80% 遮罩会被实现成全不透明灰底；颜色 token 也失真。更严重的是 `SpecDiff._paintKey` 也用 `figmaHex`，只改 paint opacity 时 `diff` 返回 0 条 changes（见 `/tmp/check_diff.dart` 输出 `opacity-only changes: []`），设计改版会被漏掉。
- 建议：`figmaHex` 接收 paint 并乘上 `paint.opacity`（`a * opacity`）后输出 `@xx`；`--map` 查语义名时只取基础 hex；`SpecDiff._paintKey` 把 `paint.opacity` 纳入 key。
- 复现数据：节点 2105:42138 与 /tmp/figma-repro/paint-opacity.json
  - 真实节点 `2105:42138`（Frame 45）：`fills=[{type:SOLID, opacity:0.8, color:#757575}]`；`spec` 头部输出 `画板 375×997，背景 #757575`。
  - 最小复现 `/tmp/figma-repro/paint-opacity.json`（RECTANGLE，`opacity:0.8`，颜色 `#757575`）：`spec 1:1 --file=...` 输出 `#757575`；`tokens` 输出 `#757575`。
  - `dart --packages=.../.dart_tool/package_config.json /tmp/check_diff.dart` → `opacity-only changes: []`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec 漏掉 rotation / isMask / clipsContent / 阴影颜色 / 文字 decoration / 渐变细节

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 2105:41433`（以及最小样例 `/tmp/figma-repro/{rotation,mask,clip,textdeco}.json`）
- 期望：`spec` 能回答设计稿还原必需的视觉属性：旋转角度、`isMask`、`clipsContent`、阴影颜色、`textDecoration` / `textCase`、渐变 stops / 方向
- 实际：这些属性全部不输出：
  1. **rotation**：真实 Group 31 `rotation=-0.344°`；spec 只有 bbox，没有角度。合成样例 `/tmp/figma-repro/rotation.json` 同样不显示。
  2. **isMask**：真实 `2105:41435` `isMask:true`；合成样例 `/tmp/figma-repro/mask.json` 只输出一个普通 RECTANGLE，没有 mask 标记。
  3. **clipsContent**：真实根画板 `2105:41433` `clipsContent:true`；spec 头部只有背景/描边/阴影，没有裁切。合成样例 `/tmp/figma-repro/clip.json` 的 `clipsContent:false` 也无法区分。
  4. **阴影颜色**：真实 News Image 的输出是 `DROP_SHADOW r=4.0 a=0.08 spread=3.0 off=(0.0,1.0)`，但 Figma 颜色是 `#676767`（rgb 0.4025）而不是黑色；实现方会默认用黑色阴影。
  5. **文字 decoration / case**：合成 `/tmp/figma-repro/textdeco.json`（`UNDERLINE` + `UPPER`）输出 `“UNDER” ...`，不显示下划线/大写；真实缓存里的 `STRIKETHROUGH` 同样不显示。
  6. **渐变细节**：真实 `2105:41636`（Member card section）是 `GRADIENT_LINEAR`，stops 为 `#F0FF00 → #58CFFB`，还有 handles；spec 只输出 `GRAD`，无法按输出还原渐变（`diff` 反而已经比较 stops）。
- 影响：这些正是本项目 `docs/agents/design-fidelity.md` 里要求逐项核对、且历史上反复返工的属性（尤其遮罩、阴影颜色、旋转、渐变）；spec 不给就只能猜或手工翻 JSON。
- 建议：在 spec 表格/头部补 `rotation`（非 0 时）、`isMask`、`clipsContent`、阴影颜色；文字列补 decoration/case；渐变输出 stops + 方向/handles（可截断但至少给首尾色与角度）。
- 复现数据：真实节点 2105:41433、2105:41636、News Image；最小样例见 /tmp/figma-repro/（mask.json 输出普通 RECTANGLE，无 mask 标记）。
- 状态变更：2026-11-20 待处理

### [待处理] figma: diff 只改 rotation / isMask / clipsContent / 文字 decoration 时仍输出「没有变化」

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart --packages=/Users/lei0533/flutter/github_w_tools/.dart_tool/package_config.json /tmp/check_diff.dart`
- 期望：设计文件版本变了、节点只有 rotation / isMask / clipsContent / textDecoration 变化时，`diff` 至少报告对应字段变化
- 实际：`SpecDiff._compare`（`diff/spec_diff.dart:91-130`）只比较 size/position/layout/visible/opacity/fills/strokes/effects/radius/name/text；`figmaTextSpec` 不含 decoration/case；节点级没有 rotation / isMask / clipsContent / blendMode。脚本对每项单独改一个属性，全部返回空 changes：
  - `opacity-only changes: []`（paint opacity，另见单独条目）
  - `rotation-only changes: []`
  - `isMask-only changes: []`
  - `clipsContent-only changes: []`
  - `text-decoration-only changes: []`
- 影响：`diff` 是「设计稿改版后改了什么」的唯一入口；这些属性单独变化时 CLI 会打印「没有变化」，直接漏掉改版。注意 `diff --if-stale` 只能判断文件版本，版本变了之后仍要靠 `SpecDiff`，此时会给出假的「没有变化」。
- 建议：把 rotation / isMask / clipsContent / textDecoration / textCase / blendMode 纳入比较 key，并让 `SpecChange` 的字段名可读（如 `rotation: -0.34 → 0`）。
- 复现数据：`/tmp/check_diff.dart` 的完整输出见上；合成节点在 `/tmp/figma-repro/{rotation,mask,clip,textdeco}.json`。代码位置：`spec_diff.dart:91-130`（`_compare`）、`spec_diff.dart:101-110`（现有字段）。
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec / tokens 选旧的完整缓存，忽略更新的 --depth 缓存；frames 却显示新数据

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：dart run w_tools_figma:figma spec 1:1 --root=/tmp/figma-stale-root（完整前置见下方）
  ```
  HOME=/tmp/figma-stale-home PUB_CACHE=~/.pub-cache \
    dart run w_tools_figma:figma init --root=/tmp/figma-stale-root
  # 写入 nodes-K-1-1.json（旧，name=OLD-FULL）和 nodes-K-1-1-d1.json（新 1.1s，name=NEW-DEPTH）
  dart run w_tools_figma:figma frames --all --root=/tmp/figma-stale-root
  dart run w_tools_figma:figma spec 1:1 --root=/tmp/figma-stale-root
  ```
- 期望：`spec` 使用包含同一 nodeId 的最新缓存，或至少提示「另有更新的 --depth 缓存，本次用的是旧完整缓存」
- 实际：`frames --all` 显示 `NEW-DEPTH`，`spec 1:1` 显示 `OLD-FULL`，且没有任何提示。根因是 `nodes_index.dart` 的 `resolveNodeCaches` 固定 `preferFullDepth: true`：只要存在未裁剪的完整缓存，就永远优先它，不看 mtime。
- 影响：`fetch nodes --refresh --depth=…` 后，完整缓存仍是旧版；`spec` / `tokens` / `diff` 的基线都读旧完整缓存，用户以为已刷新、实际按旧设计实现（`diff` 还会把旧基线当对比基准）。本项目就有 `nodes-…-0-1.json` 与 `nodes-…-0-1-d2.json` 并存。
- 建议：选缓存时同时看 mtime：若更新的 depth 缓存包含目标 id，优先用新缓存并在 stderr 提示子节点可能缺失；或至少提示「存在更新的 depth 缓存，本次使用旧完整缓存」。`fetch --refresh --depth` 也应提示完整缓存未更新。
- 复现数据：临时缓存目录 `/tmp/figma-stale-home/.cache/w_tools/figma/figma-stale-root-544221cb/`；`full mtime 1795165137.83`、`depth mtime 1795165138.94`；输出分别为 `OLD-FULL` / `NEW-DEPTH`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: frames --name 在默认范围只查顶层，嵌套命中时静默返回「（没有 FRAME）」

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma frames --name=會員卡`
- 期望：名称过滤应在「所有画板」里找（或至少提示还有嵌套命中），因为本项目的画板大量挂在 TABLE / mockup 页面下面
- 实际：输出 `（没有 FRAME）`，exit 0；同一命令加 `--all` 能列出 6 个名称含「會員卡」的画板。`frames` 先按顶层收窄再过滤，嵌套命中被静默丢掉，没有任何提示。
- 影响：正常使用里按名字找画板会得到「不存在」的错误结论；消费方 `docs/agents/design-fidelity.md` 还写着「默认 frames 会显示（没有 FRAME），直接加 --all（或用 --name= 过滤）」——按文档用 `--name` 仍然找不到。AI 按此会改去 fetch，浪费 Tier 1。
- 建议：`--name` / `--page` 在全部 FRAME 上过滤（命中嵌套时标注 `nested`，或在默认输出里直接包含命中项）；若坚持只查顶层，空结果时检查 `--all` 命中数并打印「匹配的 N 个画板在嵌套层级，加 --all」。退出码可保持 0。
- 复现数据：frames --name=會員卡 输出「（没有 FRAME）」；加 --all 命中 6 条
  ```
  $ dart run w_tools_figma:figma frames --name=會員卡
  （没有 FRAME）
  $ dart run w_tools_figma:figma frames --all --name=會員卡 | wc -l
  6 条（01 member card-目前尚無會員卡 / 01-我的會員卡 / 02 member card-有會員卡 / …）
  ```
- 状态变更：2026-11-20 待处理

### [待处理] figma: 从子目录运行 figma CLI 会换项目缓存 id，frames / spec 报没有缓存

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`cd tool && dart run w_tools_figma:figma spec 2105:41433`
- 期望：从仓库子目录运行也应复用仓库根的项目缓存（或在报错里给出当前识别的 root / cache 目录与 `--root` 用法）
- 实际：项目 id 按 CWD 计算（`cache/cache_paths.dart` 的 `projectId` 取 `root.absolute.path`），于是变成 `~/.cache/w_tools/figma/tool-d24ff065`，报 `… 里没有 nodes-*.json`；`frames` 的报错甚至不带路径。`.dart_tool` / `pubspec.yaml` / `.git` 都不参与向上查找。
- 影响：IDE 终端、`cd tool` 后跑命令、CI 在子目录执行时都会看不到已有缓存；若此时执行 `fetch nodes`，会把数据拉到另一个项目 id 下，再跑一次又消耗 Tier 1；排查成本高。
- 建议：默认从 CWD 向上找最近的 `pubspec.yaml` / `.git` 作为项目根（或 `.w_tools` 标记），并允许 `--root` 覆盖；报错里打印实际 root、cache 目录和 `--root` 示例。
- 复现数据：cd tool 后 frames 输出「缓存里没有 nodes-*.json，先跑 fetch nodes」，spec 输出 tool-d24ff065 缓存目录
  ```
  $ cd tool && dart run w_tools_figma:figma spec 2105:41433
  /Users/lei0533/.cache/w_tools/figma/tool-d24ff065 里没有 nodes-*.json，先拉一次节点树缓存
  $ cd tool && dart run w_tools_figma:figma frames
  缓存里没有 nodes-*.json，先跑 fetch nodes
  # 加 --root=<repo> 后正常
  ```
- 状态变更：2026-11-20 待处理

### [待处理] figma: /meta 的 last_touched_at 没被读取，_meta 文件缺设计最后修改时间

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 2105:41433 --check-stale`，然后看 `~/.cache/w_tools/figma/ureward-56cc5be6/_meta-Upysz….json`
- 期望：`/meta` 返回的 `last_touched_at` 被记录到 `_meta-<key>.json`，`--check-stale` / `diff` 能显示设计最后修改时间
- 实际：`commands/file_meta.dart:23` 读的是 `file['lastTouchedAt']`，而 Figma `/v1/files/<key>/meta` 返回的字段是 `last_touched_at`（snake_case）。因此 `lastTouchedAt` 永远是 null，`_meta` 文件只有 `version` / `checkedAt`，没有 `lastTouchedAt`。
- 影响：无法判断「缓存是几点拉的、设计最后什么时候改的」，`--check-stale` 的诊断信息少一半；排查「设计改了吗」时只能再查 Figma。
- 建议：读 `file['last_touched_at']`（可兼容 camelCase 作为 fallback），并在 `fetch --json` / `usage` 或 `diff` 输出里暴露 `lastTouchedAt`。
- 复现数据：线上 `/meta` 的 `file` keys 为 `[name, folder_name, last_touched_at, creator, last_touched_by, thumbnail_url, editorType, version, link_access, url, role]`，`last_touched_at=2026-11-13T01:03:43.385Z`，`lastTouchedAt=None`；本地 `_meta-….json` 只有 `{"version":"2421134302405946194","checkedAt":"…"}`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: fetch nodes 只按整串 ids 精确命中缓存；拆分 / 损坏 / 部分缺失都会重烧 Tier 1

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：dart --packages=/Users/lei0533/flutter/github_w_tools/.dart_tool/package_config.json /tmp/check_fetch.dart
  ```
  dart --packages=/Users/lei0533/flutter/github_w_tools/.dart_tool/package_config.json /tmp/check_fetch.dart
  dart --packages=/Users/lei0533/flutter/github_w_tools/.dart_tool/package_config.json /tmp/check_partial.dart
  ```
- 期望：缓存命中应覆盖「节点已在某个 nodes 缓存里」的情况；缓存损坏应报错（或明确提示）而不是静默重拉；部分节点缺失的警告应可重复看到
- 实际：
  1. **只按整串 ids 精确命中**：先 `fetch nodes K 1:1,2:2`（命中缓存，0 次调用），再 `fetch nodes K 1:1` → 仍发起网络请求（脚本输出 `fetch [1:1] error=... calls=1`）。实际会消耗 1 次 Tier 1，尽管 `1:1` 就在缓存里。
  2. **损坏缓存静默当未命中**：`CacheStore.read` 捕获 `FormatException` 后返回 null；`fetch` 于是重新请求（脚本 `fetch corrupt ... calls=1`），不会提示缓存损坏。
  3. **部分缺失不持久化**：第一次 `fetch [1:1,2:2]` 中 `2:2` 返回 null，警告 `missing=[2:2]` 并把只含 `1:1` 的缓存写成文件名 `…-1-1-2-2.json`；第二次同参数直接缓存命中，`missing=[]`（`/tmp/check_partial.dart` 输出），用户会以为 `2:2` 已存在。
- 影响：在 View/Collab 座位 20 次/月的前提下，拆分 id、损坏缓存、重复 fetch 都可能白烧一次；部分缺失的警告消失后，AI 会继续按「节点存在」实现。
- 建议：命中时按单个 id 在所有 nodes 缓存里查（或维护 id→file 索引）并合并结果；损坏缓存只在显式 `--refresh` 时才覆盖，默认报错并指向 `cache clean`；把 `missingNodeIds` 写进缓存 sidecar / `--json`，缓存命中时也返回。
- 复现数据：/tmp/check_fetch.dart 输出 fromCache true、calls 0/1；/tmp/check_partial.dart 输出 first missing [2:2]、second missing 空。
- 状态变更：2026-11-20 待处理

### [待处理] figma: usage 在预算设为 1 时 0 次也报「已用 0/1」接近上限

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2（隔离 HOME：`/tmp/figma-init-home`）
- 命令 / 输入：`dart run w_tools_figma:figma usage --set=1` → `dart run w_tools_figma:figma usage`
- 期望：0 次调用时不应提示「已用 0/1」接近上限
- 实际：输出 `Tier 1 calls this month (2026-11): 0 / 1` 后紧跟 `⚠️ 已用 0/1，本月剩余 1 次`。`usage_handler.dart:75` 用 `used >= (limit * 0.8).floor()`，limit=1 时阈值是 0，恒为真。
- 影响：预算设得小时第一条 usage 就报警，警告失去意义；低优先级但容易误导。
- 建议：阈值改为 `used > 0 && used * 5 >= limit * 4`（或至少 `used >= max(1, (limit * 0.8).floor())`）；`--set=1` 这种边界补一个单测。
- 复现数据：隔离 HOME 下先 `usage --set=1`，再 `usage`，输出 `Tier 1 calls this month (2026-11): 0 / 1` + `⚠️ 已用 0/1，本月剩余 1 次`；`--json` 为 `{"used":0,"limit":1,"remaining":1}`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: cache clean --file=./x 被误判越界；--all 确认只统计当前项目体积

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2（隔离 HOME：`/tmp/figma-init-home`）
- 命令 / 输入：dart run w_tools_figma:figma cache clean --file=./nodes-dummy.json --yes --root=/tmp/figma-init-test（前置见下方）
  ```
  echo '{}' > ~/.cache/w_tools/figma/<项目id>/nodes-dummy.json
  dart run w_tools_figma:figma cache clean --file=./nodes-dummy.json --yes --root=/tmp/figma-init-test
  dart run w_tools_figma:figma cache clean --all
  ```
- 期望：`--file=./nodes-dummy.json` 指向的就是当前项目缓存目录内的文件，应该允许删除；`--all` 的确认提示应给出「所有项目」的总体积
- 实际：
  1. `--file=nodes-dummy.json` 和绝对路径都能删；`--file=./nodes-dummy.json` 被拒绝，exit 2：`--file 只能删当前项目缓存目录下的文件：./nodes-dummy.json`。`cache_handler.dart:182` 用字符串比较 `file.parent.absolute.path != root.path`，没有规范化 `.` / `..` / 符号链接。
  2. `cache clean --all`（不带 `--yes`）的提示是「当前项目 14 个文件 / 148.7 MB」，而实际会删所有项目；无法判断误删范围。
- 影响：开发者在缓存目录里复制 `--file` 路径时最容易带 `./`，被拒绝后只能猜正确格式；`--all` 的确认信息不足，误删他人项目缓存时没有预期。
- 建议：用 `path.canonicalize` / `File.resolveSymbolicLinks` 后判断「是否在当前项目缓存目录内」；`--all` 不带 `--yes` 时统计所有项目目录的总文件数/体积再提示。
- 复现数据：上述命令输出；`cache clean --file=./nodes-dummy.json` exit 2，`--file=nodes-dummy.json` exit 0。`cache clean --all` 提示「当前项目 14 个文件 / 148.7 MB」。
- 状态变更：2026-11-20 待处理

### [待处理] figma: frames 中文列错位；同名旧画板无拉取时间；无缓存提示不带路径

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma frames`、`frames --all`、`frames --verbose`
- 期望：表格列可读、同名画板能看出新旧、没有缓存时能直接看到去哪个目录找
- 实际：
  1. **中文列错位**：`padRight` 按 Dart 字符数补齐，CJK 显示宽度是 2；`導航欄優惠券` 行和 `page / id / name` 表头对不齐，`--all` 时更明显。
  2. **同名旧画板没有时间**：默认输出里 `01優惠券-可使用` 出现 3 次（`2105:42140`、`2137:172367`、`2137:180183`），`--verbose` 只多给缓存路径，没有拉取时间/大小，无法判断哪份是最新设计。`_mergeFrameRow` 只在同一 id 上合并，不同 id 的同名画板全留。
  3. **无缓存报错不带路径**：`frames` 报 `缓存里没有 nodes-*.json，先跑 fetch nodes`，不显示当前项目缓存目录（`spec` / `tokens` 会带路径），从子目录运行时分不清是哪个项目。
- 影响：找画板时容易选中旧版本；中文表在终端里难读；缓存目录分裂时难以定位。
- 建议：按显示宽度补齐（CJK 算 2）；`--verbose`/`--json` 增加 `fetchedAt`（缓存 mtime）或 `cacheAge`，同名不同 id 时给提示；无缓存错误统一带上 `store.dir.path`。
- 复现数据：`frames` 输出中 `page` 列宽度与 `導航欄優惠券` 不一致；`frames --verbose | grep 01優惠券-可使用` 三行；`cd tool && frames` 的错误文本。
- 状态变更：2026-11-20 待处理

### [待处理] figma: tokens 的样例名不可定位，--out 把本机绝对缓存路径写进文档

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma tokens 2105:41433,2105:41664 --out=/tmp/tokens-gen.md --map=figma_tokens.yaml`
- 期望：token 样例能定位到节点（至少带父级路径），生成到仓库的文档不应写死本机绝对路径，`--min` 说明不要自相矛盾
- 实际：
  1. **样例不可定位**：颜色表的「出现位置」输出 `Vector / Vector / Vector`、`Frame 11312 / Frame 11312 / Frame 11312`；`_label` 只取节点名，同名 Vector 无法区分。改成 `父级 > 名称` 或带 nodeId 更有用。
  2. **绝对路径写进文档**：markdown 头 `> 数据源：`/Users/lei0533/.cache/w_tools/figma/.../nodes-….json``；按文档 `tokens … --out=docs/design-tokens.md` 生成并提交会泄漏本机路径，也会随机器变化产生 diff。
  3. **`--min` 文案矛盾**：结尾写「出现 1 次的值可以用 `--min=1` 查看全部（默认也会列出）」——默认就是 min=1，前后半句冲突。
- 影响：颜色 token 表定位困难；生成的文档不可复现、带本机路径；文档说明让人怀疑默认值。
- 建议：samples 存相对路径（`父节点名 > 节点名`）或 nodeId；markdown 数据源用相对于项目根的路径 / 缓存文件名；`--min` 文案改成「默认 min=1，列出全部；只关心高频值用 --min=3」。
- 复现数据：`/tmp/tokens-gen.md` 的 `## 颜色` 表与文件头；`Vector / 「2025/10/03 2」 / Vector` 等行。
- 状态变更：2026-11-20 待处理

### [待处理] figma: diff 首次运行没有基线，stdout 仍输出「没有变化」

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：清掉某个 nodeId 的 nodes 缓存后执行 `dart run w_tools_figma:figma diff <fileKey> <nodeId>`
- 期望：没有旧缓存时明确说「首次 diff，已建立基线（没有可比对象）」，`--json` 里有 `firstBaseline: true` / `baselineCreated: true`
- 实际：`DiffCommand.run` 在没有 previous 时返回 `changes=[] nodes=[] tierCalls=1`；`diff_handler.dart:151-152` 只判断 `result.isEmpty`，stdout 打印 `没有变化（nodeId）`。只有 stderr 的一行 `# 首次 diff：没有旧缓存可比，本次只写入基线` 说明真相；`--json` 里也没有基线标记。
- 影响：清缓存后第一次 diff（或 CI 首次跑）会把「没有基线」误读成「设计没变」，`--json` 消费者无法区分 `tierCalls=1 + changes=[]` 是首跑还是真没变。
- 建议：返回 `baselineCreated` 标记；文本输出 `已建立基线（无旧缓存，未做比较）`；`--json` 增加 `firstBaseline` / `baseline: null` 字段。
- 复现数据：`commands/diff_command.dart` 的 `previous == null` 分支返回空结果；`cli/diff_handler.dart:151-152` 的 `if (result.isEmpty) printLine('没有变化…')`。
- 状态变更：2026-11-20 待处理

### [待处理] figma: spec / tokens 的 Markdown 表格未转义 | 与换行；富文本按字符展开

- 包/版本：w_tools_figma 1.1.0
- 环境：macOS 26.6.2 / Dart 3.12.2 / ureward a410823
- 命令 / 输入：`dart run w_tools_figma:figma spec 1:1 --file=/tmp/figma-repro/rich.json`（文本内容为 `A|B\nC`，带一段 style override）
- 期望：Markdown 表格单元格里的 `|` 和换行被转义（`\|`、`<br>` 或空格），富文本 runs 合并成连续区间
- 实际：
  1. 文本里的 `|` 直接进入表格，`\n` 直接把一行拆成两行：输出变成 `“A|B` + 换行 + `C” ...`，列数全乱，后续行也错位。
  2. 富文本 runs 逐字符输出：`runs: [0]='A'   [1]='|' 700 #3366CC [2]='B'   [3]='\n'   [4]='C'`；一段 100 字、只有 1 处变色的文案会生成 100 段 `[i]='x'`。
- 影响：`spec` 的 markdown 是贴 PR / 给 AI 读的主要输出；多行文案（很常见）会把整张表破坏，runs 又让表格膨胀到不可读。
- 建议：表格单元格统一转义 `|` → `\|`、换行 → `<br>`（或压成空格）；runs 按连续相同 styleOverride 合并为区间（`[1..2] 700 #3366CC`），并显示区间文本。
- 复现数据：`/tmp/figma-repro/rich.json`；`spec` 输出中 `| 0.0,0.0 | 100.0×20.0 | TEXT | rich | … | “A|B` 后换行 `C” … |`。`tokens` 的 samples 同样未转义，只是当前项目数据里没碰到。
- 状态变更：2026-11-20 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
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
