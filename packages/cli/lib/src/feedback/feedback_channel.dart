import 'dart:io';

import 'package:path/path.dart' as p;

import '../context/install_info.dart';
import 'feedback_ledger.dart' as ledger;

/// 反馈落到哪里：本地台账（`docs/feedback/`）/ GitHub Issue / 关闭。
enum FeedbackMode {
  ledger,
  issue,
  disabled;

  /// 与 `feedback status --json` / 文档里的字符串一致。
  String get wire => name;
}

/// 解析后的反馈通道。
///
/// 路由只在这里实现一次，`submit` / `status` / `path` / `search` / `lint` 都复用它，
/// 避免「`path` 说能写台账、`submit` 却说跳过」这类自相矛盾。
///
/// 优先级：
/// 1. 项目根就是 w_tools 仓库 → 写该仓库的 `docs/feedback/`（维护者默认路径，不读开关）；
/// 2. 开启反馈（`feedback.enabled`）且本机解析到 w_tools 仓库检出（path / git 依赖）
///    → 仍然优先写那个仓库的台账，不公开发 Issue；
/// 3. 开启反馈但没有本地仓库 → GitHub Issue；
/// 4. 其余 → disabled：不写文件、不建 Issue。
class FeedbackChannel {
  const FeedbackChannel({
    required this.mode,
    this.repoRoot,
    this.enabled = false,
    this.isWtoolsRepo = false,
    this.ledgerOverride,
    this.ledgerOverrideInvalid,
  });

  final FeedbackMode mode;

  /// 本机可写的 w_tools 仓库根（台账在 `<repoRoot>/docs/feedback`）；`null` 表示没有。
  final String? repoRoot;

  /// 项目是否开启了反馈通道（`feedback.enabled`）。
  final bool enabled;

  /// 项目根是否就是 w_tools 仓库本身（维护者）。
  final bool isWtoolsRepo;

  /// `feedback.ledger` 解析后的有效路径；`null` 表示没配。
  final String? ledgerOverride;

  /// `feedback.ledger` 配了但不指向 w_tools 仓库时，这里是解析后的路径（提示用）。
  final String? ledgerOverrideInvalid;

  bool get hasLedger => repoRoot != null;

  /// 台账目录；`null` 表示本机没有可写台账。
  String? get ledgerDir => repoRoot == null ? null : p.join(repoRoot!, 'docs', 'feedback');

  Map<String, Object?> toJson() => <String, Object?>{
    'channel': mode.wire,
    'isWtoolsRepo': isWtoolsRepo,
    'feedbackEnabled': enabled,
    'ledger': ledgerDir,
    'ledgerOverride': ledgerOverride,
    if (ledgerOverrideInvalid != null) 'ledgerOverrideInvalid': ledgerOverrideInvalid,
  };

  /// [issueEnabled] 来自 `.w_tools_doctor.yaml`（默认 false）；[ledgerOverride] 是
  /// `feedback.ledger`（相对项目根或绝对路径）；[pubCache] 只给测试覆盖缓存路径。
  ///
  /// 仓库自身不看开关：`--ledger` 一直是维护者路径，保持不变。
  /// 显式 `feedback.ledger` 优先于依赖探测，也不受 pub cache 排除影响（是用户指名要的）。
  static FeedbackChannel resolve({
    required Directory projectRoot,
    required bool issueEnabled,
    String? ledgerOverride,
    String? pubCache,
  }) {
    final inRepo = ledger.isWtoolsRepo(projectRoot);
    String? overridePath;
    String? overrideInvalid;
    final rawOverride = ledgerOverride?.trim();
    if (rawOverride != null && rawOverride.isNotEmpty) {
      final resolved = p.normalize(
        p.isAbsolute(rawOverride) ? rawOverride : p.join(projectRoot.path, rawOverride),
      );
      if (ledger.isWtoolsRepo(Directory(resolved))) {
        overridePath = resolved;
      } else {
        overrideInvalid = resolved;
      }
    }

    if (inRepo) {
      return FeedbackChannel(
        mode: FeedbackMode.ledger,
        repoRoot: projectRoot.path,
        enabled: issueEnabled,
        isWtoolsRepo: true,
        ledgerOverride: overridePath,
        ledgerOverrideInvalid: overrideInvalid,
      );
    }

    final repo = overridePath ?? _autoRepo(projectRoot, pubCache: pubCache);
    if (issueEnabled && repo != null) {
      return FeedbackChannel(
        mode: FeedbackMode.ledger,
        repoRoot: repo,
        enabled: true,
        ledgerOverride: overridePath,
        ledgerOverrideInvalid: overrideInvalid,
      );
    }
    if (issueEnabled) {
      return FeedbackChannel(
        mode: FeedbackMode.issue,
        enabled: true,
        ledgerOverride: overridePath,
        ledgerOverrideInvalid: overrideInvalid,
      );
    }
    // 未开启：不自动写，但保留「本机有台账」这个事实，好让 --ledger / path 说真话。
    return FeedbackChannel(
      mode: FeedbackMode.disabled,
      repoRoot: repo,
      ledgerOverride: overridePath,
      ledgerOverrideInvalid: overrideInvalid,
    );
  }

  /// 依赖里解析到的本机 w_tools 检出；pub cache 里的 git 依赖不算。
  static String? _autoRepo(Directory projectRoot, {String? pubCache}) {
    final repo = InstallInfo.detect(projectRoot: projectRoot).repoRoot;
    if (repo == null) return null;
    if (!ledger.isWtoolsRepo(Directory(repo))) return null;
    // 写进缓存会脏缓存，`pub cache repair` 还会删掉。
    if (isPubCachePath(repo, cache: pubCache)) return null;
    return repo;
  }
}

/// 路径是否在 pub cache 里（`PUB_CACHE` 或 `~/.pub-cache`）。
///
/// git 依赖会把整个仓库克隆到 pub cache：它有 `docs/feedback/`，但不该被当成
/// 「本机 w_tools 库」来写 —— 缓存可能被清掉，写进去等于写丢。
bool isPubCachePath(String path, {String? cache}) {
  final root = cache ?? _defaultPubCache();
  if (root == null || root.isEmpty) return false;
  return p.isWithin(p.normalize(root), p.normalize(path));
}

String? _defaultPubCache() {
  final env = Platform.environment;
  final explicit = env['PUB_CACHE'];
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final home = env['HOME'] ?? env['USERPROFILE'];
  return home == null ? null : p.join(home, '.pub-cache');
}

/// `gh` 是否可用于建 Issue（安装 + 登录）。
class GhStatus {
  const GhStatus({required this.installed, required this.authenticated});

  final bool installed;
  final bool authenticated;

  bool get ready => installed && authenticated;

  Map<String, Object?> toJson() => <String, Object?>{
    'installed': installed,
    'authenticated': authenticated,
    'ready': ready,
  };

  /// 探测 `gh`；不抛异常，失败即视为不可用。
  static GhStatus probe() {
    if (!_exitOk(const <String>['--version'])) {
      return const GhStatus(installed: false, authenticated: false);
    }
    return GhStatus(installed: true, authenticated: _exitOk(const <String>['auth', 'status']));
  }

  static bool _exitOk(List<String> args) {
    try {
      return Process.runSync('gh', args).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}
