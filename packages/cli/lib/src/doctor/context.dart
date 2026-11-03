import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'config.dart';
import '../common/pubspec_lock.dart';

/// 扫描上下文：项目根、pubspec、待查的 dart 文件。
class ProjectContext {
  ProjectContext({
    required this.root,
    required this.pubspec,
    required this.files,
    required this.config,
  });

  final Directory root;

  final DoctorConfig config;

  /// 跨 context / doctor 共享的项目事实（懒计算）。
  late final ProjectFacts facts = ProjectFacts.compute(this);

  /// 规则之间共享文件内容，避免同一个文件被 8 条规则各读一次
  final Map<String, String> _cache = <String, String>{};

  /// pubspec.yaml 解析后的内容（未解析成功时为空 map）
  final YamlMap pubspec;

  /// 需要扫描的 dart 文件（相对路径）
  final List<String> files;

  String get name => (pubspec['name'] as String?) ?? p.basename(root.path);

  static ProjectContext load(Directory root, DoctorConfig config, {bool includeTests = false}) {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    YamlMap pubspec = YamlMap();
    if (pubspecFile.existsSync()) {
      final raw = loadYaml(pubspecFile.readAsStringSync());
      if (raw is YamlMap) pubspec = raw;
    }

    final roots = <String>['lib'];
    if (includeTests) roots.addAll(<String>['test', 'tool', 'integration_test']);

    final files = <String>[];
    for (final dir in roots) {
      final d = Directory(p.join(root.path, dir));
      if (!d.existsSync()) continue;
      for (final entity in d.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = p.relative(entity.path, from: root.path).replaceAll('\\', '/');
        if (rel.endsWith('.g.dart') || rel.endsWith('.freezed.dart')) continue;
        if (config.ignore.any((raw) => _matchesIgnore(rel, raw))) continue;
        files.add(rel);
      }
    }
    files.sort();
    return ProjectContext(root: root, pubspec: pubspec, files: files, config: config);
  }

  String read(String relPath) => _cache.putIfAbsent(
    relPath,
    () => File(p.join(root.path, relPath)).readAsStringSync(),
  );

  /// 忽略项按路径前缀匹配：`lib/app/generated` 只命中该目录及其子文件，
  /// 不会误伤 `lib/app/generated2/`。
  static bool _matchesIgnore(String rel, String raw) {
    final prefix = raw.replaceAll('*', '');
    if (rel == prefix) return true;
    final withSlash = prefix.endsWith('/') ? prefix : '$prefix/';
    return rel.startsWith(withSlash);
  }

  /// 只取 `lib/` 或 `test/` 等前缀下的文件。
  Iterable<String> filesUnder(String prefix) =>
      files.where((f) => f == prefix || f.startsWith('$prefix/'));
}

/// context / doctor 共用的事实。
///
/// 只在这里解析 toolkit / 暂存层 / 依赖，避免两个命令各算一套。
class ProjectFacts {
  ProjectFacts._({
    required this.ctx,
    required this.dependencies,
    required this.subpackageDependencies,
    required this.hasStagingDirectory,
    required this.stagingFiles,
    required this.missingStagedFiles,
    required this.toolkitPath,
    required this.toolkitExports,
    required this.isFlutter,
  });

  final ProjectContext ctx;
  final List<String> dependencies;
  final List<String> subpackageDependencies;
  final bool hasStagingDirectory;
  final List<String> stagingFiles;
  final List<String> missingStagedFiles;
  final String? toolkitPath;
  final List<String> toolkitExports;
  final bool isFlutter;

  /// pubspec.lock 版本；按需读取，避免不查版本的规则触发 lock 解析。
  late final Map<String, String> packages = readLockedVersions(ctx.root);

  static ProjectFacts compute(ProjectContext ctx) {
    final deps = <String>[];
    final depsNode = ctx.pubspec['dependencies'];
    if (depsNode is YamlMap) {
      deps.addAll(
        depsNode.keys.map((e) => '$e').where((e) => e.startsWith('w_tools')).toList(),
      );
    }
    deps.sort();
    final subpackages = deps.where((e) => e.startsWith('w_tools_')).toList();

    final toolkitFile = File(p.join(ctx.root.path, ctx.config.toolkitEntry));
    var exports = <String>[];
    String? actualToolkitPath;
    if (toolkitFile.existsSync()) {
      actualToolkitPath = ctx.config.toolkitEntry;
      final pattern = RegExp(r"""export\s+['"]package:(w_tools_[a-z0-9_]+)/""");
      exports =
          pattern
              .allMatches(toolkitFile.readAsStringSync())
              .map((m) => m.group(1)!)
              .toSet()
              .toList()
            ..sort();
    }

    final stagingDir = Directory(p.join(ctx.root.path, designSystemDirPath));
    final stagingFiles = ctx
        .filesUnder(designSystemDirPath)
        .where((file) => file.endsWith('.dart'))
        .toList();
    final missing = <String>[];
    for (final file in stagingFiles) {
      final head = ctx.read(file).split('\n').take(10).join('\n');
      if (!head.contains('// STAGED:')) missing.add(file);
    }

    return ProjectFacts._(
      ctx: ctx,
      dependencies: deps,
      subpackageDependencies: subpackages,
      hasStagingDirectory: stagingDir.existsSync(),
      stagingFiles: stagingFiles,
      missingStagedFiles: missing,
      toolkitPath: actualToolkitPath,
      toolkitExports: exports,
      isFlutter: depsNode is YamlMap && depsNode.containsKey('flutter'),
    );
  }
}
