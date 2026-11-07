import 'dart:io';

import 'package:args/args.dart';

import '../common/project_pubspec.dart';
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
    required this.aiPrompts,
    required this.check,
    required this.checkDrift,
    required this.force,
    required this.forceConfig,
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
  final bool aiPrompts;
  final bool check;
  final bool checkDrift;
  final bool force;
  final bool forceConfig;
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
    if (argv.contains('--ai-prompts') && argv.contains('--no-ai-prompts')) {
      throw const InitOptionsException('--ai-prompts 与 --no-ai-prompts 不能同时使用');
    }
    if (argv.contains('--no-instructions') && argv.contains('--ai-prompts')) {
      throw const InitOptionsException('--no-instructions 与 --ai-prompts 不能同时使用');
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

    final pubspec = ProjectPubspec.load(root);
    final figma = args.wasParsed('figma')
        ? args['figma'] as bool
        : (manifest?.figma ?? _resolveFigma(pubspec, config));
    final aiPrompts = targets.isEmpty
        ? false
        : args.wasParsed('ai-prompts')
        ? args['ai-prompts'] as bool
        : (manifest?.aiPrompts ?? true);
    final device = (args['device-test'] as bool)
        ? true
        : args.wasParsed('device')
        ? args['device'] as bool
        : (manifest?.device ?? pubspec.hasDependency('w_tools_device'));
    return InitOptions(
      profile: profile,
      features: features,
      targets: targets,
      lang: lang,
      figma: figma,
      device: device,
      aiPrompts: aiPrompts,
      check: check,
      checkDrift: checkDrift,
      force: args['force'] as bool,
      forceConfig: args['force-config'] as bool,
      forceStarters: (args['force-starters'] as bool) || (args['force-ui'] as bool),
      figmaInstall: _figmaInstallLine(pubspec),
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
    aiPrompts: aiPrompts,
    generator: generator,
  );
}

class InitOptionsException implements Exception {
  const InitOptionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

String? _figmaInstallLine(ProjectPubspec pubspec) {
  if (!pubspec.hasDependency('w_tools_figma')) return null;
  final constraint = pubspec.constraint('w_tools_figma');
  if (constraint == null) return '# w_tools_figma 已通过 path/git 安装';
  return 'dart pub add dev:w_tools_figma:$constraint';
}

bool _resolveFigma(ProjectPubspec pubspec, DoctorConfig config) {
  return switch (config.aiFigma) {
    'true' => true,
    'false' => false,
    _ => pubspec.hasDependency('w_tools_figma'),
  };
}
