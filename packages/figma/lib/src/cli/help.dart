import 'dart:io';

import 'cli_io.dart';

const Map<String, String> commandUsage = <String, String>{
  'init': '''
init — 初始化 token / 缓存 / 预算文件

dart run w_tools_figma:figma init [--force]

生成 .figma-token、.figma-cache/，并把 token 与缓存目录追加到 .gitignore。
--force 会覆盖已有 token。
''',
  'frames': '''
frames — 列出缓存里的 FRAME

dart run w_tools_figma:figma frames [--file=<path>] [--json]

输出 id / name / width×height / children / cacheFile，方便找 nodeId。
''',
  'fetch': '''
fetch — 从 Figma 拉取并写缓存

dart run w_tools_figma:figma fetch file   <fileKey> [--depth=3]
dart run w_tools_figma:figma fetch nodes  <fileKey> <id1,id2,...>
dart run w_tools_figma:figma fetch images <fileKey> <id1,id2,...> [--scale=2]

--refresh      删除对应缓存并重新请求
--check-stale  调 file/meta 判断缓存版本，只提示不重拉
--no-log       本次不写用量日志

缓存命中不读 token、不消耗 Tier 1；未命中 / refresh / check-stale 需要 token。
''',
  'spec': '''
spec — 从缓存导出节点规格

dart run w_tools_figma:figma spec <nodeId> [--file=<path>] [--root=<dir>] [--json] [--node-depth=<n>]

只读 .figma-cache/nodes-*.json，不访问 Figma。
--json 输出 Markdown 载体，不是结构化字段树。
''',
  'tokens': '''
tokens — 汇总设计 token

dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [--min=<n>] [--out=<path>] [--json]

统计 SOLID 颜色、文字样式、圆角、auto-layout 间距；只读缓存。
''',
  'diff': '''
diff — 对比旧缓存与最新节点

dart run w_tools_figma:figma diff <fileKey> <nodeId> [--json] [--if-stale]

会请求 Figma，消耗 1 次 Tier 1；--if-stale 先用 /meta 比较版本，没变则 0 次。
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
