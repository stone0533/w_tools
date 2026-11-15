import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'locale_code.dart';
import 'locale_config.dart';

/// 一个应用语言实例。
///
/// 每个应用壳持有自己的实例；当前语言只有一个可写入口 [changeLanguage]。
/// 本类不依赖 GetX，也不持久化选择：需要恢复上次语言时，在 `start()` 之前调用
/// [changeLanguage] 即可。
class WLanguage {
  WLanguage._({
    required Map<String, String> supportedLanguages,
    required String initialLanguage,
    required bool explicitSelection,
  }) : _supportedLanguages = Map<String, String>.unmodifiable(supportedLanguages),
       _current = ValueNotifier<String>(initialLanguage),
       _explicit = explicitSelection;

  /// 从 [WLocaleConfig] 创建实例；配置存在即视为显式选择语言。
  ///
  /// 传 null 时使用默认语言 `en_US`，且不算显式选择。
  factory WLanguage.fromConfig(WLocaleConfig? config) {
    if (config == null) {
      return WLanguage._(
        supportedLanguages: const <String, String>{'en_US': 'English'},
        initialLanguage: 'en_US',
        explicitSelection: false,
      );
    }
    return WLanguage._(
      supportedLanguages: config.supportedLanguages,
      initialLanguage: config.initialLanguage ?? config.supportedLanguages.keys.first,
      explicitSelection: true,
    );
  }

  final Map<String, String> _supportedLanguages;
  final ValueNotifier<String> _current;
  final StreamController<String> _changes = StreamController<String>.broadcast();
  bool _explicit;

  /// 支持的语言（只读）。
  Map<String, String> get supportedLanguages => _supportedLanguages;

  /// 当前语言码。
  String get currentLanguage => _current.value;

  /// 当前语言的展示名；未收录时回退为语言码本身。
  String get currentLanguageName => _supportedLanguages[currentLanguage] ?? currentLanguage;

  /// 当前语言对应的 [Locale]。
  Locale get currentLocale => localeFromCode(currentLanguage);

  /// 是否已经由 `WLocaleConfig` / [changeLanguage] 显式选择过语言。
  bool get hasExplicitSelection => _explicit;

  /// 语言变化的只读通知。
  Stream<String> get languageChanges => _changes.stream;

  /// 语言变化的只读值监听（可用于 `ValueListenableBuilder`）。
  ValueListenable<String> get languageListenable => _current;

  /// 切换语言；未收录的语言返回 false 且不产生变化。
  bool changeLanguage(String languageCode) {
    if (!_supportedLanguages.containsKey(languageCode)) return false;
    _explicit = true;
    if (_current.value == languageCode) return true;

    _current.value = languageCode;
    _changes.add(languageCode);
    return true;
  }

  /// 把语言码解析为 [Locale]，支持 `en` / `zh_CN` / `zh_Hant_TW` 三种形态。
  ///
  /// 非法形态（例如 `en_US_POSIX`）抛 [ArgumentError]。
  static Locale localeFromCode(String languageCode) => parseLocaleCode(languageCode);
}
