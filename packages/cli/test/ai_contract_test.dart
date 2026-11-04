import 'package:test/test.dart';
import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/explain/render_explain.dart';
import 'package:w_tools_cli/src/init/templates.g.dart' as templates;

void main() {
  group('AI 教学契约', () {
    final teachEntries = catalog.where((entry) => entry.teach).toList();

    test('至少覆盖主要入口组件', () {
      expect(teachEntries.length, greaterThanOrEqualTo(25));
      expect(
        teachEntries.map((e) => e.package).toSet(),
        containsAll(<String>[
          'w_tools_core',
          'w_tools_ui',
          'w_tools_form',
          'w_tools_async',
          'w_tools_api',
          'w_tools_toast',
          'w_tools_app_getx',
          'w_tools_map_google',
          'w_tools_qr',
        ]),
      );
    });

    for (final entry in teachEntries) {
      test('${entry.name} 具备 usage / pitfalls / related', () {
        expect(entry.usage, isNotNull);
        expect(entry.usage!.trim(), isNotEmpty);
        expect(entry.pitfalls, isNotEmpty);
        expect(entry.related, isNotEmpty);

        final prompt = renderExplainPrompt(
          entry,
          importPath: entry.importPath,
          docsUrl: 'https://example.com/${entry.docs}',
        );
        expect(prompt, contains('用法：'));
        expect(prompt, contains('注意：'));
        expect(prompt, contains('相关：'));
        expect(prompt.length, lessThan(5000));
      });
    }
  });

  group('AGENTS 教学契约', () {
    test('async 模板包含 load 与查询命令', () {
      expect(templates.agentsAsync, contains('c.load()'));
      expect(templates.agentsAsync, contains('explain WAsync --format=prompt'));
      expect(templates.agentsAsyncEn, contains('c.load()'));
    });

    test('生成的 AGENTS 使用统一命令入口', () {
      expect(templates.agentsBase, contains('w_tools_cli:w_tools context'));
      expect(templates.agentsBase, contains('w_tools_cli:w_tools list'));
      expect(templates.agentsBase, contains('w_tools_cli:w_tools explain'));
      expect(templates.agentsBase, isNot(contains('w_tools_cli:context')));
    });
  });
}
