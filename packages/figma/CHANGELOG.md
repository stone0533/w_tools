## 0.13.2

### Fixed
- `spec` / `tokens` 同 id 命中多份 nodes 缓存时优先未 `--depth` 裁剪的完整树；
  只剩裁剪缓存时在 stderr 提示子节点可能缺失（此前会静默输出空表 / 缺 token）。

## 0.13.1

### Deprecated
- `url --root` / `get --root` 标弃用：这两个命令本来就不用 `--root`，现在使用会在 stderr 提示，
  `--help` 已标注（`remove-in: 0.14.0`）。行为不变，仍接受该参数。

## 0.13.0

### Breaking
- 删除 `UsageSummary`（0.12.0 的兼容别名）。改用 `UsageResult`：类型成员不变，
  按 API 快照这是删除 `UsageSummary.new` / `UsageSummary.month` / `UsageSummary.used` /
  `UsageSummary.limit` / `UsageSummary.recent` / `UsageSummary.remaining` /
  `UsageSummary.isNearLimit`。
- 删除 `FigmaSpecRenderer.renderMarkdown`：它只是 `renderMarkdownFromRoot` 的转发，改用后者。
  按 API 快照这是删除 `FigmaSpecRenderer.renderMarkdown`。
- 删除 `spec --no-markdown` 旗标：改用 `--node-only`（语义完全一致，只影响 `--json`）。

### Changed
- 版本 0.12.0 → 0.13.0（0.x 预发布语义，minor 可破坏）。JSON 契约与其它命令行为不变。

## 0.12.0

### Changed
- `tokens --json` 增加结构化数组 `colors` / `texts` / `radii` / `spacings`（含出现次数与示例），
  脚本 / AI 不必再解析 `markdown`；`counts` 与 `markdown` 保留，v1 schema 只增字段。
- `url --json` / `me --json` 补 `schema` 字段（`w_tools_figma.url/1` / `w_tools_figma.me/1`），
  与其它 `--json` 输出一致；`me` 保留 `/v1/me` 的原始字段，不做删减。
- `frames` 复用 `_nodes-index.json` 里的 FRAME 摘要，不再每次解析全部缓存；
  `spec --node-only` 不再先渲染一遍 markdown。缓存文件名格式不变。
- `frames` 排序在同名画板时按 id 兜底，脚本拿到的顺序稳定。
- 取值型选项支持空格写法（`--depth 3` / `--root /tmp/x`），与 `--depth=3` 等价；
  以前只有 `--set 20` 是特例。
- 参数解析改用 `package:args`（新增 `args: ^2.6.0` 依赖）：flag / 选项语义、中文报错与退出码不变，
  手写分派链换成声明式配置。唯一可见差异是边界报错文案：`--node-depth -1` 现在报
  "未知选项：-1"（以前报"需要非负整数"，退出码都是 2）。

### Breaking
- `UsageSummary` 重命名为 `UsageResult`。按 API 快照这是"删旧名 + 加新名"：
  `UsageSummary.month` / `UsageSummary.used` / `UsageSummary.limit` / `UsageSummary.recent` /
  `UsageSummary.remaining` / `UsageSummary.isNearLimit` 都迁到 `UsageResult.*`。
  旧名保留为 `@Deprecated` 的 `typedef`（`remove-in: 0.13.0`），**源码兼容**，
  但显式写 `UsageSummary` 类型的代码会收到弃用提示。
- 构造器与返回类型同步改名：`UsageSummary.new` → `UsageResult.new`，
  `UsageCommand.run` 的返回类型从 `UsageSummary` 变成 `UsageResult`（签名行为不变）。

### Deprecated
- `FigmaSpecRenderer.renderMarkdown` 标废弃，改用 `renderMarkdownFromRoot`（`remove-in: 0.13.0`）。
- `spec --no-markdown` 标弃用，改用 `--node-only`（`remove-in: 0.13.0`）；行为不变，
  使用时 stderr 提示一行，`--help` 已标注。

### Fixed
- `diff` / `diff --if-stale` 不再写死节点缓存的文件名：`fetch nodes --depth=<n>` 或批量 ids
  产生的缓存也能当基线（之前会误报"没有变化"，并照扣 1 次 Tier 1）。没有旧缓存时提示
  "首次 diff"，基线来自 `--depth` 时给警告；`--json` 输出不变。
- `spec` / `tokens` 读到损坏的 nodes 缓存（如 `--file=` 指向被截断的缓存）时返回退出码 1
  并提示清理 / 重拉，不再落到"参数错误"（退出码 2）。
- `budget --set` 改为读-改-写，不再抹掉 `_budget.json` 里的其它字段（存量 `month` / `used`）。
- 不带 `--file` 时，损坏的 nodes 缓存现在报"解析失败"并给出文件路径 + `cache clean` 建议，
  不再只报"找不到节点"；`frames` 走索引跳过坏文件时也会在 stderr 提示。
- 多余的位置参数（`spec 1:2 9:9`、`url a b`、`fetch nodes K 1:2 extra` 等）返回退出码 2，
  不再静默忽略多出来的参数。
- `spec` 规格表的描边列不再出现 Python 字面量：缺 `strokeWeight` 时省略宽度，不打印 `None px`。
- 顶层 `--help` 与 `help <command>` 合并到同一份来源，`help fetch` 不再漏掉 `fetch nodes --depth`。
- `help init` 点明这是 Figma 取数的 init，与 `w_tools_cli` 的 init（生成 AGENTS / doctor 配置）不是一回事。

## 0.11.5

### Fixed
- `--help` / 契约文案指向 `packages/figma/README.md`，不再引用已删除的
  `docs/figma-cli.md`；相关缓存 / fetch 注释同步。

## 0.11.4

### Fixed
- token 缺失 / 非法时退出码从 2 改为 4，与契约和 `--help` 一致。
- README / 契约：安装约束、`--root` 说明、`diff <fileKey> <nodeId>` 签名同步。

### Changed
- `version` 命令进入顶层 `--help`、README 命令表和 CLI 契约。
- README 补 `cache` / `help` / `version` 命令与库 API 说明。

## 0.11.3

### Fixed
- 修正 0.11.2 归档中 `figmaVersion` 仍为 `0.11.1` 的问题。

## 0.11.2

### Changed
- `AGENTS.md`：查询 / 诊断命令改为 `dart run w_tools_cli:w_tools list|explain|doctor`，
  不再推荐旧入口。

## 0.11.1

### Changed
- token 配置错误退出码 4→2，与 CLI 统一。

## 0.10.0

### 新增
- `fetch nodes --depth=<n>`：限制节点树层数。深页面（如整页 27 个容器）原本一次拉 129 MB，
  现在可以只拉需要的层；不同 depth 用不同缓存文件，互不覆盖。不传 `--depth` 行为不变。

## 0.9.1

### 安全
- `cache clean --all` 现在需要 `--yes` 确认（清理后重新 fetch 会消耗 Figma 额度）。

## 0.9.0

### 新增
- `figma cache stats`：当前项目缓存目录 / 文件数 / 大小（`--json` 给脚本）。
- `figma cache clean [--all]`：清理当前项目缓存；`--all` 清所有项目缓存（**保留**账号级用量/预算）。
- Windows 路径：缓存用 `%LOCALAPPDATA%\w_tools\figma`、令牌用 `%APPDATA%\w_tools\figma-token`，
  环境变量缺失时回落到 `~/.cache` / `~/.config`。

## 0.8.0

### Changed（破坏性：路径）
- 缓存 / 令牌 / 额度记录**移出项目仓库**：
  - 缓存：`~/.cache/w_tools/figma/<项目标识>/`（原 `<project>/.figma-cache/`）
  - 令牌：`~/.config/w_tools/figma-token`（原 `<project>/.figma-token`，权限 600）
  - 额度/预算：`~/.cache/w_tools/figma/_usage.log` / `_budget.json`（按账号，跨项目共用）
- 旧路径首次运行时**自动迁移**（缓存移动、令牌移动），之后旧文件删除。
- `init` 不再往 `.gitignore` 加 `.figma-cache/` / `.figma-token`（新路径在仓库外）；
  只有老项目还留着旧文件时才补，防止误提交。
- `spec` / `tokens` / `frames` 的缓存定位改用项目缓存目录（不再硬编码 `.figma-cache`）。

# Changelog

## 0.11.0

### Added
- `fetch` / `diff` 增加额度护栏：本月 Tier 1 达到预算上限时默认拒绝（退出码 3），`--ignore-budget` 放行；缓存命中与 `spec` / `tokens` 不触发检查。

### Fixed
- Windows 下能识别 `nodes-*.json` 缓存（原先按 `/` 切分会得到整条路径，导致 `spec` / `tokens` / `frames` 找不到缓存）。

## 0.9.2

### Fixed
- 新增 `cache.v1.json` schema。
- `tokens --json` 与 `--out` 改为互斥。
- `cache stats` 不再接受 `--all/--yes`；`cache clean --yes` 必须搭配 `--all`。
- 文档移除过时的 usage `seat` 字段。

## 0.7.0

### Fixed
- `version` 从包版本读取，不再写死 0.1.0。
- `fetch --refresh` 请求失败时保留旧缓存。
- `diff` 遵守 `--no-log`。
- `tokens` 跳过隐藏节点及其子树。
- 命令级选项校验：spec 不再静默接受 tokens/fetch 专属参数。

## 0.6.0

### Changed
- `spec` / `tokens` 默认扫描所有缓存，选择包含目标 nodeId 的文件；不再只取最大文件。
- 找不到节点时给出候选缓存文件。
- 新增 `.figma-cache/_nodes-index.json` 缓存索引。
- `spec a,b` / `tokens a,b` 支持跨缓存。
- `tokens --json` 增加 `sources` 数组。

## 0.5.0

### Added
- `spec` 输出 strokeAlign、节点 opacity、阴影 spread。
- `tokens --map` 语义名合并进颜色主表；`frames` 人类输出显示 page 列。

## 0.4.0

### Added
- `frames --all/--name/--page/--verbose`；默认只列顶层 FRAME，cacheFile 改为相对路径。
- `spec a,b,c` 多画板 Markdown；JSON 使用 `w_tools_figma.specs/1`。
- `tokens --map` 缺少 `colors:` 时明确报错。

## 0.3.0

### Added
- `frames`：列出缓存里的 FRAME，方便找 nodeId。
- `diff --if-stale`：先用 `/meta` 比较版本，没变不消耗 Tier 1。
- diff 比较 position / itemSpacing / padding / rectangleCornerRadii。

### Changed
- diff 成功后删除 `.prev` 备份。

## 0.2.0

### Added
- `url --json`。
- `spec --json --node-depth=<n>`，限制原始节点层级。
- `get` 下载改为临时文件 + rename，并给 body 读取加超时。

## 0.1.1

### Changed
- README 标明 pub 安装方式，并补充消费方 AI 入口说明。
- 明确 0.1.1 不包含 `page` 命令。

## 0.1.0

- 初始内部版本：`init` / `fetch` / `spec` / `tokens` / `url` / `diff` / `usage` / `budget`。
- 本地缓存、用量日志、预算、Tier 3 stale 检查与 token 保护。
- `get` 下载图片地址；`me` 校验 token。
- CLI 拆分、单命令帮助、AI 使用说明与 JSON schema。
