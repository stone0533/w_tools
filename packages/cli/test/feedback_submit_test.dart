import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_submit.dart';

const _body = '''- 包/版本：w_tools_ui 5.0.0
- 环境：Flutter 3.44 / macOS
- 命令 / 输入：WImage(...)
- 期望：显示图片
- 实际：空白
- 影响：页面不可用
- 建议：补错误提示
- 复现数据：见附件
''';

void main() {
  test('缺少必填字段时列出字段', () {
    final draft = FeedbackDraft(package: 'ui', title: '空白', body: '- 包/版本：w_tools_ui 5.0.0');
    expect(draft.missingFields, isNotEmpty);
    expect(draft.missingFields, contains('环境'));
  });

  test('合法正文补待处理标题并生成预填 URL', () {
    final draft = FeedbackDraft(package: 'ui', title: 'WImage 空白', body: _body);
    expect(draft.missingFields, isEmpty);
    expect(draft.body, startsWith('### [待处理] ui: WImage 空白'));
    expect(draft.body, contains('- 状态变更：'));
    expect(draft.issueTitle, '[feedback][ui] WImage 空白');
    expect(draft.issueUrl.host, 'github.com');
    expect(draft.issueUrl.queryParameters['title'], draft.issueTitle);
    expect(draft.issueUrl.queryParameters['body'], contains('w_tools_ui 5.0.0'));
  });

  test('searchLocal 搜台账与收件箱', () {
    final root = Directory.systemTemp.createTempSync('wt_fb_search_');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    File(p.join(root.path, 'docs', 'feedback', 'ui.md')).writeAsStringSync('### WImage 空白\n');
    Directory(p.join(root.path, 'docs', 'agents')).createSync(recursive: true);
    File(p.join(root.path, 'docs', 'agents', 'feedback.md')).writeAsStringSync('### WImage 第二次\n');
    final hits = searchLocal(root, query: 'WImage');
    expect(hits.length, 2);
    final filtered = searchLocal(root, package: 'ui', query: 'WImage');
    expect(filtered.any((m) => m.file.endsWith('ui.md')), isTrue);
    expect(filtered.any((m) => m.file.endsWith('feedback.md')), isTrue);
  });
}
