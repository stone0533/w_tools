import 'dart:io';

/// `w_tools upgrade` 的纯逻辑：声明 + lock + 最新版本 → 升级计划。
///
/// 这里不读文件、不发网络请求：命令层把 [ProjectPubspec] 的结果和
/// [LatestRelease] 喂进来，测试可以直接穷举各种边界（0.x、跨 major、SDK 不兼容）。

/// 语义化版本；只用于比较和 caret 上界，不追求完整的 semver（预发布按同版本处理）。
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)');

  /// 解析 `1.2.3` / `1.2.3-dev.1+build`；`Platform.version` 这种带后缀的取第一个 token。
  static SemVer? tryParse(String raw) {
    final token = raw.trim().split(RegExp(r'\s+')).first;
    final match = _pattern.firstMatch(token);
    if (match == null) return null;
    return SemVer(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static SemVer? parsePrefix(String raw) => tryParse(raw);

  /// `^a.b.c` 的上界（不含）：`8.1.2 -> 9.0.0`、`0.13.1 -> 0.14.0`、`0.0.3 -> 0.0.4`。
  SemVer caretUpperBound() {
    if (major > 0) return SemVer(major + 1, 0, 0);
    if (minor > 0) return SemVer(0, minor + 1, 0);
    return SemVer(0, 0, patch + 1);
  }

  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator <(SemVer other) => compareTo(other) < 0;

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      other is SemVer && other.major == major && other.minor == minor && other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

/// hosted 源上的一个发布版本。
class LatestRelease {
  const LatestRelease({
    required this.version,
    this.sdkConstraint,
    this.flutterConstraint,
    this.published,
  });

  final String version;
  final String? sdkConstraint;
  final String? flutterConstraint;
  final String? published;
}

enum UpgradeStatus {
  /// 声明下界已经是最新。
  upToDate,

  /// 可以抬到最新（同 caret 窗口，或显式允许跨 major）。
  outdated,

  /// 最新版本在 caret 窗口外；默认只报告，`--major` 才写。
  majorBlocked,

  /// 最新版本要求的 Dart 版本本机不满足。
  sdkBlocked,

  /// 不参与本次升级（path / git / override / 非 caret 约束 …）。
  skipped,
}

class PackageUpgrade {
  const PackageUpgrade({
    required this.name,
    required this.dev,
    required this.declared,
    required this.locked,
    required this.latest,
    required this.status,
    this.target,
    this.reason,
    this.lockBehind = false,
  });

  final String name;
  final bool dev;

  /// pubspec 里的原始约束（`^8.0.1`）；path / git 依赖为 null。
  final String? declared;
  final String? locked;
  final LatestRelease? latest;
  final UpgradeStatus status;

  /// 要写入的新约束（`^8.1.0`）；仅 [UpgradeStatus.outdated] 有值。
  final String? target;

  /// 跳过 / 阻塞原因（给人和 AI 看的一句话）。
  final String? reason;

  /// lock 里的版本低于最新（下界已最新时说明 `pub get` 没跑）。
  final bool lockBehind;

  bool get needsWrite => status == UpgradeStatus.outdated && target != null;

  bool get risky => status == UpgradeStatus.majorBlocked || status == UpgradeStatus.sdkBlocked;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'dev': dev,
    'declared': declared,
    'locked': locked,
    'latest': latest?.version,
    'status': status.name,
    if (target != null) 'target': target,
    if (reason != null) 'reason': reason,
    'lockBehind': lockBehind,
    if (latest?.sdkConstraint != null) 'sdk': latest!.sdkConstraint,
    if (latest?.flutterConstraint != null) 'flutter': latest!.flutterConstraint,
  };
}

class UpgradePlan {
  const UpgradePlan({required this.hosted, required this.packages});

  final String hosted;
  final List<PackageUpgrade> packages;

  Iterable<PackageUpgrade> get writable => packages.where((p) => p.needsWrite);

  int count(UpgradeStatus status) => packages.where((p) => p.status == status).length;

  /// `--check` 的判定：可升的没升，或者 lock 落后于最新。
  bool get hasFindings => packages.any((p) => p.needsWrite || p.lockBehind);

  /// 跨 major / SDK 不兼容；`--strict` 时也算落后。
  bool get hasRisks => packages.any((p) => p.risky);
}

/// `w_tools` / `w_tools_*` 才是本命令的处理对象；其它依赖（含刻意钉死的）一律不碰。
bool isWToolsDependency(String name) => name == 'w_tools' || name.startsWith('w_tools_');

/// 只接受 `^a.b.c`：精确钉死 (`1.2.3`)、`>=` 范围、`any` 都留给人工处理。
SemVer? parseCaretConstraint(String raw) {
  final text = raw.trim();
  if (!text.startsWith('^')) return null;
  return SemVer.tryParse(text.substring(1));
}

/// 判断 `current` 是否满足 `sdk: ^3.10.0` / `>=3.9.0 <4.0.0` 这类约束。
///
/// 只实现 hosted 上 `environment.sdk` 实际会出现的写法；解析不了返回 null（= 不知道，不拦）。
bool? satisfiesConstraint(String? constraint, SemVer? current) {
  if (constraint == null || current == null) return null;
  final tokens = constraint.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  var seen = false;
  for (final token in tokens) {
    final ok = _satisfiesToken(token, current);
    if (ok == null) return null;
    if (!ok) return false;
    seen = true;
  }
  return seen ? true : null;
}

bool? _satisfiesToken(String token, SemVer current) {
  if (token.startsWith('^')) {
    final floor = SemVer.tryParse(token.substring(1));
    if (floor == null) return null;
    return !(current < floor) && current < floor.caretUpperBound();
  }
  for (final prefix in <String>['>=', '<=', '>', '<']) {
    if (!token.startsWith(prefix)) continue;
    final bound = SemVer.tryParse(token.substring(prefix.length));
    if (bound == null) return null;
    return switch (prefix) {
      '>=' => !(current < bound),
      '<=' => !(current > bound),
      '>' => current > bound,
      _ => current < bound,
    };
  }
  final exact = SemVer.tryParse(token);
  if (exact == null) return null;
  return current == exact;
}

/// 生成计划。
///
/// [latest] 里缺失的包按「hosted 上找不到」处理；[only] 非空时只考虑这些包
/// （其余显式标成 skipped，输出里仍然可见，不会被静默忽略）。
UpgradePlan buildPlan({
  required String hosted,
  required Map<String, Object?> dependencies,
  required Map<String, Object?> devDependencies,
  required Map<String, String> locked,
  required Map<String, LatestRelease?> latest,
  required Set<String> overrides,
  required bool allowMajor,
  required Set<String> only,
  String? dartVersion,
}) {
  final currentDart = SemVer.parsePrefix(dartVersion ?? Platform.version);
  final names = <String>{
    ...dependencies.keys,
    ...devDependencies.keys,
  }.where(isWToolsDependency).toList()..sort();

  final packages = <PackageUpgrade>[
    for (final name in names)
      _planOne(
        name: name,
        dev: !dependencies.containsKey(name),
        raw: dependencies[name] ?? devDependencies[name],
        locked: locked[name],
        latest: latest[name],
        overridden: overrides.contains(name),
        allowMajor: allowMajor,
        included: only.isEmpty || only.contains(name),
        currentDart: currentDart,
      ),
  ];
  return UpgradePlan(hosted: hosted, packages: packages);
}

PackageUpgrade _planOne({
  required String name,
  required bool dev,
  required Object? raw,
  required String? locked,
  required LatestRelease? latest,
  required bool overridden,
  required bool allowMajor,
  required bool included,
  required SemVer? currentDart,
}) {
  PackageUpgrade skip(String reason) => PackageUpgrade(
    name: name,
    dev: dev,
    declared: raw is String ? raw : null,
    locked: locked,
    latest: latest,
    status: UpgradeStatus.skipped,
    reason: reason,
  );

  final latestVersion = latest == null ? null : SemVer.tryParse(latest.version);
  final lockedVersion = locked == null ? null : SemVer.tryParse(locked);
  final lockBehind =
      latestVersion != null && lockedVersion != null && lockedVersion < latestVersion;

  PackageUpgrade rest(UpgradeStatus status, {String? target, String? reason}) => PackageUpgrade(
    name: name,
    dev: dev,
    declared: raw is String ? raw : null,
    locked: locked,
    latest: latest,
    status: status,
    target: target,
    reason: reason,
    lockBehind: lockBehind,
  );

  if (overridden) return skip('dependency_overrides 里已覆盖，抬 pub 版本不会生效');
  if (!included) return skip('不在 --only 范围内');
  if (raw is! String) {
    return skip(raw == null ? '依赖形式无法解析' : 'path / git 依赖，不抬 pub 版本');
  }
  final floor = parseCaretConstraint(raw);
  if (floor == null) return skip('非 caret 约束（$raw），请手工处理');
  if (latest == null) return skip('hosted 上找不到该包');
  if (latestVersion == null) return skip('最新版本号无法解析（${latest.version}）');

  if (!(latestVersion > floor)) return rest(UpgradeStatus.upToDate);

  final sdkOk = satisfiesConstraint(latest.sdkConstraint, currentDart);
  if (sdkOk == false) {
    return rest(
      UpgradeStatus.sdkBlocked,
      reason: '最新版要求 Dart ${latest.sdkConstraint}，本机 ${currentDart ?? '未知'}',
    );
  }

  final inCaretWindow = latestVersion < floor.caretUpperBound();
  if (!inCaretWindow && !allowMajor) {
    return rest(
      UpgradeStatus.majorBlocked,
      reason: '跨 major：$raw → ${latest.version}（确认后用 --major 或 --only=$name）',
    );
  }
  return rest(UpgradeStatus.outdated, target: '^${latest.version}');
}
