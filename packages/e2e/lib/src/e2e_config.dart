import 'package:flutter/foundation.dart';

/// 自动登录被跳过的原因；`null` 表示条件满足。
///
/// `E2eLogin.run` 会把它打成一行 `[E2E] skip: <name>`，排查时不用再
/// 逐个核对 `--dart-define`。
enum E2eSkipReason {
  /// release 构建永远不生效（`E2E_PROFILE` 也放不开）。
  releaseBuild,

  /// 没有 `--dart-define=E2E=1`（或 `true`）。
  flagOff,

  /// profile 构建没有 `--dart-define=E2E_PROFILE=1`。
  profileNotAllowed,

  /// 缺 `E2E_EMAIL`。
  missingEmail,

  /// 缺 `E2E_PASSWORD`。
  missingPassword,

  /// 手工构造的 `E2eConfig(enabled: false)`，没有更具体的原因。
  disabled,
}

/// E2E 免登录配置。
///
/// 默认值来自编译期 `--dart-define`：
/// - `E2E=1`（或 `true`）
/// - `E2E_EMAIL` / `E2E_PASSWORD`
/// - `E2E_PROFILE=1`：profile 构建显式放行（默认只允许 debug）
///
/// 注意 `bool.fromEnvironment` 只认 `"true"`，`E2E=1` 会得到 false —— 这里按字符串读。
@immutable
class E2eConfig {
  const E2eConfig({
    required this.enabled,
    required this.email,
    required this.password,
    this.timeout = const Duration(seconds: 60),
    this.disabledReason,
  }) : assert(
          disabledReason == null || !enabled,
          'disabledReason 只在 enabled: false 时有意义',
        );

  factory E2eConfig.fromEnvironment() {
    const flag = String.fromEnvironment('E2E');
    const profileFlag = String.fromEnvironment('E2E_PROFILE');
    final envEnabled = flag == '1' || flag.toLowerCase() == 'true';
    final profileEnabled = profileFlag == '1' || profileFlag.toLowerCase() == 'true';
    // 默认 debug；profile 必须显式 E2E_PROFILE=1，避免 profile 分发包自动登录。
    final modeAllowed = kDebugMode || (kProfileMode && profileEnabled);
    // 原因按「用户最需要先处理的那条」排序：release 是硬规则，其次开关，再是 mode。
    final E2eSkipReason? reason = kReleaseMode
        ? E2eSkipReason.releaseBuild
        : !envEnabled
            ? E2eSkipReason.flagOff
            : !modeAllowed
                ? E2eSkipReason.profileNotAllowed
                : null;
    return E2eConfig(
      enabled: reason == null,
      email: const String.fromEnvironment('E2E_EMAIL'),
      password: const String.fromEnvironment('E2E_PASSWORD'),
      disabledReason: reason,
    );
  }

  final bool enabled;
  final String email;
  final String password;
  final Duration timeout;

  /// 编译期 / 构建模式层面的跳过原因；`fromEnvironment` 会填入。
  ///
  /// 手工构造 `enabled: false` 的 config 可以不传，此时 [skipReason] 为
  /// [E2eSkipReason.disabled]。
  final E2eSkipReason? disabledReason;

  /// 为什么不能自动登录；null 表示条件满足。
  ///
  /// 顺序：显式 [disabledReason] → 手工禁用 → 缺 email → 缺 password。
  E2eSkipReason? get skipReason {
    final reason = disabledReason;
    if (reason != null) return reason;
    if (!enabled) return E2eSkipReason.disabled;
    if (email.isEmpty) return E2eSkipReason.missingEmail;
    if (password.isEmpty) return E2eSkipReason.missingPassword;
    return null;
  }

  /// 是否具备自动登录条件。
  bool get canAutoLogin => skipReason == null;

  E2eConfig copyWith({Duration? timeout}) => E2eConfig(
        enabled: enabled,
        email: email,
        password: password,
        timeout: timeout ?? this.timeout,
        disabledReason: disabledReason,
      );

  @override
  String toString() => 'E2eConfig(enabled: $enabled, skipReason: ${skipReason?.name ?? '-'}, '
      'email: ${email.isEmpty ? '-' : email}, password: ${password.isEmpty ? '-' : '***'})';
}
