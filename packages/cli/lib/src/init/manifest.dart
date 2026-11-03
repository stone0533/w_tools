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
  });

  final String profile;
  final Map<String, bool> features;
  final List<String> targets;
  final String lang;
  final bool figma;
  final bool device;

  static const fileName = '.w_tools_init.json';

  static File fileFor(Directory root) => File('${root.path}/$fileName');

  static InitManifest? load(Directory root) {
    final file = fileFor(root);
    if (!file.existsSync()) return null;
    try {
      final raw = jsonDecode(file.readAsStringSync());
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
      })}\n';
}
