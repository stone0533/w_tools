import 'dart:convert';
import 'dart:io';

/// `init` 生成时使用的参数，供 `--check` 回放，避免参数不同导致假 drift。
class InitManifest {
  const InitManifest({
    required this.profile,
    required this.features,
    required this.targets,
    required this.lang,
    required this.figma,
    required this.device,
    this.aiPrompts = true,
    this.generator,
    this.figmaInstall,
  });

  final String profile;
  final Map<String, bool> features;
  final List<String> targets;
  final String lang;
  final bool figma;
  final bool device;
  final bool aiPrompts;

  /// 写这份 manifest 的 CLI 版本（老文件可能没有）。
  final String? generator;

  /// `--figma-install` 的自定义安装命令；默认命令不记录。
  ///
  /// R8 回放生成内容时要还原同一份文本，否则会把「自定义安装命令」误判成漂移。
  final String? figmaInstall;

  /// 新位置：`.w_tools/init.json`（工具元数据统一收敛在 `.w_tools/`）。
  static const fileName = '.w_tools/init.json';

  /// 旧位置（1.8.x 及以前），只用于迁移。
  static const legacyFileName = '.w_tools_init.json';

  static File fileFor(Directory root) => File('${root.path}/$fileName');

  static File legacyFileFor(Directory root) => File('${root.path}/$legacyFileName');

  /// 把旧的 `.w_tools_init.json` 搬到 `.w_tools/init.json`；返回是否发生了迁移。
  static bool migrateLegacy(Directory root) {
    final legacy = legacyFileFor(root);
    if (!legacy.existsSync()) return false;
    final target = fileFor(root);
    target.parent.createSync(recursive: true);
    if (!target.existsSync()) {
      legacy.renameSync(target.path);
    } else {
      legacy.deleteSync();
    }
    return true;
  }

  static InitManifest? load(Directory root) {
    final file = fileFor(root);
    if (!file.existsSync()) {
      final legacy = legacyFileFor(root);
      if (legacy.existsSync()) {
        // 老项目直接读旧文件，写回时（init）会顺手迁移
        return _decode(legacy.readAsStringSync());
      }
      return null;
    }
    return _decode(file.readAsStringSync());
  }

  static InitManifest? _decode(String text) {
    try {
      final raw = jsonDecode(text);
      if (raw is! Map) return null;
      final features = raw['features'];
      return InitManifest(
        profile: '${raw['profile'] ?? 'full'}',
        features: features is Map
            ? <String, bool>{
                for (final entry in features.entries) '${entry.key}': entry.value == true,
              }
            : const <String, bool>{},
        targets: raw['targets'] is List
            ? (raw['targets'] as List).map((e) => '$e').toList()
            : const <String>['agents'],
        lang: '${raw['lang'] ?? 'zh'}',
        figma: raw['figma'] == true,
        device: raw['device'] == true,
        aiPrompts: raw['aiPrompts'] != false,
        generator: raw['generator'] is String ? '${raw['generator']}' : null,
        figmaInstall: raw['figmaInstall'] is String ? '${raw['figmaInstall']}' : null,
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  String encode() =>
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema': 'w_tools_cli.init/1',
        'profile': profile,
        'features': features,
        'targets': targets,
        'lang': lang,
        'figma': figma,
        'device': device,
        'aiPrompts': aiPrompts,
        if (generator != null) 'generator': generator,
        if (figmaInstall != null) 'figmaInstall': figmaInstall,
      })}\n';
}
