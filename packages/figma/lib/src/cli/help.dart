import 'dart:io';

import 'cli_io.dart';

const String usageText = '''
w_tools_figma — 只读的 Figma 取数与规格导出 CLI（文档见 packages/figma/README.md）

用法：
  dart run w_tools_figma:figma init   [--force]
  dart run w_tools_figma:figma fetch  file   <fileKey> [--depth=3]
  dart run w_tools_figma:figma fetch  nodes  <fileKey> <id[,id...]> [--depth=<n>]
  dart run w_tools_figma:figma frames [--file=<path>] [--json] [--all] [--name=<s>] [--page=<s>] [--verbose]
  dart run w_tools_figma:figma fetch  images <fileKey> <id[,id...]> [--scale=2]
  dart run w_tools_figma:figma spec   <nodeId> [选项]
  dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [选项]
  dart run w_tools_figma:figma usage  [--json]
  dart run w_tools_figma:figma cache  stats [--json]
  dart run w_tools_figma:figma cache  clean [--all --yes] [--json]
  dart run w_tools_figma:figma diff   <fileKey> <nodeId> [--json]
  dart run w_tools_figma:figma budget [--set=<n>] [--json]
  dart run w_tools_figma:figma get    <url> <outfile>
  dart run w_tools_figma:figma me     [--json]
  dart run w_tools_figma:figma url    <figma-url | nodeId>
  dart run w_tools_figma:figma help   [command]
  dart run w_tools_figma:figma version

选项（spec / tokens 通用）：
  --file=<path>   指定缓存节点树 JSON（默认扫描 nodes-*.json 并选含目标节点的文件）
  --root=<dir>    项目根（默认当前目录），用于定位项目缓存（~/.cache/w_tools/figma/）
  --json          输出 JSON（默认输出 Markdown）
  --node-depth=<n>  spec --json 限制原始 node 的子节点深度（0 = 不带 children）
  --node-only       spec --json 只输出 node，不带 markdown
  -h, --help      显示帮助

tokens 专属：
  --min=<n>       只列出出现次数 >= n 的项（默认 1）
  --out=<path>    写入文件（默认打印到 stdout）
  --map=<path>    颜色语义映射 YAML（colors: {"#RRGGBB": name}）

fetch 专属：
  --depth=<n>     file 的深度（默认 3）
  --scale=<n>     images 的倍率（默认 2）
  --refresh       绕过缓存重新请求（失败时保留旧缓存）
  --check-stale   用 Tier 3 的 file/meta 判断缓存是否过期（不占 20 次/月，只提示不重拉）
  --no-log        本次不写用量日志（调试用）
  --ignore-budget 本月额度已尽时仍然请求（默认拒绝，退出码 3）

diff 专属：
  --if-stale      先用 /meta 比较版本；没变就不拉节点（不再消耗 Tier 1）

退出码：0 成功 / 1 一般错误 / 2 参数错误 / 3 额度受限 / 4 token 问题 / 5 网络错误

说明：
  · spec / tokens 只读本地缓存，不访问 Figma，不消耗额度；
  · token 优先读 FIGMA_TOKEN，其次读 ~/.config/w_tools/figma-token（旧 .figma-token 会自动迁移）；
  · 缓存由 fetch file / nodes / images 生成。
''';
const Map<String, String> commandUsage = <String, String>{
  'init': '''
init — 初始化 token / 缓存 / 预算文件

dart run w_tools_figma:figma init [--force]

建 token（~/.config/w_tools/figma-token）与缓存目录（~/.cache/w_tools/figma/），都不在项目仓库里。
--force 会覆盖已有 token。
这是 Figma 取数的 init；`w_tools_cli` 的 init 生成 AGENTS / doctor 配置，不是一回事。
''',
  'frames': '''
frames — 列出缓存里的 FRAME

dart run w_tools_figma:figma frames [--file=<path>] [--json] [--all] [--name=<s>] [--page=<s>] [--verbose]

输出 id / name / width×height / children / cacheFile，方便找 nodeId。
''',
  'fetch': '''
fetch — 从 Figma 拉取并写缓存

dart run w_tools_figma:figma fetch file   <fileKey> [--depth=3]
dart run w_tools_figma:figma fetch nodes  <fileKey> <id1,id2,...> [--depth=<n>]
dart run w_tools_figma:figma fetch images <fileKey> <id1,id2,...> [--scale=2]

--refresh      绕过缓存重新请求（失败时保留旧缓存）
--check-stale  调 file/meta 判断缓存版本，只提示不重拉
--no-log       本次不写用量日志
--ignore-budget 本月额度已尽时仍然请求（默认拒绝，退出码 3）

缓存命中不读 token、不消耗 Tier 1；未命中 / refresh / check-stale 需要 token。
''',
  'spec': '''
spec — 从缓存导出节点规格

dart run w_tools_figma:figma spec <nodeId> [--file=<path>] [--root=<dir>] [--json] [--node-only] [--node-depth=<n>]

只读缓存，不访问 Figma；默认扫描所有 nodes-*.json，选包含目标 nodeId 的文件。
--json 输出结构化 node；默认同时带 markdown，--node-only 可只保留 node。
''',
  'tokens': '''
tokens — 汇总设计 token

dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [--min=<n>] [--out=<path>] [--map=<path>] [--json]

统计 SOLID 颜色、文字样式、圆角、auto-layout 间距；只读缓存。
--json 与 --out 不能同时使用。
''',
  'cache': '''
cache — 查看 / 清理本机缓存

dart run w_tools_figma:figma cache stats [--json]
dart run w_tools_figma:figma cache clean [--all --yes] [--json]

stats 只统计当前项目缓存；clean 默认清当前项目，--all 清所有项目缓存。
--all 必须同时给 --yes；不会清理 _usage.log / _budget.json。
''',
  'diff': '''
diff — 对比旧缓存与最新节点

dart run w_tools_figma:figma diff <fileKey> <nodeId> [--json] [--if-stale]

会请求 Figma，消耗 1 次 Tier 1；--if-stale 先用 /meta 比较版本，没变则 0 次。
额度用尽时默认拒绝（退出码 3），--ignore-budget 放行。
''',
  'usage': '''
usage — 查看本月调用次数

dart run w_tools_figma:figma usage [--json]

读取本地 _usage.log，不访问 Figma。
''',
  'budget': '''
budget — 查看 / 设置月度预算

dart run w_tools_figma:figma budget [--set=<n>] [--json]
dart run w_tools_figma:figma budget --set 20

默认上限 20 次/月；budget 为本地配置。
''',
  'get': '''
get — 下载图片 URL

dart run w_tools_figma:figma get <url> <outfile>

下载 fetch images 返回的签名 URL；不访问 Figma API，不消耗额度。
--root 对这个命令没有作用（已弃用，改为无操作；remove-in 0.14.0）。
''',
  'me': '''
me — 校验 token

dart run w_tools_figma:figma me [--json]

调用 /v1/me 校验 token 并显示当前用户；不消耗 Tier 1。
''',
  'url': '''
url — 解析 Figma 链接

dart run w_tools_figma:figma url '<figma-url>' [--json]
dart run w_tools_figma:figma url 1862:9222

输出 fileKey 与 nodeId，不访问 Figma。
--root 对这个命令没有作用（已弃用，改为无操作；remove-in 0.14.0）。
''',
  'version': '''
version — 显示版本

dart run w_tools_figma:figma version
''',
};

void printCommandHelp(String command) {
  final help = commandUsage[command];
  if (help == null) {
    stderr.writeln('未知命令：$command');
    exitCode = 2;
    return;
  }
  printOut(help);
  exitCode = 0;
}
