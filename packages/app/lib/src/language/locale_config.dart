import 'package:flutter/foundation.dart';

/// 应用支持的语言与启动/回退策略。
///
/// 只描述“支持哪些语言、首次启动用哪种、当前语言不受支持时回退到哪种”，
/// 运行期当前语言由 `WLanguage` 实例维护。
@immutable
class WLocaleConfig {
  factory WLocaleConfig({
    required Map<String, String> supportedLanguages,
    String? initialLanguage,
    String? fallbackLanguage,
  }) {
    final config = WLocaleConfig._(
      Map<String, String>.unmodifiable(
        Map<String, String>.from(supportedLanguages),
      ),
      initialLanguage,
      fallbackLanguage,
    );
    config._validate();
    return config;
  }

  const WLocaleConfig._(
    this.supportedLanguages,
    this.initialLanguage,
    this.fallbackLanguage,
  );

  /// 支持的语言（语言码 → 展示名），不可变。
  final Map<String, String> supportedLanguages;

  /// 首次启动使用的语言；为 null 时使用 [supportedLanguages] 的第一个。
  final String? initialLanguage;

  /// 当前语言不在 [supportedLanguages] 时的回退语言；为 null 时不回退。
  final String? fallbackLanguage;

  static const Object _unset = Object();

  WLocaleConfig copyWith({
    Map<String, String>? supportedLanguages,
    Object? initialLanguage = _unset,
    Object? fallbackLanguage = _unset,
  }) {
    return WLocaleConfig(
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      initialLanguage: identical(initialLanguage, _unset)
          ? this.initialLanguage
          : initialLanguage as String?,
      fallbackLanguage: identical(fallbackLanguage, _unset)
          ? this.fallbackLanguage
          : fallbackLanguage as String?,
    );
  }

  void _validate() {
    if (supportedLanguages.isEmpty) {
      throw ArgumentError.value(supportedLanguages, 'supportedLanguages', '不能为空');
    }
    final initial = initialLanguage;
    if (initial != null && !supportedLanguages.containsKey(initial)) {
      throw ArgumentError.value(initial, 'initialLanguage', '必须出现在 supportedLanguages 中');
    }
    final fallback = fallbackLanguage;
    if (fallback != null && !supportedLanguages.containsKey(fallback)) {
      throw ArgumentError.value(fallback, 'fallbackLanguage', '必须出现在 supportedLanguages 中');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WLocaleConfig &&
        mapEquals(other.supportedLanguages, supportedLanguages) &&
        other.initialLanguage == initialLanguage &&
        other.fallbackLanguage == fallbackLanguage;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(
      supportedLanguages.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    initialLanguage,
    fallbackLanguage,
  );
}
