import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 当前 `w_tools_cli` 的安装位置，以及它是否指向一个**仓库检出**。
///
/// 用途：AI 需要知道「库侧 `docs/feedback/` 在不在本机」。
/// - 路径依赖 / 仓库内运行时：`repoRoot` 是仓库根，`feedbackDir` 可用；
/// - 从 pub cache 运行时：不是仓库，`isRepoCheckout = false`，只能写消费方的本地收件箱。
class InstallInfo {
  const InstallInfo({
    required this.packageRoot,
    required this.repoRoot,
    required this.isRepoCheckout,
    required this.feedbackDir,
  });

  final String packageRoot;
  final String? repoRoot;
  final bool isRepoCheckout;
  final String? feedbackDir;

  Map<String, Object?> toJson() => <String, Object?>{
    'packageRoot': packageRoot,
    'repoRoot': repoRoot,
    'isRepoCheckout': isRepoCheckout,
    'feedbackDir': feedbackDir,
  };

  /// [projectRoot] 用来读它的 `.dart_tool/package_config.json`（最可靠的解析来源）。
  static InstallInfo detect({Directory? projectRoot}) {
    final pkg = _packageRootFromConfig(projectRoot) ?? _packageRootFromScript();
    final repo = _repoRoot(pkg);
    final feedback = repo == null ? null : p.join(repo, 'docs', 'feedback');
    final isCheckout = feedback != null && Directory(feedback).existsSync();
    return InstallInfo(
      packageRoot: pkg,
      repoRoot: repo,
      isRepoCheckout: isCheckout,
      feedbackDir: isCheckout ? feedback : null,
    );
  }

  /// 从项目的 `package_config.json` 读 `w_tools_cli` 的真实位置（path / git 依赖都适用）。
  static String? _packageRootFromConfig(Directory? projectRoot) {
    if (projectRoot == null) return null;
    final config = File(p.join(projectRoot.path, '.dart_tool', 'package_config.json'));
    if (!config.existsSync()) return null;
    try {
      final data = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
      final packages = data['packages'];
      if (packages is! List) return null;
      for (final entry in packages) {
        if (entry is! Map || entry['name'] != 'w_tools_cli') continue;
        final uri = entry['rootUri'];
        if (uri is! String) continue;
        final resolved = Uri.parse(uri).isAbsolute
            ? Uri.parse(uri)
            : config.absolute.uri.resolve(uri);
        return p.normalize(Directory.fromUri(resolved).path);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// 兜底：从入口脚本向上找 `pubspec.yaml`（`name: w_tools_cli`）。
  static String _packageRootFromScript() {
    var dir = File(Platform.script.toFilePath()).parent;
    for (var i = 0; i < 8; i++) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync() && pubspec.readAsStringSync().contains('name: w_tools_cli')) {
        return dir.path;
      }
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }
    return Directory.current.path;
  }

  /// 包根在 `<repo>/packages/cli` 时，上两级就是仓库根。
  static String? _repoRoot(String packageRoot) {
    final packagesDir = Directory(packageRoot).parent;
    if (p.basename(packagesDir.path) != 'packages') return null;
    final repo = packagesDir.parent;
    return repo.path == '/' ? null : repo.path;
  }
}
