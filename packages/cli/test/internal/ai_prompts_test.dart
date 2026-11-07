import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/templates.dart';

File _template(String name) => File('templates/ai/$name');

void main() {
  final zh = _template('consumer-prompts.md').readAsStringSync();
  final en = _template('consumer-prompts.en.md').readAsStringSync();

  test('场景表与章节一一对应，元提示覆盖 C-A~C-K', () {
    final table = RegExp(r'\|[^|\n]+\|\s*(C-[A-K])\s*\|');
    final heading = RegExp(r'^## (C-[A-K]) ', multiLine: true);

    for (final content in <String>[zh, en]) {
      final tableIds = table.allMatches(content).map((m) => m.group(1)!).toSet();
      final headingIds = heading.allMatches(content).map((m) => m.group(1)!).toSet();
      expect(tableIds, headingIds);
      expect(tableIds, containsAll(<String>['C-A', 'C-K']));
    }

    expect(zh, contains('C-A 到 C-K'));
    expect(en, contains('C-A through C-K'));
  });

  test('zh / en 章节顺序与命令集合一致，且不再使用旧入口', () {
    final heading = RegExp(r'^## (C-[A-K]) ', multiLine: true);
    final zhIds = heading.allMatches(zh).map((m) => m.group(1)!).toList();
    final enIds = heading.allMatches(en).map((m) => m.group(1)!).toList();
    expect(zhIds, enIds);

    final command = RegExp(r'dart run w_tools_cli:[^\s`]+');
    final zhCommands = command.allMatches(zh).map((m) => m.group(0)!).toSet();
    final enCommands = command.allMatches(en).map((m) => m.group(0)!).toSet();
    expect(zhCommands, enCommands);

    for (final content in <String>[zh, en]) {
      expect(
        RegExp(r'w_tools_cli:(?!w_tools)\w+').hasMatch(content),
        isFalse,
        reason: 'AI_PROMPTS 仍教旧入口，应统一用 dart run w_tools_cli:w_tools <cmd>',
      );
    }
  });

  test('@if 标记平衡、无嵌套，feature 名合法', () {
    const features = <String>{
      'app',
      'form',
      'ui',
      'api',
      'toast',
      'qr',
      'map',
      'async',
    };
    for (final content in <String>[zh, en]) {
      var depth = 0;
      for (final line in content.split('\n')) {
        final start = RegExp(r'^<!-- @if:([a-z]+) -->$').firstMatch(line);
        if (start != null) {
          expect(features, contains(start.group(1)));
          expect(depth, 0, reason: '@if 不支持嵌套：$line');
          depth++;
        } else if (line == '<!-- @endif -->') {
          expect(depth, 1, reason: '多余的 @endif');
          depth--;
        }
      }
      expect(depth, 0, reason: '@if 未闭合');
    }
  });

  test('按能力裁剪：form / api / async / ui 内容不泄漏', () {
    final full = InitTemplates.aiPrompts();
    expect(full, contains('C-C 表单'));
    expect(full, contains('C-D 接口'));
    expect(full, contains('WAsyncPagedController'));
    expect(full, contains('WImage.source'));

    final trimmed = InitTemplates.aiPrompts(
      features: InitFeatures.full.copyWith(
        form: false,
        api: false,
        asyncFeature: false,
        ui: false,
      ),
    );
    expect(trimmed, isNot(contains('C-C 表单')));
    expect(trimmed, isNot(contains('C-D 接口')));
    expect(trimmed, isNot(contains('WAsyncPagedController')));
    expect(trimmed, isNot(contains('WImage.source')));
    expect(trimmed, isNot(contains('@if:')));
    expect(trimmed, isNot(contains('@endif')));
    expect(trimmed, contains('C-K'));
  });

  test('升级 / 审计命令与 AGENTS 标记块写法可直接执行', () {
    for (final content in <String>[zh, en]) {
      expect(content, contains('doctor --format=json'));
      expect(content, contains('init --check-drift'));
      expect(content, contains('init --force'));
      expect(content, contains('w_tools:begin/end'));
      expect(content, isNot(contains('不要手改生成的 AGENTS.md')));
    }
  });

  test('固定前缀去掉与 AGENTS 重复的规则，C-I 指向 AGENTS device', () {
    expect(zh, contains('项目规则优先于本文件'));
    expect(zh, contains('import / 分层 / 禁止项按 AGENTS.md'));
    expect(zh, isNot(contains('先看项目现有相似页面')));
    expect(zh, contains('AGENTS.md 的 device 段'));

    expect(en, contains('project rules take precedence over this file'));
    expect(en, contains('imports / layering / bans follow AGENTS.md'));
    expect(en, contains('device section in AGENTS.md'));
  });

  test('不再教已删除 / 过期 API', () {
    const removed = <String>[
      'WTextConfig',
      'WImage.network',
      'WImage.asset',
      'WImage.file',
      'WImage.data',
      'WApp.start()',
      'WApp.appWrapper',
    ];
    for (final content in <String>[zh, en]) {
      for (final api in removed) {
        expect(content, isNot(contains(api)), reason: 'AI_PROMPTS 仍出现已删除 API：$api');
      }
    }
  });
}
