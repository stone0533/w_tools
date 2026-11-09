import 'dart:io';

import '../common/project_pubspec.dart';
import '../doctor/config.dart';
import 'features.dart';
import 'generated_files.dart';
import 'manifest.dart';
import 'targets.dart';
import 'templates.dart';

/// 用 `.w_tools/init.json` 回放 `init` 会写出的内容。
///
/// doctor R8 用它做**内容**比对：CLI 升了版本但模板没变时不该报警
/// （只比版本号会让每个补丁版本都给所有消费方报一次 warn）。
/// 拿不到 manifest / 配置损坏时返回 null，调用方退回版本标记比对。
class ExpectedArtifacts {
  const ExpectedArtifacts._();

  static Map<String, String>? render(Directory root) {
    final manifest = InitManifest.load(root);
    if (manifest == null) return null;

    final DoctorConfig config;
    try {
      config = DoctorConfig.load(root);
    } on Object {
      return null;
    }
    final pubspec = ProjectPubspec.load(root);
    final app = pubspec.declaredName ?? 'app';
    final features = InitFeatures.fromJson(manifest.profile, manifest.features);

    final out = <String, String>{
      config.toolkitEntry: InitTemplates.toolkit(features: features),
    };
    for (final target in manifest.targets) {
      final rel = targetFiles[target];
      if (rel == null) continue;
      out[rel] = InitTemplates.agentsBlock(
        lang: manifest.lang,
        app: app,
        isFlutter: pubspec.isFlutter,
        withUi: features.ui,
        withApp: features.app,
        withForm: features.form,
        withApi: features.api,
        withAsync: features.asyncFeature,
        withToast: features.toast,
        withQr: features.qr,
        withMap: features.map,
        withFigma: manifest.figma,
        withDevice: manifest.device,
        figmaInstall: manifest.figmaInstall,
        toolkitEntry: config.toolkitEntry,
        banned: config.banned,
      );
    }
    if (manifest.aiPrompts && manifest.targets.isNotEmpty) {
      out[GeneratedFiles.aiPrompts] = InitTemplates.aiPrompts(
        lang: manifest.lang,
        features: features,
        rulesFiles: InitTemplates.rulesFiles(manifest.targets.toSet()),
        toolkitImport: InitTemplates.toolkitImport(app, config.toolkitEntry),
        isFlutter: pubspec.isFlutter,
        usesAggregate: pubspec.usesAggregate,
      );
    }
    return out;
  }
}
