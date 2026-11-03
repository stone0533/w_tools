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
