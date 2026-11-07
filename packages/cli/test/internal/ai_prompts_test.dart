import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/templates.dart';

File _template(String name) => File('templates/ai/$name');

final _familyHeading = RegExp(r'^## ([A-Z])\. ', multiLine: true);
final _subHeading = RegExp(r'^### ([A-Z]-\d)\. ', multiLine: true);
final _idMention = RegExp(r'\b([A-Z]-\d)\b');
final _tableRow = RegExp(r'^\| `(<[^`]+>)` \|', multiLine: true);

/// `heading` 之后、下一个 `## ` 之前的内容。
String _section(String text, String heading) {
  final start = text.indexOf('\n$heading\n');
  expect(start, isNonNegative, reason: '缺少章节「$heading」');
  final rest = text.substring(start + heading.length + 2);
  final end = rest.indexOf('\n## ');
  return end == -1 ? rest : rest.substring(0, end);
}

Set<String> _ids(String text, RegExp re) => re.allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final zh = _template('consumer-prompts.md').readAsStringSync();
  final en = _template('consumer-prompts.en.md').readAsStringSync();

  test('每个场景编号都有标题，§1 场景选择也列全了', () {
    for (final content in <String>[zh, en]) {
      final families = _ids(content, _familyHeading);
      final subs = _ids(content, _subHeading);
      expect(families, containsAll(<String>['A', 'K']));
      expect(subs.length, greaterThanOrEqualTo(15));

      // 每个子标题的字母前缀都必须有对应的族标题。
      for (final sub in subs) {
        expect(families, contains(sub.substring(0, 1)), reason: '子标题 $sub 没有对应的族标题');
      }

      final selection = _section(
        content,
        content.contains('## 1. 场景选择') ? '## 1. 场景选择' : '## 1. Scenario selection',
      );
      final listed = _ids(selection, _idMention);
      expect(listed, subs, reason: '§1 列出的编号必须与正文标题完全一致');
    }
  });

  test('zh / en 章节编号与命令集合一致，且不再使用旧入口', () {
    expect(_ids(zh, _subHeading).toList(), _ids(en, _subHeading).toList());
    expect(_ids(zh, _familyHeading).toList(), _ids(en, _familyHeading).toList());

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
        } else if (line.trim() == '<!-- @endif -->') {
          expect(depth, 1, reason: '多余的 @endif');
          depth--;
        }
      }
      expect(depth, 0, reason: '@if 未闭合');
    }
  });

  test('按能力裁剪：form / api / async / ui 内容不泄漏', () {
    final full = InitTemplates.aiPrompts();
    expect(full, contains('C-1. 实现表单页'));
    expect(full, contains('D-1. 实现接口'));
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
    expect(trimmed, isNot(contains('## C.')));
    expect(trimmed, isNot(contains('## D.')));
    expect(trimmed, isNot(contains('WAsyncPagedController')));
    expect(trimmed, isNot(contains('WImage.source')));
    expect(trimmed, isNot(contains('@if:')));
    expect(trimmed, isNot(contains('@endif')));
    expect(trimmed, contains('K-1'));
  });

  test('任意能力组合都不残留 @if / 悬空编号', () {
    for (var mask = 0; mask < (1 << initFeatureSpecs.length); mask++) {
      var features = InitFeatures.full;
      for (var i = 0; i < initFeatureSpecs.length; i++) {
        features = features.withFeature(
          initFeatureSpecs[i].feature,
          mask & (1 << i) != 0,
        );
      }
      final content = InitTemplates.aiPrompts(features: features);
      expect(content, isNot(contains('@if:')), reason: 'mask=$mask');
      expect(content, isNot(contains('@endif')), reason: 'mask=$mask');
      final headings = _ids(content, _subHeading);
      final referenced = _ids(content, _idMention);
      expect(
        referenced.difference(headings),
        isEmpty,
        reason: 'mask=$mask 仍引用不存在的场景编号',
      );
    }
  });

  test('裁剪任一能力后，正文不再引用被裁掉的场景编号', () {
    // 悬空编号是这份模板最容易犯的错：表行 / 默认工作流 / 反查表都是静态文本，
    // 一旦指向被 @if 关掉的场景，读者就照着找不到那段。
    for (final spec in initFeatureSpecs) {
      final features = InitFeatures.full.withFeature(spec.feature, false);
      final content = InitTemplates.aiPrompts(features: features);
      final headings = _ids(content, _subHeading);
      final referenced = _ids(content, _idMention);
      expect(
        referenced.difference(headings),
        isEmpty,
        reason: '关掉 ${spec.flag} 后仍引用不存在的场景编号',
      );
    }
  });

  test('填空表存在，且每个语言都定义了占位符', () {
    for (final content in <String>[zh, en]) {
      final defined = _ids(content, _tableRow);
      expect(defined.length, greaterThanOrEqualTo(10), reason: '填空表缺失或过短');
      expect(content, isNot(contains('<...>')), reason: '不允许残留 <...>');
    }
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

  test('升级 migration 路径不只写 major', () {
    for (final content in <String>[zh, en]) {
      expect(content, contains('docs/migrations/'));
      expect(content, contains('form-5.1.md'));
      expect(content, isNot(contains('<major>')));
    }
  });

  test('固定前缀自足：内联硬规则，项目规则文件由生成器注入', () {
    expect(zh, contains('项目规则优先于本文件'));
    expect(zh, contains('{{dependencyNote}}'));
    expect(zh, contains('{{toolkitImport}}'));
    expect(zh, contains('直接 import package:w_tools_* 只出现在 toolkit 自身'));

    expect(en, contains('project rules take precedence over this file'));
    expect(en, contains('{{dependencyNote}}'));
    expect(en, contains('{{toolkitImport}}'));
    expect(en, contains(r'direct `package:w_tools_*` imports belong only in the toolkit itself'));
  });

  test('按项目上下文渲染规则文件 / 工具链 / 聚合包', () {
    final dartAggregate = InitTemplates.aiPrompts(
      rulesFiles: 'CLAUDE.md',
      toolkitImport: 'package:foo/app/w/toolkit.dart',
      isFlutter: false,
      usesAggregate: true,
    );
    expect(dartAggregate, contains('CLAUDE.md'));
    expect(dartAggregate, isNot(contains('AGENTS.md')));
    expect(dartAggregate, contains('dart analyze'));
    expect(dartAggregate, contains('dart test'));
    expect(dartAggregate, isNot(contains('flutter analyze')));
    expect(dartAggregate, contains('package:foo/app/w/toolkit.dart'));
    expect(dartAggregate, contains('已使用聚合包'));
    expect(dartAggregate, isNot(contains('{{')));

    final subpackage = InitTemplates.aiPrompts();
    expect(subpackage, contains('本项目依赖具体子包'));
    expect(subpackage, contains('flutter analyze'));
    expect(subpackage, contains('AGENTS.md'));
    expect(subpackage, contains('package:app/app/w/toolkit.dart'));
  });

  test('AI 读不到仓库时也不指向 AGENTS 的 device 段', () {
    for (final content in <String>[zh, en]) {
      expect(content, isNot(contains('AGENTS.md 的 device 段')));
      expect(content, isNot(contains('device section in AGENTS.md')));
    }
    expect(zh, contains('w_tools_device'));
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
