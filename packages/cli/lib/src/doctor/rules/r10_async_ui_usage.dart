import '../config.dart';
import '../context.dart';
import '../rule.dart';
import '../suppression.dart';
import '../text_scan.dart';

/// R10：装了 `w_tools_async_ui` 的业务页面仍直接使用 async 原语。
///
/// 这条规则只在项目直接依赖 `w_tools_async_ui` 时启用；没装可选包的项目
/// 不会被误报。先保持 warn，等消费方迁移稳定后再考虑 error。
class R10AsyncUiUsage {
  static const id = 'R10';
  static const title = 'async_ui 规范入口';

  static final _rawView = RegExp(r'\bWAsyncView\b');
  static final _rawSliver = RegExp(r'\bWAsyncStateSliver\b');
  static final _manualFlag = RegExp(r'\bhasLoadedMorePage\b');

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    if (!config.enabledRules.contains(id)) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未启用（rules.R10: false）',
      );
    }
    if (!ctx.facts.dependencies.contains('w_tools_async_ui')) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未依赖 w_tools_async_ui（可选包）',
      );
    }

    final issues = <DoctorIssue>[];
    for (final file in ctx.filesUnder('lib/app/modules')) {
      final source = SourceFile(file, ctx.read(file).split('\n'));
      for (final line in source.codeLines) {
        if (Suppression.isIgnored(source.lines, line.index, id)) continue;

        if (_rawView.hasMatch(line.code) || _rawSliver.hasMatch(line.code)) {
          issues.add(
            DoctorIssue(
              rule: id,
              level: DoctorLevel.error,
              file: file,
              line: line.lineNumber,
              message: '业务页面直接使用了 async 原语',
              hint:
                  '单区块用 WAsyncSection；标准分页用 WAsyncPagedList；'
                  '自定义滚动用 WAsyncPagedSliver。原语只留给库 / 设计系统。',
            ),
          );
        }
        if (_manualFlag.hasMatch(line.code)) {
          issues.add(
            DoctorIssue(
              rule: id,
              level: DoctorLevel.error,
              file: file,
              line: line.lineNumber,
              message: '业务页面维护了 hasLoadedMorePage',
              hint: '删掉手写 bool；分页 footer 只读 snapshot.footerStatus。',
            ),
          );
        }
      }
    }

    return DoctorRuleResult(
      ruleId: id,
      title: title,
      status: issues.isEmpty ? DoctorRuleStatus.pass : DoctorRuleStatus.fail,
      issues: issues,
    );
  }
}
