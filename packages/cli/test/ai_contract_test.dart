import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
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

    test('所有库包至少有一个 teach 入口', () {
      final excluded = <String>{
        'w_tools_cli',
        'w_tools_device',
        'w_tools_e2e',
        'w_tools_figma',
      };
      final packages = <String>{
        for (final pubspec in Directory('../../packages').listSync().whereType<Directory>())
          if (File('${pubspec.path}/pubspec.yaml').existsSync())
            (loadYaml(File('${pubspec.path}/pubspec.yaml').readAsStringSync()) as Map)['name']
                as String,
      };
      final taught = teachEntries.map((e) => e.package).toSet();
      for (final package in packages.difference(excluded)) {
        expect(taught, contains(package), reason: '$package 没有 teach 入口');
      }
    });

    test('related 必须能解析到组件名 / 别名', () {
      final names = <String>{
        for (final entry in catalog) ...entry.names,
        for (final entry in catalog) ...entry.aliases,
      };
      for (final entry in teachEntries) {
        for (final related in entry.related) {
          for (final name in related.split('/')) {
            final normalized = name.replaceAll('`', '').trim();
            if (normalized.isEmpty) continue;
            expect(
              names,
              contains(normalized),
              reason: '${entry.name} 的 related 无法解析：$related',
            );
          }
        }
      }
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

  group('UI 教学覆盖', () {
    final ui = catalog.where((e) => e.package == 'w_tools_ui').toList();

    test('ui 每个 catalog 条目都有 usage（explain 能给出用法）', () {
      for (final entry in ui) {
        expect(entry.usage, isNotNull, reason: '${entry.name} 缺少 usage');
        expect(entry.usage!.trim(), isNotEmpty, reason: '${entry.name} usage 为空');
      }
    });

    test('ui 的 teach usage 覆盖多种变体（不是单行）', () {
      for (final entry in ui.where((e) => e.teach)) {
        expect(
          entry.usage,
          contains('\n'),
          reason: '${entry.name} 的 usage 只有一行，AI 学不到变体',
        );
      }
    });

    test('ui 每条都有 docsAnchor（explain 能带章节锚点）', () {
      for (final entry in ui) {
        expect(entry.docsAnchor, isNotNull, reason: '${entry.name} 缺少 docsAnchor');
        expect(entry.docsAnchor!.trim(), isNotEmpty);
        expect(entry.docsAnchor!.startsWith('#'), isFalse);
      }
    });

    test('ui docsAnchor 都能在 ui_module.md 找到', () {
      final text = File('../../docs/modules/ui_module.md').readAsStringSync();
      String slug(String heading) {
        var h = heading.trim().toLowerCase().replaceAll('`', '');
        h = h.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\- ]'), '');
        return h.trim().replaceAll(' ', '-');
      }

      final slugs = RegExp(
        r'^#{1,6} (.+)$',
        multiLine: true,
      ).allMatches(text).map((m) => slug(m.group(1)!)).toSet();
      for (final entry in ui) {
        expect(
          slugs,
          contains(entry.docsAnchor),
          reason: '${entry.name} 的 docsAnchor 不在 ui_module.md：${entry.docsAnchor}',
        );
      }
    });

    test('ui 高频子 API 能通过 explain 查到', () {
      const names = <String>[
        'WButtonSize',
        'WButtonMotion',
        'WButtonEffectType',
        'WButtonSemantics',
        'WBadgeConfig',
        'WClipRRectConfig',
        'WImageDefaultsScope',
        'WScreenData',
        'WStepState',
        'WGradients',
        'WShadows',
        'WTextStyleExtension',
        'WGlobalKeyExtension',
        'WPressEffect',
        'WAssetImageSource',
        'WBase64ImageSource',
        'WFileImageSource',
        'WNetworkImageSource',
        'WProviderImageSource',
        'WButtonContentBuilder',
        'WButtonResolvedStyle',
        'WImageErrorView',
        'WImageFrame',
      ];
      for (final name in names) {
        expect(findComponent(name), isNotNull, reason: '$name 未登记到 catalog');
      }
    });

    test('ui 模板包含 WBadge/WClipRRect/WActionRow/WStep 的选择规则', () {
      for (final template in <String>[templates.agentsUi, templates.agentsUiEn]) {
        for (final name in <String>['WBadge', 'WClipRRect', 'WActionRow', 'WStep']) {
          expect(template, contains(name), reason: '模板缺少 $name');
        }
      }
    });
  });

  group('AGENTS 教学契约', () {
    test('async 模板包含 load 与查询命令', () {
      expect(templates.agentsAsync, contains('c.load()'));
      expect(templates.agentsAsync, contains('explain WAsync --format=prompt'));
      expect(templates.agentsAsyncEn, contains('c.load()'));
    });

    test('所有 AGENTS 模板非空且使用统一命令', () {
      final all = <String, String>{
        'base': templates.agentsBase,
        'feedback': templates.agentsFeedback,
        'closing': templates.agentsClosing,
        'ui': templates.agentsUi,
        'form': templates.agentsForm,
        'api': templates.agentsApi,
        'app': templates.agentsApp,
        'async': templates.agentsAsync,
        'toast': templates.agentsToast,
        'core': templates.agentsCore,
        'qr': templates.agentsQr,
        'map': templates.agentsMap,
        'figma': templates.agentsFigma,
        'device': templates.agentsDevice,
        'baseEn': templates.agentsBaseEn,
        'asyncEn': templates.agentsAsyncEn,
      };
      for (final entry in all.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
        expect(entry.value, isNot(contains('w_tools_cli:context')), reason: entry.key);
        expect(entry.value, isNot(contains('w_tools_cli:list')), reason: entry.key);
        expect(entry.value, isNot(contains('w_tools_cli:explain')), reason: entry.key);
      }
    });

    test('每个 InitFeature 都有 zh/en AGENTS 模板', () {
      final features = <String, (String, String)>{
        'app': (templates.agentsApp, templates.agentsAppEn),
        'form': (templates.agentsForm, templates.agentsFormEn),
        'ui': (templates.agentsUi, templates.agentsUiEn),
        'api': (templates.agentsApi, templates.agentsApiEn),
        'toast': (templates.agentsToast, templates.agentsToastEn),
        'qr': (templates.agentsQr, templates.agentsQrEn),
        'map': (templates.agentsMap, templates.agentsMapEn),
        'async': (templates.agentsAsync, templates.agentsAsyncEn),
      };
      for (final entry in features.entries) {
        expect(entry.value.$1.trim(), isNotEmpty, reason: '${entry.key} zh');
        expect(entry.value.$2.trim(), isNotEmpty, reason: '${entry.key} en');
      }
    });

    test('生成的 AGENTS 使用统一命令入口', () {
      expect(templates.agentsBase, contains('w_tools_cli:w_tools context'));
      expect(templates.agentsBase, contains('w_tools_cli:w_tools list'));
      expect(templates.agentsBase, contains('w_tools_cli:w_tools explain'));
      expect(templates.agentsBase, isNot(contains('w_tools_cli:context')));
    });
  });
}
