import 'package:flutter/foundation.dart';

/// E2E 免登录配置。
///
/// 默认值来自编译期 `--dart-define`：
/// - `E2E=1`（或 `true`）
/// - `E2E_EMAIL` / `E2E_PASSWORD`
///
/// 注意 `bool.fromEnvironment` 只认 `"true"`，`E2E=1` 会得到 false —— 这里按字符串读。
@immutable
class E2eConfig {
  const E2eConfig({
    required this.enabled,
    required this.email,
    required this.password,
    this.timeout = const Duration(seconds: 60),
  });

  factory E2eConfig.fromEnvironment() {
    const flag = String.fromEnvironment('E2E');
    return E2eConfig(
      enabled: (flag == '1' || flag.toLowerCase() == 'true') && !kReleaseMode,
      email: const String.fromEnvironment('E2E_EMAIL'),
      password: const String.fromEnvironment('E2E_PASSWORD'),
    );
  }

  final bool enabled;
  final String email;
  final String password;
  final Duration timeout;

  /// 是否具备自动登录条件。
  bool get canAutoLogin => enabled && email.isNotEmpty && password.isNotEmpty;

  E2eConfig copyWith({Duration? timeout}) => E2eConfig(
        enabled: enabled,
        email: email,
        password: password,
        timeout: timeout ?? this.timeout,
      );

  @override
  String toString() =>
      'E2eConfig(enabled: $enabled, email: ${email.isEmpty ? '-' : email}, password: ${password.isEmpty ? '-' : '***'})';
}
