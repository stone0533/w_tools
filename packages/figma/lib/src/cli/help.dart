import 'dart:io';

import 'args.dart';
import 'cli_io.dart';

class _CommandDoc {
  const _CommandDoc(this.command, this.summary, this.usage, this.notes);

  final String command;
  final String summary;
  final String usage;
  final String notes;
}

const _docs = <_CommandDoc>[
  _CommandDoc(
    'init',
    '初始化 token / 缓存 / 预算文件',
    'dart run w_tools_figma:figma init [--force]',
    '建 token（~/.config/w_tools/figma-token）与缓存目录（~/.cache/w_tools/figma/），都不在项目仓库里。\n'
        '--force 只重建模板；已有真实 token 时不会覆盖（需先手动删除该文件）。\n'
        '旧 .figma-cache / .figma-token 不再自动迁移；需要时手动删除。\n'
        '这是 Figma 取数的 init；`w_tools_cli` 的 init 生成 AGENTS / doctor 配置，不是一回事。',
  ),
  _CommandDoc(
    'frames',
    '列出缓存里的 FRAME',
    'dart run w_tools_figma:figma frames [--file=<path>] [--json] [--all] [--name=<s>] [--page=<s>] [--depth=<n>] [--limit=<n>] [--verbose]',
    '输出 id / name / width×height / children / cacheFile，方便找 nodeId。\n'
        '--name / --page 搜索全部 FRAME（含嵌套）；真实大文件优先过滤；--all 可能数千行，建议配合 --depth / --limit。',
  ),
  _CommandDoc(
    'fetch',
    '从 Figma 拉取并写缓存',
    'dart run w_tools_figma:figma fetch nodes  <fileKey> <id1,id2,...> [--depth=<n>]\n'
        'dart run w_tools_figma:figma fetch images <fileKey> <id1,id2,...> [--scale=2]',
    'images 不缓存，直接输出 `id<TAB>url`（签名会过期）；--depth / --refresh / --check-stale 不适用。\n'
        '缓存命中不读 token、不消耗 Tier 1；未命中 / refresh / check-stale 需要 token。',
  ),
  _CommandDoc(
    'spec',
    '从缓存导出节点规格',
    'dart run w_tools_figma:figma spec <nodeId> [--file=<path>] [--root=<dir>] [--json] [--node-only] [--node-depth=<n>] [--skip-name-prefix=<s>] [--with-id] [--with-layout] [--skip-hidden]',
    '只读缓存，不访问 Figma；默认扫描所有 nodes-*.json，选包含目标 nodeId 的文件。\n'
        '--json 输出 {schema:"w_tools_figma.specs/1", items:[...]}；--node-only 只与 --json 一起用；--with-id 加 nodeId 列；--with-layout 加布局列；--skip-hidden 跳过 visible=false / opacity=0 的节点。',
  ),
  _CommandDoc(
    'tokens',
    '汇总设计 token',
    'dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [--min=<n>] [--out=<path>] [--map=<path>] [--json] [--skip-markdown]',
    '统计 SOLID 颜色、文字样式、圆角、auto-layout 间距；只读缓存。\n'
        '--json 与 --out 不能同时使用；--skip-markdown 只与 --json 一起用。',
  ),
  _CommandDoc(
    'cache',
    '查看 / 清理本机缓存',
    'dart run w_tools_figma:figma cache stats [--files] [--json]\n'
        'dart run w_tools_figma:figma cache clean [--all] [--legacy] [--file=<path>] --yes [--json]',
    'stats 只统计当前项目缓存；--files 列出每个文件（legacy / nodes / index + indexed）。\n'
        'clean 必须给 --yes；--legacy 只删旧 file-*；--file 只删点名文件；--all 清所有项目；不会清理 _usage.log / _budget.json。',
  ),
  _CommandDoc(
    'diff',
    '对比旧缓存与最新节点',
    'dart run w_tools_figma:figma diff <fileKey> <nodeId> [--json] [--if-stale]',
    '会请求 Figma，消耗 1 次 Tier 1；--if-stale 先用 /meta 比较版本，没变则 0 次。\n'
        '额度由 Figma 服务端限制；遇到 429 返回退出码 3。',
  ),
  _CommandDoc(
    'usage',
    '查看本月调用次数 / 设置月度预算',
    'dart run w_tools_figma:figma usage [--json]\n'
        'dart run w_tools_figma:figma usage --set=20',
    '读取本地 _usage.log，不访问 Figma。\n'
        '--set 写 _budget.json（只改 limit，保留其它字段）；默认上限 20 次/月。',
  ),
  _CommandDoc(
    'get',
    '下载图片 URL',
    'dart run w_tools_figma:figma get <url> <outfile>',
    '下载 fetch images 返回的签名 URL；不访问 Figma API，不消耗额度。',
  ),
  _CommandDoc(
    'me',
    '校验 token',
    'dart run w_tools_figma:figma me [--json]',
    '调用 /v1/me 校验 token 并显示当前用户；不消耗 Tier 1。',
  ),
  _CommandDoc(
    'url',
    '解析 Figma 链接',
    "dart run w_tools_figma:figma url '<figma-url>' [--json]",
    '输出 fileKey 与 nodeId，不访问 Figma。',
  ),
  _CommandDoc(
    'help',
    '显示命令帮助',
    'dart run w_tools_figma:figma help [command]',
    '与 `dart run w_tools_figma:figma <command> --help` 等价。',
  ),
  _CommandDoc(
    'version',
    '显示版本',
    'dart run w_tools_figma:figma version',
    '',
  ),
];

/// 每个命令的帮助：命令签名 / 选项由 [parserFor] 生成，避免多份手写。
final Map<String, String> commandUsage = <String, String>{
  for (final doc in _docs) doc.command: _render(doc),
};

final String usageText = _renderUsage();

String _render(_CommandDoc doc) {
  final options = doc.command == 'help' || doc.command == 'version' ? '' : _options(doc.command);
  final notes = doc.notes.isEmpty ? '' : '\n${doc.notes}\n';
  return '${doc.command} — ${doc.summary}\n\n${doc.usage}\n\n$options$notes';
}

String _options(String command) {
  final usage = parserFor(command).usage.trim();
  final helpLine = '  -h, --help      显示帮助';
  if (usage.isEmpty) return '$helpLine\n\n';
  return '$usage\n$helpLine\n\n';
}

String _renderUsage() {
  final buf = StringBuffer()
    ..writeln('w_tools_figma — 只读的 Figma 取数与规格导出 CLI（文档见 packages/figma/README.md）')
    ..writeln()
    ..writeln('用法：');
  for (final doc in _docs) {
    buf.writeln('  ${doc.usage.split('\n').join('\n  ')}');
  }
  buf
    ..writeln()
    ..writeln('选项：每个命令只列出自己支持的选项，见 `dart run w_tools_figma:figma help <command>`。')
    ..writeln('退出码：0 成功 / 1 一般错误 / 2 参数错误 / 3 额度受限 / 4 token 问题 / 5 网络错误')
    ..writeln()
    ..writeln('说明：')
    ..writeln('  · spec / tokens 只读本地缓存，不访问 Figma，不消耗额度；')
    ..writeln('  · token 优先读 FIGMA_TOKEN，其次读 ~/.config/w_tools/figma-token；')
    ..writeln('  · 缓存由 fetch nodes 生成；fetch images 不缓存（签名 URL 会过期）。');
  return buf.toString();
}

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
