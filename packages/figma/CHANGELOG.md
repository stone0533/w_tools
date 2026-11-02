# Changelog

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
