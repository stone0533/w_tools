import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_channel.dart';
import 'package:w_tools_cli/src/feedback/feedback_command.dart' as command;

/// 反馈通道矩阵：本地台账优先 → Issue → 跳过。
///
/// 这组用例锁住「`path` 认本地台账、`submit` 却按项目根判定」的自相矛盾。
Directory _tmp(String prefix) => Directory.systemTemp.createTempSync(prefix);

/// 造一个 w_tools 仓库检出（pubspec name=w_tools + packages/cli + docs/feedback）。
Directory _repo(Directory root) {
  final repo = Directory(p.join(root.path, 'repo'))..createSync(recursive: true);
  File(p.join(repo.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
  final cli = Directory(p.join(repo.path, 'packages', 'cli'))..createSync(recursive: true);
  File(p.join(cli.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
  final feedback = Directory(p.join(repo.path, 'docs', 'feedback'))..createSync(recursive: true);
  File(p.join(feedback.path, 'README.md')).writeAsStringSync('''
# 反馈

| 包 | 待处理 | 最近更新 |
| --- | --- | --- |
| [api](api.md) | 0 | 2026-11-04 |
''');
  final config = File(p.join(repo.path, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true);
  config.writeAsStringSync(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {'name': 'w_tools_cli', 'rootUri': '../packages/cli'},
      ],
    }),
  );
  return repo;
}

/// 造一个消费方项目。
///
/// [linkRepo] 非空时把 `w_tools_cli` 解析到那个仓库（path 依赖）；
/// 否则解析到 `root/pubcache/w_tools_cli`（模拟 pub cache，本机没有仓库）。
Directory _consumer(Directory root, {String? linkRepo}) {
  final app = Directory(p.join(root.path, 'app'))..createSync(recursive: true);
  File(p.join(app.path, 'pubspec.yaml')).writeAsStringSync('name: demo_app\n');
  final String cliRoot;
  if (linkRepo != null) {
    cliRoot = p.join(linkRepo, 'packages', 'cli');
  } else {
    final cache = Directory(p.join(root.path, 'pubcache', 'w_tools_cli'))
      ..createSync(recursive: true);
    File(p.join(cache.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
    cliRoot = cache.path;
  }
  final config = File(p.join(app.path, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true);
  config.writeAsStringSync(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {'name': 'w_tools_cli', 'rootUri': cliRoot},
      ],
    }),
  );
  return app;
}

void _enableFeedback(Directory app) {
  File(p.join(app.path, '.w_tools_doctor.yaml')).writeAsStringSync('''
feedback:
  enabled: true
''');
}

const _body = '''- 包/版本：w_tools_ui 5.0.0
- 环境：Flutter 3.44 / macOS
- 命令 / 输入：WImage(...)
- 期望：显示
- 实际：空白
- 影响：页面不可用
- 建议：补提示
- 复现数据：见附件
''';

void main() {
  group('FeedbackChannel.resolve', () {
    test('项目根就是仓库 → ledger，不读开关', () {
      final root = _tmp('wt_ch_repo_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);

      final channel = FeedbackChannel.resolve(projectRoot: repo, issueEnabled: false);

      expect(channel.mode, FeedbackMode.ledger);
      expect(channel.isWtoolsRepo, isTrue);
      expect(channel.ledgerDir, p.join(repo.path, 'docs', 'feedback'));
    });

    test('消费方开启反馈 + 本机有仓库 → ledger（本地优先，不建 Issue）', () {
      final root = _tmp('wt_ch_local_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root, linkRepo: repo.path);

      final channel = FeedbackChannel.resolve(projectRoot: app, issueEnabled: true);

      expect(channel.mode, FeedbackMode.ledger);
      expect(channel.isWtoolsRepo, isFalse);
      expect(channel.enabled, isTrue);
      expect(channel.repoRoot, repo.path);
      expect(channel.ledgerDir, p.join(repo.path, 'docs', 'feedback'));
    });

    test('pub cache 里的 git 依赖不算「本机库」：不开到 Issue，也不往里写', () {
      final root = _tmp('wt_ch_cache_');
      addTearDown(() => root.deleteSync(recursive: true));
      final cache = Directory(p.join(root.path, 'pubcache'))..createSync(recursive: true);
      final repo = _repo(cache);
      final app = _consumer(root, linkRepo: repo.path);

      final channel = FeedbackChannel.resolve(
        projectRoot: app,
        issueEnabled: true,
        pubCache: cache.path,
      );

      expect(channel.mode, FeedbackMode.issue);
      expect(channel.hasLedger, isFalse);
      expect(isPubCachePath(repo.path, cache: cache.path), isTrue);
    });

    test('feedback.ledger 指定别处的仓库 → ledger（即使依赖里解析不到）', () {
      final root = _tmp('wt_ch_override_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root); // 依赖里没有 w_tools，只有配置指过去
      final relative = p.relative(repo.path, from: app.path);

      final channel = FeedbackChannel.resolve(
        projectRoot: app,
        issueEnabled: true,
        ledgerOverride: relative,
      );

      expect(channel.mode, FeedbackMode.ledger);
      expect(channel.ledgerDir, p.join(repo.path, 'docs', 'feedback'));
      expect(channel.ledgerOverride, repo.path);
    });

    test('feedback.ledger 指向非仓库 → 忽略并标记，回落到 Issue', () {
      final root = _tmp('wt_ch_override_bad_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);
      final bogus = Directory(p.join(root.path, 'not_a_repo'))..createSync(recursive: true);

      final channel = FeedbackChannel.resolve(
        projectRoot: app,
        issueEnabled: true,
        ledgerOverride: bogus.path,
      );

      expect(channel.mode, FeedbackMode.issue);
      expect(channel.hasLedger, isFalse);
      expect(channel.ledgerOverrideInvalid, bogus.path);
    });

    test('feedback.ledger 指定时 pub cache 排除不生效（用户指名要写）', () {
      final root = _tmp('wt_ch_override_cache_');
      addTearDown(() => root.deleteSync(recursive: true));
      final cache = Directory(p.join(root.path, 'pubcache'))..createSync(recursive: true);
      final repo = _repo(cache);
      final app = _consumer(root);

      final channel = FeedbackChannel.resolve(
        projectRoot: app,
        issueEnabled: true,
        ledgerOverride: repo.path,
        pubCache: cache.path,
      );

      expect(channel.mode, FeedbackMode.ledger);
      expect(channel.ledgerDir, p.join(repo.path, 'docs', 'feedback'));
    });

    test('消费方开启反馈 + 本机没有仓库 → issue', () {
      final root = _tmp('wt_ch_issue_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);

      final channel = FeedbackChannel.resolve(projectRoot: app, issueEnabled: true);

      expect(channel.mode, FeedbackMode.issue);
      expect(channel.hasLedger, isFalse);
      expect(channel.ledgerDir, isNull);
    });

    test('未开启反馈 → disabled；本地台账仍保留，但 submit 默认不写', () {
      final root = _tmp('wt_ch_off_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root, linkRepo: repo.path);

      final channel = FeedbackChannel.resolve(projectRoot: app, issueEnabled: false);

      expect(channel.mode, FeedbackMode.disabled);
      expect(channel.enabled, isFalse);
      // 保留「本机有台账」的事实：--ledger / path / status 才不会说反话
      expect(channel.hasLedger, isTrue);

      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);
      final skipped = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
      ]);
      expect(skipped.exitCode, 4);
      expect(File(p.join(repo.path, 'docs', 'feedback', 'ui.md')).existsSync(), isFalse);
    });

    test('feedback.ledger 让「clone 在别处」的消费方也能写台账', () {
      final root = _tmp('wt_ch_override_write_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root); // 没有 path 依赖
      _enableFeedback(app);
      File(p.join(app.path, '.w_tools_doctor.yaml')).writeAsStringSync('''
feedback:
  enabled: true
  ledger: ${repo.path}
''');
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=WImage 空白',
        '--body-file=${body.path}',
      ]);

      expect(result.exitCode, 0);
      expect(
        File(p.join(repo.path, 'docs', 'feedback', 'ui.md')).readAsStringSync(),
        contains('### [待处理] ui: WImage 空白'),
      );
    });

    test('未开启时 --ledger 仍可显式写本地台账', () {
      final root = _tmp('wt_ch_off_ledger_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root, linkRepo: repo.path);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
        '--ledger',
      ]);

      expect(result.exitCode, 0);
      expect(
        File(p.join(repo.path, 'docs', 'feedback', 'ui.md')).readAsStringSync(),
        contains('### [待处理] ui: t'),
      );
    });
  });

  group('feedback submit 路由（进程内）', () {
    test('未开启 → exit 4，什么都不写', () {
      final root = _tmp('wt_ch_skip_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
      ]);

      expect(result.exitCode, 4);
      expect(Directory(p.join(app.path, 'docs')).existsSync(), isFalse);
    });

    test('未开启 + --issue → exit 2（开关是硬门禁）', () {
      final root = _tmp('wt_ch_bypass_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
        '--issue',
        // 万一门禁被去掉，也只会打到一个不存在的仓库（不会真的建 issue）
        '--repo=stone0533/__w_tools_feedback_guard__',
      ]);

      expect(result.exitCode, 2);
    });

    test('--ledger 没有本地仓库 → exit 2', () {
      final root = _tmp('wt_ch_ledger_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
        '--ledger',
      ]);

      expect(result.exitCode, 2);
    });

    test('开启 + 本机有仓库 → 写进那个仓库的台账并更新索引（不建 Issue）', () {
      final root = _tmp('wt_ch_write_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root, linkRepo: repo.path);
      _enableFeedback(app);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=WImage 空白',
        '--body-file=${body.path}',
      ]);

      expect(result.exitCode, 0);
      final ledger = File(p.join(repo.path, 'docs', 'feedback', 'ui.md'));
      expect(ledger.existsSync(), isTrue);
      expect(ledger.readAsStringSync(), contains('### [待处理] ui: WImage 空白'));
      expect(
        File(p.join(repo.path, 'docs', 'feedback', 'README.md')).readAsStringSync(),
        contains('| [ui](ui.md) | 1 |'),
      );
    });

    test('开启 + 本机没有仓库 → 走 Issue（失败也不写台账、不谎报成功）', () {
      final root = _tmp('wt_ch_issue_route_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);
      _enableFeedback(app);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${app.path}',
        '--package=ui',
        '--title=t',
        '--body-file=${body.path}',
        // 有 gh 时打到不存在的仓库（失败 → exit 1）；没有 gh 时退出 3。都不该是 0。
        '--repo=stone0533/__w_tools_feedback_guard__',
      ]);

      expect(result.exitCode, anyOf(1, 3));
      expect(File(p.join(app.path, 'docs', 'feedback', 'ui.md')).existsSync(), isFalse);
    });

    test('仓库自身不带开关也默认写台账', () {
      final root = _tmp('wt_ch_self_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_body);

      final result = command.run(<String>[
        'submit',
        '--root=${repo.path}',
        '--package=cli',
        '--title=测试',
        '--body-file=${body.path}',
      ]);

      expect(result.exitCode, 0);
      expect(
        File(p.join(repo.path, 'docs', 'feedback', 'cli.md')).existsSync(),
        isTrue,
      );
    });
  });

  group('status / path / lint 与 submit 同一判定', () {
    test('消费方开启 + 本机有仓库：status 报 ledger，path 指向该仓库', () {
      final root = _tmp('wt_ch_status_');
      addTearDown(() => root.deleteSync(recursive: true));
      final repo = _repo(root);
      final app = _consumer(root, linkRepo: repo.path);
      _enableFeedback(app);

      expect(
        command.run(<String>['status', '--root=${app.path}']).exitCode,
        0,
      );
      expect(
        command.run(<String>['path', '--root=${app.path}', '--package=ui']).exitCode,
        0,
      );
    });

    test('本机没有台账时 lint 跳过（exit 0，不再输出 ✓ 0 条）', () {
      final root = _tmp('wt_ch_lint_');
      addTearDown(() => root.deleteSync(recursive: true));
      final app = _consumer(root);

      expect(command.run(<String>['lint', '--root=${app.path}']).exitCode, 0);
    });
  });
}
