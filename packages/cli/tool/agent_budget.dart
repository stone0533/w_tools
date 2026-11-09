// ignore_for_file: avoid_print

// 消费方 AGENTS 片段的预算检查（数据在 catalog/agent_budget.yaml）。
//
// 用法（在 packages/cli 下）：
//   dart run tool/agent_budget.dart            # 打印余量表
//   dart run tool/agent_budget.dart --json     # 机器可读快照（周检 / 趋势用）
//   dart run tool/agent_budget.dart --record   # 把当前快照写进 docs/metrics/agents_budget.jsonl
//   dart run tool/agent_budget.dart --check    # 超预算 / 预算缺失 / 当前版本没记录时退出 1
//
// 为什么要有历史记录：预算只能回答「现在离上限多远」，回答不了「这个版本又长了多少」。
// 版本是 AGENTS 变化的最小发布单位，所以历史按 CLI 版本一行（`--record` 幂等 upsert），
// 周检（.github/workflows/release-status.yml）读它出趋势表，不需要机器人提交。
//
// 为什么单独一个 tool 而不是写在测试里：预算要跟**渲染结果**比，只有 Dart 能渲染。
// 测试（test/internal/templates_fresh_test.dart）和 preflight 都 import / 调用这里的
// 实现，避免「测试里一套数字、数据文件里一套数字」。
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/common/version.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/templates.dart';
import 'package:yaml/yaml.dart';

/// 一组预算上限（渲染后的行数 / 字符数）。
class BudgetLimit {
  const BudgetLimit({required this.lines, required this.chars});

  final int lines;
  final int chars;
}

/// 某 lang + profile 的实际用量与上限。
class BudgetRow {
  const BudgetRow({
    required this.lang,
    required this.profile,
    required this.limit,
    required this.lines,
    required this.chars,
  });

  final String lang;
  final String profile;
  final BudgetLimit limit;
  final int lines;
  final int chars;

  String get label => '$lang/$profile';

  int get lineMargin => limit.lines - lines;
  int get charMargin => limit.chars - chars;

  bool get overLines => lineMargin < 0;
  bool get overChars => charMargin < 0;

  bool get ok => !overLines && !overChars;
}

/// `catalog/agent_budget.yaml` 的内容 + 校验用的必检组合。
class AgentBudget {
  const AgentBudget({required this.limits, required this.feedbackMaxLines});

  /// lang -> profile -> 上限
  final Map<String, Map<String, BudgetLimit>> limits;

  /// 「完成前」里允许出现 feedback 字样的行数（默认关闭的通道不该常驻）。
  final int feedbackMaxLines;

  /// 删掉任何一条预算都要显式报错，不能静默失去保护。
  static const requiredCombos = <String>['zh/full', 'zh/minimal', 'en/full', 'en/minimal'];

  static const fileName = 'agent_budget.yaml';

  static File fileIn(Directory cliRoot) => File(p.join(cliRoot.path, 'catalog', fileName));

  /// 从当前目录向上找 `w_tools_cli` 包根（`dart test` / `dart run` 的 cwd 不同）。
  static Directory findCliRoot([Directory? start]) {
    var dir = start ?? Directory.current;
    while (dir.path != dir.parent.path) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync() && pubspec.readAsStringSync().contains('name: w_tools_cli')) {
        return dir;
      }
      dir = dir.parent;
    }
    throw StateError('找不到 w_tools_cli 包根（从 ${(start ?? Directory.current).path} 向上找）');
  }

  static AgentBudget load([Directory? cliRoot]) {
    final root = cliRoot ?? findCliRoot();
    final file = fileIn(root);
    if (!file.existsSync()) {
      throw StateError('缺少 ${file.path}：预算必须显式声明（见 docs/ai-contract.md §3.3）');
    }
    final raw = loadYaml(file.readAsStringSync());
    if (raw is! YamlMap) {
      throw StateError('${file.path} 必须是一个 map');
    }

    final limits = <String, Map<String, BudgetLimit>>{};
    final agents = raw['agents'];
    if (agents is! YamlMap) {
      throw StateError('${file.path}: 缺少 agents 段');
    }
    for (final langEntry in agents.entries) {
      final lang = '${langEntry.key}';
      final profiles = langEntry.value;
      if (profiles is! YamlMap) {
        throw StateError('${file.path}: agents.$lang 必须是 map（profile -> {lines, chars}）');
      }
      final perProfile = <String, BudgetLimit>{};
      for (final entry in profiles.entries) {
        final profile = '${entry.key}';
        if (!InitProfile.values.any((value) => value.name == profile)) {
          throw StateError(
            '${file.path}: agents.$lang.$profile 不是已知 profile'
            '（${InitProfile.values.map((value) => value.name).join(' / ')}）',
          );
        }
        final node = entry.value;
        if (node is! YamlMap) {
          throw StateError('${file.path}: agents.$lang.$profile 必须是 {lines, chars}');
        }
        final lines = node['lines'];
        final chars = node['chars'];
        if (lines is! int || chars is! int || lines <= 0 || chars <= 0) {
          throw StateError('${file.path}: agents.$lang.$profile 需要正整数 lines / chars');
        }
        perProfile[profile] = BudgetLimit(lines: lines, chars: chars);
      }
      limits[lang] = perProfile;
    }

    final feedback = raw['feedback'];
    final maxLines = feedback is YamlMap ? feedback['maxLines'] : null;
    if (maxLines is! int || maxLines <= 0) {
      throw StateError('${file.path}: 缺少 feedback.maxLines（正整数）');
    }

    final budget = AgentBudget(limits: limits, feedbackMaxLines: maxLines);
    budget.validateRequired(file.path);
    return budget;
  }

  void validateRequired(String path) {
    final missing = <String>[
      for (final combo in requiredCombos)
        if (!hasCombo(combo)) combo,
    ];
    if (missing.isNotEmpty) {
      throw StateError('$path: 缺少必检组合 ${missing.join(', ')}（删预算保护要显式改代码并写明理由）');
    }
  }

  bool hasCombo(String combo) {
    final parts = combo.split('/');
    if (parts.length != 2) return false;
    return limits[parts[0]]?.containsKey(parts[1]) ?? false;
  }
}

/// 按 init 的同一套开关渲染某个 lang + profile 的片段（预算量的是真实产物）。
String renderBlock(String lang, String profile) {
  final features = InitFeatures.forProfile(
    InitProfile.values.firstWhere((value) => value.name == profile),
  );
  return InitTemplates.agentsBlock(
    lang: lang,
    withUi: features.ui,
    withApp: features.app,
    withForm: features.form,
    withApi: features.api,
    withAsync: features.asyncFeature,
    withToast: features.toast,
    withQr: features.qr,
    withMap: features.map,
  );
}

/// 逐个组合量一遍（顺序固定：lang 排序，profile 排序）。
List<BudgetRow> measure(AgentBudget budget) {
  final rows = <BudgetRow>[];
  for (final lang in budget.limits.keys.toList()..sort()) {
    final profiles = budget.limits[lang]!;
    for (final profile in profiles.keys.toList()..sort()) {
      final text = renderBlock(lang, profile);
      rows.add(
        BudgetRow(
          lang: lang,
          profile: profile,
          limit: profiles[profile]!,
          lines: text.split('\n').length,
          chars: text.length,
        ),
      );
    }
  }
  return rows;
}

/// 「完成前」里提到 feedback 的行数（只数这一节，避免把别处的词算进来）。
int feedbackLines(String lang) {
  final block = renderBlock(lang, 'full');
  final heading = lang == 'en' ? '## Before done' : '## 完成前';
  final index = block.indexOf(heading);
  final tail = index < 0 ? block : block.substring(index);
  return tail.split('\n').where((line) => line.contains('feedback')).length;
}

List<String> violations(AgentBudget budget, {List<BudgetRow>? rows}) {
  final out = <String>[];
  for (final row in rows ?? measure(budget)) {
    if (row.overLines) {
      out.add('${row.label}: ${row.lines} 行 > ${row.limit.lines}（超 ${-row.lineMargin} 行）');
    }
    if (row.overChars) {
      out.add('${row.label}: ${row.chars} 字符 > ${row.limit.chars}（超 ${-row.charMargin} 字符）');
    }
  }
  for (final lang in <String>['zh', 'en']) {
    final count = feedbackLines(lang);
    if (count > budget.feedbackMaxLines) {
      out.add('$lang: 反馈段 $count 行 > ${budget.feedbackMaxLines} 行（默认关闭的通道不该常驻）');
    }
  }
  return out;
}

/// 机器可读快照：一行 = 一个版本（`--json` 与历史记录共用同一形状）。
Map<String, Object?> snapshotJson(AgentBudget budget, {List<BudgetRow>? rows}) {
  final measured = rows ?? measure(budget);
  return <String, Object?>{
    'schema': 'w_tools_cli.agent_budget/1',
    'schemaVersion': 1,
    'generator': cliVersion,
    'measuredAt': DateTime.now().toUtc().toIso8601String(),
    'rows': <Map<String, Object?>>[
      for (final row in measured)
        <String, Object?>{
          'lang': row.lang,
          'profile': row.profile,
          'lines': row.lines,
          'chars': row.chars,
          'limitLines': row.limit.lines,
          'limitChars': row.limit.chars,
        },
    ],
    'feedback': <String, Object?>{
      'zh': feedbackLines('zh'),
      'en': feedbackLines('en'),
      'maxLines': budget.feedbackMaxLines,
    },
  };
}

/// 历史快照：`docs/metrics/agents_budget.jsonl`，一个 CLI 版本一行。
///
/// 位置在 `docs/` 下（不进 CLI 包），因为它是仓库的演变记录，不是消费方产物。
File historyFileFor(Directory cliRoot) {
  final repoRoot = p.normalize(p.join(cliRoot.path, '..', '..'));
  return File(p.join(repoRoot, 'docs', 'metrics', 'agents_budget.jsonl'));
}

/// 幂等写入：同一 `generator` 覆盖原行，否则追加；保持文件按记录顺序。
void upsertRecord(File history, Map<String, Object?> record) {
  final lines = history.existsSync()
      ? history.readAsLinesSync().where((line) => line.trim().isNotEmpty).toList()
      : <String>[];
  final encoded = jsonEncode(record);
  final index = lines.indexWhere((line) {
    try {
      final decoded = jsonDecode(line);
      return decoded is Map && decoded['generator'] == record['generator'];
    } on FormatException {
      return false;
    }
  });
  if (index >= 0) {
    lines[index] = encoded;
  } else {
    lines.add(encoded);
  }
  history.parent.createSync(recursive: true);
  history.writeAsStringSync('${lines.join('\n')}\n');
}

/// 当前版本是否已经记录；历史坏了也要报出来（否则趋势会静默断档）。
///
/// 只校验**存在性**，不校验数值一致：同一个版本内模板可能继续改，强行要求
/// 「记录 == 当前渲染」会让多个并行 PR 因合并顺序把 main 弄红；数值的准确性
/// 由发布流程保证（`docs/releasing.md` 第 4 步在发布前 `--record` 重新测量）。
List<String> recordViolations(File history, String version) {
  if (!history.existsSync()) {
    return <String>[
      '缺少 ${history.path}：跑 `dart run tool/agent_budget.dart --record` 生成并提交（一个版本一行）',
    ];
  }
  var hasVersion = false;
  final lines = history.readAsLinesSync().where((line) => line.trim().isNotEmpty).toList();
  for (var index = 0; index < lines.length; index++) {
    try {
      final decoded = jsonDecode(lines[index]);
      if (decoded is! Map) {
        return <String>['${history.path} 第 ${index + 1} 行不是 JSON 对象'];
      }
      if (decoded['generator'] == version) hasVersion = true;
    } on FormatException {
      return <String>['${history.path} 第 ${index + 1} 行不是合法 JSON'];
    }
  }
  if (hasVersion) return const <String>[];
  return <String>[
    '当前版本 $version 还没有历史快照：跑 `dart run tool/agent_budget.dart --record` 并提交 ${history.path}',
  ];
}

void main(List<String> argv) {
  final asJson = argv.contains('--json');
  final record = argv.contains('--record');
  final checkOnly = argv.contains('--check');

  final AgentBudget budget;
  final Directory cliRoot;
  try {
    cliRoot = AgentBudget.findCliRoot();
    budget = AgentBudget.load(cliRoot);
  } on StateError catch (e) {
    stderr.writeln('✗ ${e.message}');
    exitCode = 1;
    return;
  }

  final rows = measure(budget);
  final snapshot = snapshotJson(budget, rows: rows);
  final history = historyFileFor(cliRoot);

  if (record) {
    upsertRecord(history, snapshot);
    print(
      '✓ 已记录 ${snapshot['generator']} → ${p.relative(history.path, from: Directory.current.path)}',
    );
    return;
  }

  final bad = <String>[
    ...violations(budget, rows: rows),
    ...recordViolations(history, cliVersion),
  ];

  if (asJson) {
    print(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        ...snapshot,
        'ok': bad.isEmpty,
        'violations': bad,
      }),
    );
    exitCode = checkOnly && bad.isNotEmpty ? 1 : 0;
    return;
  }

  if (!checkOnly) {
    print('AGENTS 片段预算（渲染后）：');
    for (final row in rows) {
      final linePct = (row.lines / row.limit.lines * 100).round();
      final charPct = (row.chars / row.limit.chars * 100).round();
      print(
        '  ${row.label.padRight(11)} '
        '${'${row.lines}'.padLeft(4)}/${'${row.limit.lines}'.padLeft(4)} 行 ($linePct%)'
        '   ${'${row.chars}'.padLeft(5)}/${'${row.limit.chars}'.padLeft(5)} 字符 ($charPct%)',
      );
    }
    print(
      '  反馈行数: zh ${feedbackLines('zh')} / en ${feedbackLines('en')}（上限 ${budget.feedbackMaxLines}）',
    );
    final recorded = recordViolations(history, cliVersion).isEmpty;
    print('  历史快照: ${recorded ? '✓ $cliVersion 已记录' : '✗ 当前版本未记录（--record）'}');
  }

  if (bad.isEmpty) {
    print('✓ AGENTS 片段在预算内（${rows.length} 个组合）');
    return;
  }
  for (final line in bad) {
    stderr.writeln('✗ $line');
  }
  stderr.writeln('修法：删内容 / 改 catalog/agent_budget.yaml（写理由）/ 跑 --record 记录本版本。');
  exitCode = 1;
}
