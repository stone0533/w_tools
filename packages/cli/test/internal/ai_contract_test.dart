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
        'WImageTheme',
        'WImageSlots',
        'WImageLoadOptions',
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

  group('FORM 教学覆盖', () {
    final form = catalog.where((e) => e.package == 'w_tools_form').toList();

    test('form 每个 catalog 条目都有 usage', () {
      for (final entry in form) {
        expect(entry.usage, isNotNull, reason: '${entry.name} 缺少 usage');
        expect(entry.usage!.trim(), isNotEmpty);
      }
    });

    test('form 的 teach usage 覆盖多种场景（不是单行）', () {
      for (final entry in form.where((e) => e.teach)) {
        expect(entry.usage, contains('\n'), reason: '${entry.name} usage 只有一行');
      }
    });

    test('form 关键类型都能通过 explain 查到', () {
      const names = <String>[
        'WFormController',
        'WFormFieldStyle',
        'WFormValidatorSettings',
        'WFormBorder',
        'WFormBorderDecoration',
        'WFormIcons',
        'WFormFieldStyleScope',
        'WFormValidatorItem',
        'WFormPopup',
        'WFormTheme',
        'WFormScope',
        'WFormReadOnlyScope',
        'WFormTextFieldData',
        'WFormTextFieldScope',
        'WFormInputFormatters',
        'WCardNumberInputFormatter',
        'WDividerInputFormatter',
        'WFormCustomValidator',
        'WFormPopupRoute',
        'WFormFieldShell',
        'WFormBorderState',
        'WFormBorderLayout',
      ];
      for (final name in names) {
        expect(findComponent(name), isNotNull, reason: '$name 未登记到 catalog');
      }
    });

    test('form 模板包含字段与 readOnly 规则', () {
      for (final template in <String>[templates.agentsForm, templates.agentsFormEn]) {
        for (final name in <String>[
          'WFormTextField',
          'WFormDropdown',
          'WFormMultiDropdown',
          'WFormDatePicker',
          'WFormCheckbox',
          'WFormRadioGroup',
          'readOnly',
          'WFormValidator',
        ]) {
          expect(template, contains(name), reason: '模板缺少 $name');
        }
      }
    });

    test('form docsAnchor 都能在 form_module.md 找到', () {
      final text = File('../../docs/modules/form_module.md').readAsStringSync();
      String slug(String heading) {
        var h = heading.trim().toLowerCase().replaceAll('`', '');
        h = h.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\- ]'), '');
        return h.trim().replaceAll(' ', '-');
      }

      final slugs = RegExp(
        r'^#{1,6} (.+)$',
        multiLine: true,
      ).allMatches(text).map((m) => slug(m.group(1)!)).toSet();
      for (final entry in form) {
        expect(
          slugs,
          contains(entry.docsAnchor),
          reason: '${entry.name} 的 docsAnchor 不在 form_module.md：${entry.docsAnchor}',
        );
      }
    });
  });

  group('ASYNC 教学覆盖', () {
    final asyncs = catalog.where((e) => e.package == 'w_tools_async').toList();

    test('async 每个 catalog 条目都有 usage', () {
      for (final entry in asyncs) {
        expect(entry.usage, isNotNull, reason: '${entry.name} 缺少 usage');
        expect(entry.usage!.trim(), isNotEmpty);
      }
    });

    test('async 关键类型都能通过 explain 查到', () {
      const names = <String>[
        'WAsyncStrings',
        'WAsyncStatus',
        'WAsyncSuccess',
        'WAsyncFailure',
        'WAsyncCancelled',
        'WCancellationException',
        'WAsyncPageLoader',
        'WAsyncTokenLoader',
        'WAsyncTokenPageLoader',
        'WAsyncErrorWidgetBuilder',
        'WAsyncRetryErrorHandler',
      ];
      for (final name in names) {
        expect(findComponent(name), isNotNull, reason: '$name 未登记到 catalog');
      }
    });

    test('async teach usage 覆盖 View / Paged / Sliver / State 关键参数', () {
      CatalogEntry byName(String name) => asyncs.firstWhere((e) => e.names.contains(name));
      expect(byName('WAsyncView').usage, contains('errorBuilder'));
      expect(byName('WAsyncView').usage, contains('onRetryError'));
      expect(byName('WAsyncPagedController').usage, contains('loadMore'));
      expect(byName('WAsyncStateSliver').usage, contains('onRetry'));
      expect(byName('WAsyncState').usage, contains('status'));
    });

    test('WAsyncErrorView 有独立条目', () {
      final entry = findComponent('WAsyncErrorView');
      expect(entry, isNotNull);
      expect(entry!.name, contains('WAsyncErrorView'));
    });

    test('async 模板包含 strings / status / result 分支', () {
      for (final template in <String>[templates.agentsAsync, templates.agentsAsyncEn]) {
        for (final name in <String>[
          'WAsyncStrings',
          'WAsyncStatus',
          'WAsyncSuccess',
          'WAsyncFailure',
          'WAsyncCancelled',
          'WCancellationException',
        ]) {
          expect(template, contains(name), reason: '模板缺少 $name');
        }
      }
    });

    test('async docsAnchor 都能在 async_module.md 找到', () {
      final text = File('../../docs/modules/async_module.md').readAsStringSync();
      String slug(String heading) {
        var h = heading.trim().toLowerCase().replaceAll('`', '');
        h = h.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\- ]'), '');
        return h.trim().replaceAll(' ', '-');
      }

      final slugs = RegExp(
        r'^#{1,6} (.+)$',
        multiLine: true,
      ).allMatches(text).map((m) => slug(m.group(1)!)).toSet();
      for (final entry in asyncs) {
        expect(
          slugs,
          contains(entry.docsAnchor),
          reason: '${entry.name} 的 docsAnchor 不在 async_module.md：${entry.docsAnchor}',
        );
      }
    });
  });

  group('APP 教学覆盖', () {
    final apps = catalog
        .where((e) => e.package == 'w_tools_app' || e.package == 'w_tools_app_getx')
        .toList();

    test('app 家族每个 catalog 条目都有 usage', () {
      for (final entry in apps) {
        expect(entry.usage, isNotNull, reason: '${entry.name} 缺少 usage');
        expect(entry.usage!.trim(), isNotEmpty);
      }
    });

    test('app 家族 teach usage 覆盖启动/插件配置', () {
      for (final entry in apps.where((e) => e.teach)) {
        expect(entry.usage, contains('\n'), reason: '${entry.name} usage 只有一行');
      }
      CatalogEntry byName(String name) => apps.firstWhere((e) => e.names.contains(name));
      expect(byName('WAppOptions').usage, contains('appWrapper'));
      expect(byName('WAppOptions').usage, contains('localeConfig'));
      expect(byName('WAppPlugin').usage, contains('dependsOn'));
      expect(byName('WAppPlugin').usage, contains('onInit'));
    });

    test('app 家族关键类型都能通过 explain 查到', () {
      const names = <String>[
        'WApp',
        'WAppOptions',
        'WAppPlugin',
        'WBottomSheet',
        'WLanguage',
        'WAppConfig',
        'WRouteObserver',
        'WRouteStack',
        'WLocaleConfig',
      ];
      for (final name in names) {
        expect(findComponent(name), isNotNull, reason: '$name 未登记到 catalog');
      }
    });

    test('app 模板包含语言 / locale / 路由栈 / 弹窗 / dependsOn', () {
      for (final template in <String>[templates.agentsApp, templates.agentsAppEn]) {
        for (final name in <String>[
          'WLanguage',
          'WLocaleConfig',
          'WAppConfig',
          'WRouteStack',
          'WBottomSheet',
          'dependsOn',
        ]) {
          expect(template, contains(name), reason: '模板缺少 $name');
        }
      }
    });

    test('app docsAnchor 都能在 app_module.md 找到', () {
      final text = File('../../docs/modules/app_module.md').readAsStringSync();
      String slug(String heading) {
        var h = heading.trim().toLowerCase().replaceAll('`', '');
        h = h.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\- ]'), '');
        return h.trim().replaceAll(' ', '-');
      }

      final slugs = RegExp(
        r'^#{1,6} (.+)$',
        multiLine: true,
      ).allMatches(text).map((m) => slug(m.group(1)!)).toSet();
      for (final entry in apps) {
        expect(
          slugs,
          contains(entry.docsAnchor),
          reason: '${entry.name} 的 docsAnchor 不在 app_module.md：${entry.docsAnchor}',
        );
      }
    });
  });

  group('DEVICE 教学覆盖', () {
    test('device 模板包含命令表', () {
      const commands = <String>[
        'list',
        'boot',
        'shot',
        'calibrate',
        'tap',
        'drag',
        'type',
        'size',
        'foreground',
        'wait',
        'verify',
      ];
      for (final template in <String>[templates.agentsDevice, templates.agentsDeviceEn]) {
        for (final command in commands) {
          expect(template, contains('device $command'), reason: '模板漏 device $command');
        }
      }
    });
  });

  group('FIGMA 教学覆盖', () {
    test('figma 模板包含全部公开命令', () {
      const commands = <String>[
        'init',
        'fetch file',
        'fetch nodes',
        'fetch images',
        'frames',
        'spec',
        'tokens',
        'usage',
        'cache stats',
        'cache clean',
        'diff',
        'budget',
        'get',
        'me',
        'url',
        'help',
        'version',
      ];
      for (final template in <String>[templates.agentsFigma, templates.agentsFigmaEn]) {
        for (final command in commands) {
          expect(template, contains('figma $command'), reason: '模板漏 figma $command');
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
  group('UI 教学质量门禁', () {
    final ui = catalog.where((e) => e.package == 'w_tools_ui').toList();

    test('ui catalog usage 不使用级联 ..build()（会丢弃 Widget）', () {
      for (final entry in ui) {
        expect(
          entry.usage ?? '',
          isNot(contains('..build()')),
          reason: '${entry.name} 的 usage 用级联 build()，返回值被丢弃',
        );
      }
    });

    test('ui catalog 条目都有非空 dontUseFor', () {
      for (final entry in ui) {
        expect(
          entry.dontUseFor?.trim(),
          isNotNull,
          reason: '${entry.name} 缺少 dontUseFor',
        );
        expect(
          entry.dontUseFor!.trim(),
          isNotEmpty,
          reason: '${entry.name} 的 dontUseFor 为空',
        );
      }
    });

    test('WImage usage 覆盖 WImageLoadOptions', () {
      final image = ui.singleWhere((e) => e.names.contains('WImage'));
      expect(image.usage ?? '', contains('options:'));
      expect(image.usage ?? '', contains('WImageLoadOptions'));
    });
  });
  group('UI 模板入口覆盖', () {
    final entrypoints =
        (loadYaml(File('catalog/entrypoints.yaml').readAsStringSync())['w_tools_ui'] as List)
            .cast<String>();

    test('entrypoints 覆盖 UI 核心入口', () {
      expect(entrypoints, isNotEmpty);
      expect(entrypoints, contains('WImage'));
      expect(entrypoints, contains('WNotificationListener'));
    });

    for (final lang in <String>['zh', 'en']) {
      test('$lang 模板覆盖 UI 核心入口', () {
        final text = File('templates/agents/$lang/ui.md').readAsStringSync();
        for (final name in entrypoints) {
          expect(text, contains(name), reason: '$lang ui.md 缺少 $name');
        }
      });

      test('$lang 模板不再教旧扩展名', () {
        final text = File('templates/agents/$lang/ui.md').readAsStringSync();
        expect(text, isNot(contains('WHexColor')));
      });
    }
  });
}
