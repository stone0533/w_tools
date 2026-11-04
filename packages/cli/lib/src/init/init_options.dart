import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' show YamlException, YamlMap, loadYaml;

import '../doctor/config.dart';
import 'features.dart';
import 'manifest.dart';
import 'targets.dart';

/// init 参数合并后的结果（CLI 参数 > manifest > 配置 > 默认值）。
class InitOptions {
  const InitOptions({
    required this.profile,
    required this.features,
    required this.targets,
    required this.lang,
    required this.figma,
    required this.device,
    required this.check,
    required this.checkDrift,
    required this.force,
    required this.forceStarters,
    required this.figmaInstall,
    this.manifest,
  });

  final InitProfile profile;
  final InitFeatures features;
  final Set<String> targets;
  final String lang;
  final bool figma;
  final bool device;
  final bool check;
  final bool checkDrift;
  final bool force;
  final bool forceStarters;
  final String? figmaInstall;
  final InitManifest? manifest;

  /// 解析 argv；出错时抛 [InitOptionsException]（命令层转 exit 2）。
  static InitOptions resolve({
    required Directory root,
    required ArgResults args,
    required List<String> argv,
    required DoctorConfig config,
  }) {
    final checkDrift = args['check-drift'] as bool;
    final check = (args['check'] as bool) || checkDrift;
    // 普通 init / --force 也沿用上次选择；--reset 才显式回到默认。
    final manifest = (args['reset'] as bool) ? null : InitManifest.load(root);

    final targetsRaw = args['targets'] as String?;
    final targets = args['instructions'] as bool
        ? (targetsRaw != null && targetsRaw.trim().isNotEmpty
              ? targetsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
              : (manifest?.targets.toSet() ?? config.aiTargets.toSet()))
        : <String>{};
    final unknown = targets.difference(targetFiles.keys.toSet());
    if (unknown.isNotEmpty) {
      throw InitOptionsException(
        '未知 targets：${unknown.join(', ')}（可选：${targetFiles.keys.join(', ')}）',
      );
    }

    final lang = args.wasParsed('lang')
        ? args['lang'] as String
        : (manifest?.lang ?? config.aiLanguage);
    if (lang != 'zh' && lang != 'en') {
      throw InitOptionsException('未知语言：$lang（可选：zh, en）');
    }

    final profileName = args.wasParsed('profile')
        ? args['profile'] as String
        : (manifest?.profile ?? args['profile'] as String);
    final profile = InitProfile.values.firstWhere(
      (p) => p.name == profileName,
      orElse: () => throw InitOptionsException('未知 profile：$profileName'),
    );

    for (final spec in initFeatureSpecs) {
      final yes = '--${spec.flag}';
      final no = '--no-${spec.flag}';
      if (argv.contains(yes) && argv.contains(no)) {
        throw InitOptionsException('$yes 与 $no 不能同时使用');
      }
    }
    if (argv.contains('--figma') && argv.contains('--no-figma')) {
      throw const InitOptionsException('--figma 与 --no-figma 不能同时使用');
    }
    if (argv.contains('--device') && argv.contains('--no-device')) {
      throw const InitOptionsException('--device 与 --no-device 不能同时使用');
    }

    var features = manifest != null && !args.wasParsed('profile')
        ? InitFeatures.fromJson(manifest.profile, manifest.features)
        : InitFeatures.forProfile(profile);
    for (final spec in initFeatureSpecs) {
      if (args.wasParsed(spec.flag)) {
        features = features.withFeature(spec.feature, args[spec.flag] as bool);
      }
    }
    if (args['with-map'] as bool) {
      if (args.wasParsed('map') && args['map'] == false) {
        throw const InitOptionsException('--with-map 与 --no-map 不能同时使用');
      }
      features = features.withFeature(InitFeature.map, true);
    }

    final figma = args.wasParsed('figma')
        ? args['figma'] as bool
        : (manifest?.figma ?? _resolveFigma(root, config));
    final device = (args['device-test'] as bool)
        ? true
        : args.wasParsed('device')
        ? args['device'] as bool
        : (manifest?.device ?? _hasDependency(root, 'w_tools_device'));
    return InitOptions(
      profile: profile,
      features: features,
      targets: targets,
      lang: lang,
      figma: figma,
      device: device,
      check: check,
      checkDrift: checkDrift,
      force: args['force'] as bool,
      forceStarters: (args['force-starters'] as bool) || (args['force-ui'] as bool),
      figmaInstall: _figmaInstallLine(root),
      manifest: manifest,
    );
  }

  InitManifest toManifest({required String generator}) => InitManifest(
    profile: profile.name,
    features: features.toJson(),
    targets: targets.toList()..sort(),
    lang: lang,
    figma: figma,
    device: device,
    generator: generator,
  );
}

class InitOptionsException implements Exception {
  const InitOptionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _hasDependency(Directory root, String name) {
  final file = File('${root.path}/pubspec.yaml');
  if (!file.existsSync()) return false;
  try {
    final raw = loadYaml(file.readAsStringSync());
    if (raw is! YamlMap) return false;
    for (final key in const <String>['dependencies', 'dev_dependencies']) {
      final deps = raw[key];
      if (deps is YamlMap && deps.containsKey(name)) return true;
    }
  } on YamlException {
    return false;
  }
  return false;
}

({bool present, String? constraint}) _figmaDependency(Directory root) {
  final file = File('${root.path}/pubspec.yaml');
  if (!file.existsSync()) return (present: false, constraint: null);
  try {
    final raw = loadYaml(file.readAsStringSync());
    for (final key in const <String>['dependencies', 'dev_dependencies']) {
      final deps = raw is YamlMap ? raw[key] : null;
      if (deps is! YamlMap || !deps.containsKey('w_tools_figma')) continue;
      final value = deps['w_tools_figma'];
      return (present: true, constraint: value is String ? value : null);
    }
  } on YamlException {
    return (present: false, constraint: null);
  }
  return (present: false, constraint: null);
}

String? _figmaInstallLine(Directory root) {
  final dep = _figmaDependency(root);
  if (!dep.present) return null;
  if (dep.constraint == null) return '# w_tools_figma 已通过 path/git 安装';
  return 'dart pub add dev:w_tools_figma:${dep.constraint}';
}

bool _resolveFigma(Directory root, DoctorConfig config) {
  return switch (config.aiFigma) {
    'true' => true,
    'false' => false,
    _ => _figmaDependency(root).present,
  };
}
