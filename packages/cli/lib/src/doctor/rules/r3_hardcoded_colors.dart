import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R3：硬编码语义色。
///
/// **调色板默认是空的** —— 哪些颜色算「语义色」是项目自己的事，写进
/// `.w_tools_doctor.yaml` 的 `colors.palette` 才检查；为空时本规则跳过。
class R3HardcodedColors {
  static const id = 'R3';
  static const title = '硬编码语义色';

  static final _colorPattern = RegExp(r'Color\(0x(?:FF)?([0-9A-Fa-f]{6})\)');
  static final _hexPattern = RegExp(r"""fromHex\(\s*['"]#([0-9A-Fa-f]{6})['"]""");

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    if (config.palette.isEmpty) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未配置 colors.palette（语义色因项目而异，需显式声明）',
      );
    }

    final palette = config.palette.map(_normalize).toSet();
    final hits = <String, List<({String file, int line})>>{};

    for (final file in ctx.files) {
      // 项目 UI 是样式注册表，暂存层还没上移，允许先固定颜色
      if (file.startsWith('$projectUiDirPath/') || file.startsWith('$designSystemDirPath/')) {
        continue;
      }
      final lines = ctx.read(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        for (final re in <RegExp>[_colorPattern, _hexPattern]) {
          for (final m in re.allMatches(lines[i])) {
            final hex = _normalize(m.group(1)!);
            if (!palette.contains(hex)) continue;
            final places = hits.putIfAbsent(hex, () => <({String file, int line})>[]);
            places.add((file: file, line: i + 1));
          }
        }
      }
    }

    final issues = <DoctorIssue>[];
    hits.forEach((hex, places) {
      if (places.length < config.colorMinCount) return;
      issues.add(
        DoctorIssue(
          rule: id,
          level: DoctorLevel.warn,
          file: places.first.file,
          line: places.first.line,
          message: '语义色 #$hex 硬编码 ${places.length} 处（阈值 ${config.colorMinCount}）',
          hint: '收敛成颜色常量（WColors 待包内提供），否则改主题时要全项目搜',
        ),
      );
    });

    return DoctorRuleResult(
      ruleId: id,
      title: title,
      status: issues.isEmpty ? DoctorRuleStatus.pass : DoctorRuleStatus.fail,
      issues: issues,
    );
  }

  static String _normalize(String hex) {
    var h = hex.replaceAll('#', '').toUpperCase();
    if (h.length == 8) h = h.substring(2); // 去掉 AA
    return h;
  }
}
