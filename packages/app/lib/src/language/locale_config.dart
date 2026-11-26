import 'package:flutter/foundation.dart';

import 'locale_code.dart';

/// 应用支持的语言与启动/回退策略。
///
/// 只描述“支持哪些语言、启动用哪种、回退到哪种、是否跟随系统”，运行期当前语言由
/// `WLanguage` 实例维护；本类不持久化任何选择。
@immutable
class WLocaleConfig {
  factory WLocaleConfig({
    required Map<String, String> supportedLanguages,
    String? initialLanguage,
    String? fallbackLanguage,
    bool followSystem = false,
  }) {
    final config = WLocaleConfig._(
      Map<String, String>.unmodifiable(
        Map<String, String>.from(supportedLanguages),
      ),
      initialLanguage,
      fallbackLanguage,
      followSystem,
    );
    config._validate();
    return config;
  }

  const WLocaleConfig._(
    this.supportedLanguages,
    this.initialLanguage,
    this.fallbackLanguage,
    this.followSystem,
  );

  /// 支持的语言（语言码 → 展示名），不可变。
  ///
  /// 语言码只接受 `lang` / `lang_COUNTRY` / `lang_Script_COUNTRY` 三种形态。
  final Map<String, String> supportedLanguages;

  /// 启动时使用的语言；为 null 时使用 [supportedLanguages] 的第一个。
  ///
  /// 本类不持久化运行期选择；要恢复上次语言，在 `start()` 之前调用
  /// `app.language.changeLanguage(saved)`。
  final String? initialLanguage;

  /// 回退语言；同时作为 GetX 翻译缺失时的 `fallbackLocale`。
  ///
  /// 为 null 时不额外指定回退。
  final String? fallbackLanguage;

  /// 是否跟随系统语言（默认 false）。
  ///
  /// true 时启动语言与系统语言变化都由系统解析决定（命中 [supportedLanguages]，
  /// 不命中用 [fallbackLanguage] 或第一个语言）；用户显式调用
  /// `WLanguage.changeLanguage` 后不再跟随。
  ///
  /// 与 [initialLanguage] 互斥：同时给出会在构造时抛 [ArgumentError]。
  final bool followSystem;

  void _validate() {
    if (supportedLanguages.isEmpty) {
      throw ArgumentError.value(supportedLanguages, 'supportedLanguages', '不能为空');
    }
    for (final code in supportedLanguages.keys) {
      try {
        parseLocaleCode(code);
      } on ArgumentError {
        throw ArgumentError.value(
          code,
          'supportedLanguages',
          '语言码格式非法，只支持 lang / lang_COUNTRY / lang_Script_COUNTRY',
        );
      }
    }
    final initial = initialLanguage;
    if (initial != null && !supportedLanguages.containsKey(initial)) {
      throw ArgumentError.value(initial, 'initialLanguage', '必须出现在 supportedLanguages 中');
    }
    final fallback = fallbackLanguage;
    if (fallback != null && !supportedLanguages.containsKey(fallback)) {
      throw ArgumentError.value(fallback, 'fallbackLanguage', '必须出现在 supportedLanguages 中');
    }
    if (followSystem && initial != null) {
      throw ArgumentError.value(
        initial,
        'initialLanguage',
        'followSystem 为 true 时不能同时指定 initialLanguage',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WLocaleConfig &&
        mapEquals(other.supportedLanguages, supportedLanguages) &&
        other.initialLanguage == initialLanguage &&
        other.fallbackLanguage == fallbackLanguage &&
        other.followSystem == followSystem;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(
      supportedLanguages.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    initialLanguage,
    fallbackLanguage,
    followSystem,
  );
}
