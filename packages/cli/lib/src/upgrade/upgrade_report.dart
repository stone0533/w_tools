import 'dart:convert';

import 'upgrade_plan.dart';

/// 一次升级的结果（渲染用）；先算计划、再写文件，报告只负责展示。
class UpgradeOutcome {
  const UpgradeOutcome({
    required this.projectName,
    required this.mode,
    this.written = const <String, String>{},
    this.pubCommand,
    this.pubExit,
    this.pubOutput,
    this.restored = false,
    this.next = const <String>[],
  });

  final String projectName;

  /// `check` / `dry-run` / `write`
  final String mode;
  final Map<String, String> written;
  final String? pubCommand;
  final int? pubExit;

  /// `pub get` 失败时的输出尾巴（给人和 AI 看冲突原因）。
  final String? pubOutput;

  /// `pub get` 失败后 pubspec 已还原。
  final bool restored;
  final List<String> next;

  Map<String, Object?> toJson(UpgradePlan plan) {
    final packages = plan.packages;
    return <String, Object?>{
      'schema': 'w_tools_cli.upgrade/1',
      'schemaVersion': 1,
      'ok': !plan.hasFindings && !restored,
      'hosted': plan.hosted,
      'mode': mode,
      'project': projectName,
      'packages': <Map<String, Object?>>[for (final p in packages) p.toJson()],
      'summary': <String, Object?>{
        'checked': packages.length,
        'outdated': plan.count(UpgradeStatus.outdated),
        'upToDate': plan.count(UpgradeStatus.upToDate),
        'majorBlocked': plan.count(UpgradeStatus.majorBlocked),
        'sdkBlocked': plan.count(UpgradeStatus.sdkBlocked),
        'skipped': plan.count(UpgradeStatus.skipped),
        'lockBehind': packages.where((p) => p.lockBehind).length,
        'written': written.length,
      },
      'pub': <String, Object?>{
        'ran': pubCommand != null,
        if (pubCommand != null) 'command': pubCommand,
        if (pubExit != null) 'exitCode': pubExit,
        if (pubOutput != null) 'output': pubOutput,
        'restored': restored,
      },
      'next': next,
    };
  }

  String toJsonText(UpgradePlan plan) => const JsonEncoder.withIndent('  ').convert(toJson(plan));

  String toText(UpgradePlan plan) {
    final buffer = StringBuffer()
      ..writeln('w_tools upgrade（${_modeLabel()}）')
      ..writeln('项目：$projectName')
      ..writeln('源：${plan.hosted}');

    if (plan.packages.isEmpty) {
      buffer
        ..writeln()
        ..writeln('没有 w_tools* 依赖，无需处理。');
      return buffer.toString();
    }

    final nameWidth = _width(plan.packages.map((p) => p.name));
    final declaredWidth = _width(plan.packages.map((p) => p.declared ?? '-'));
    buffer
      ..writeln()
      ..writeln(
        '  ${'name'.padRight(nameWidth)}  '
        '${'declared'.padRight(declaredWidth)}  '
        '${'lock'.padRight(8)}  ${'latest'.padRight(8)}  status',
      );
    for (final p in plan.packages) {
      final status = _statusLabel(p);
      final detail = p.reason == null ? '' : '（${p.reason}）';
      buffer.writeln(
        '  ${p.name.padRight(nameWidth)}  '
        '${(p.declared ?? '-').padRight(declaredWidth)}  '
        '${(p.locked ?? '-').padRight(8)}  '
        '${(p.latest?.version ?? '-').padRight(8)}  '
        '$status$detail',
      );
    }

    final outdated = plan.count(UpgradeStatus.outdated);
    buffer.writeln();
    if (outdated > 0) {
      buffer.writeln(
        '$outdated 个可升级：${plan.writable.map((p) => p.name).join('、')}',
      );
    } else {
      buffer.writeln('${plan.packages.length} 个包全部已是最新。');
    }
    final majorBlocked = plan.count(UpgradeStatus.majorBlocked);
    if (majorBlocked > 0) {
      buffer.writeln('$majorBlocked 个跨 major 未处理：确认后用 --major（或 --only=<包>）。');
    }

    if (written.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          restored
              ? '改动曾写入 pubspec.yaml，pub get 失败后已还原：'
              : (mode == 'write' ? '已写入 pubspec.yaml：' : '--dry-run：以下改动未写入'),
        );
      written.forEach((name, target) {
        final before = plan.packages.firstWhere((p) => p.name == name).declared;
        buffer.writeln('  $name: $before -> $target');
      });
    }
    if (restored) {
      buffer.writeln('pub get 失败，pubspec.yaml 已还原。');
    }
    if (pubCommand != null) {
      buffer.writeln(
        pubExit == 0 ? '$pubCommand … 完成' : '$pubCommand … 失败（exit $pubExit）',
      );
    }
    if (pubOutput != null) {
      buffer.writeln('pub 输出（末尾）：');
      for (final line in pubOutput!.split('\n')) {
        buffer.writeln('  $line');
      }
    }
    if (next.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('next:');
      for (final line in next) {
        buffer.writeln('  $line');
      }
    }
    return buffer.toString().trimRight();
  }

  String toPrompt(UpgradePlan plan) {
    final lines = <String>[
      '# w_tools upgrade（${_modeLabel()}，源 ${plan.hosted}）',
      '项目: $projectName',
      for (final p in plan.packages)
        switch (p.status) {
          UpgradeStatus.outdated =>
            '可升级 ${p.name}: ${p.declared} -> ${p.target}'
                '${p.locked == null ? '' : '（lock ${p.locked}）'}',
          UpgradeStatus.majorBlocked =>
            '跨major ${p.name}: ${p.declared} -> ${p.latest?.version}'
                '${p.reason == null ? '' : '（${p.reason}）'}',
          UpgradeStatus.sdkBlocked => 'sdk ${p.name}: ${p.reason}',
          UpgradeStatus.skipped => '跳过 ${p.name}: ${p.reason}',
          UpgradeStatus.upToDate => '已最新 ${p.name}: ${p.locked ?? p.declared}',
        },
      '汇总: 可升级 ${plan.count(UpgradeStatus.outdated)} / 已最新 ${plan.count(UpgradeStatus.upToDate)}'
          ' / 跳过 ${plan.count(UpgradeStatus.skipped)}',
      if (written.isNotEmpty) '写入: ${written.entries.map((e) => '${e.key} ${e.value}').join('、')}',
      if (pubCommand != null) 'pub: $pubCommand exit ${pubExit ?? '?'}',
      for (final line in next) 'next: $line',
    ];
    return lines.join('\n');
  }

  String _modeLabel() => switch (mode) {
    'check' => '只检查',
    'dry-run' => '预览',
    _ => '写入',
  };

  String _statusLabel(PackageUpgrade p) {
    if (written.containsKey(p.name)) {
      if (mode != 'write') return '可升级';
      return restored ? '已回滚' : '已写入';
    }
    return switch (p.status) {
      UpgradeStatus.upToDate => '已最新',
      UpgradeStatus.outdated => '可升级',
      UpgradeStatus.majorBlocked => '跨 major',
      UpgradeStatus.sdkBlocked => 'SDK 不兼容',
      UpgradeStatus.skipped => '跳过',
    };
  }

  static int _width(Iterable<String> values) {
    var max = 0;
    for (final value in values) {
      if (value.length > max) max = value.length;
    }
    return max;
  }
}
