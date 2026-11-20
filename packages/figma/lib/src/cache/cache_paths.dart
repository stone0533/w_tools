import 'dart:io';

/// 缓存 / token / 用量文件的路径解析（只算路径，不读写内容）。
class CachePaths {
  CachePaths(
    this.root, {
    String? home,
    bool? windows,
    Map<String, String>? environment,
  })  : _home = home ?? defaultHome(),
        _windows = windows ?? Platform.isWindows,
        _env = environment ?? Platform.environment;

  final Directory root;
  final String _home;
  final bool _windows;
  final Map<String, String> _env;

  static String defaultHome() {
    final env = Platform.environment;
    return env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
  }

  /// 项目在缓存里的稳定标识：`<目录名>-<hash8>`（FNV-1a，跨进程稳定）。
  String get projectId {
    final path = root.absolute.path;
    var hash = 0x811c9dc5;
    for (final unit in path.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final name = path.split(Platform.pathSeparator).where((e) => e.isNotEmpty).lastOrNull;
    return '${name ?? 'project'}-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// 账号级缓存根（用量 / 预算也在这里）。
  ///
  /// Windows 用 `%LOCALAPPDATA%\w_tools\figma`，其它平台 `~/.cache/w_tools/figma`。
  Directory get cacheRoot {
    if (_windows) {
      final local = _env['LOCALAPPDATA'];
      if (local != null && local.isNotEmpty) {
        return Directory('$local\\w_tools\\figma');
      }
    }
    return Directory('$_home/.cache/w_tools/figma');
  }

  /// 项目缓存目录。
  Directory get dir => Directory('${cacheRoot.path}/$projectId');

  /// 令牌文件：Windows 用 `%APPDATA%\w_tools\figma-token`，其它平台 `~/.config/w_tools/`。
  File get tokenFile {
    if (_windows) {
      final appData = _env['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return File('$appData\\w_tools\\figma-token');
      }
    }
    return File('$_home/.config/w_tools/figma-token');
  }

  File get usageFile => File('${cacheRoot.path}/_usage.log');
  File get budgetFile => File('${cacheRoot.path}/_budget.json');

  /// 缓存文件名：`<kind>-<fileKey>-<idslug>[-s<scale>].json`。
  File cacheFile({
    required String kind,
    required String fileKey,
    String? ids,
    int? scale,
    int? depth,
  }) {
    final slug = ids == null ? '' : '-${ids.replaceAll(RegExp(r'[:,.]'), '-')}';
    final suffix = depth != null
        ? '-d$depth'
        : scale == null
            ? ''
            : '-s$scale';
    return File('${dir.path}/$kind-$fileKey$slug$suffix.json');
  }

  /// 记录文件版本的小文件（Tier 3 的 `file/meta` 结果）。
  File metaFile(String fileKey) => File('${dir.path}/_meta-$fileKey.json');
}
