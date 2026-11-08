import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'locale_config.dart';

/// 一个应用语言实例。
///
/// 每个应用壳持有自己的实例；当前语言只有一个可写入口 [changeLanguage]。
/// 本类不依赖 GetX；应用壳通过 [bindLocaleUpdater] 注入自己的 locale 刷新逻辑。
class WLanguage {
  WLanguage({
    Map<String, String> supportedLanguages = const {'en_US': 'English'},
    String currentLanguage = 'en_US',
    String? initialLanguage,
    String? fallbackLanguage,
    bool explicitSelection = false,
  }) : _supportedLanguages = Map<String, String>.unmodifiable(
         Map<String, String>.from(supportedLanguages),
       ) {
    final initial = initialLanguage;
    if (initial != null && !_supportedLanguages.containsKey(initial)) {
      throw ArgumentError.value(
        initial,
        'initialLanguage',
        '必须出现在 supportedLanguages 中',
      );
    }
    final fallback = fallbackLanguage;
    if (fallback != null && !_supportedLanguages.containsKey(fallback)) {
      throw ArgumentError.value(
        fallback,
        'fallbackLanguage',
        '必须出现在 supportedLanguages 中',
      );
    }

    _current = ValueNotifier<String>(
      _resolveInitial(currentLanguage, initial, fallback),
    );
    _explicit = explicitSelection || initial != null;
  }

  /// 从 [WLocaleConfig] 创建实例；配置存在即视为显式选择语言。
  factory WLanguage.fromConfig(WLocaleConfig? config) {
    if (config == null) return WLanguage();
    return WLanguage(
      supportedLanguages: config.supportedLanguages,
      currentLanguage: config.initialLanguage ?? config.supportedLanguages.keys.first,
      initialLanguage: config.initialLanguage,
      fallbackLanguage: config.fallbackLanguage,
      explicitSelection: true,
    );
  }

  final Map<String, String> _supportedLanguages;
  late final ValueNotifier<String> _current;
  final StreamController<String> _changes = StreamController<String>.broadcast();
  bool _explicit = false;
  void Function(Locale)? _onLocaleChanged;

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
    _onLocaleChanged?.call(currentLocale);
    return true;
  }

  /// 绑定应用壳的 locale 刷新逻辑（由 GetX 适配层注入）。
  void bindLocaleUpdater(void Function(Locale locale) updater) {
    _onLocaleChanged = updater;
  }

  /// 监听语言变化；返回可取消的订阅。
  StreamSubscription<String> listenLanguageChange(
    void Function(String) callback,
  ) {
    return _changes.stream.listen(callback);
  }

  /// 把语言码解析为 [Locale]，支持 `en` / `zh_CN` / `zh_Hant_TW`。
  static Locale localeFromCode(String languageCode) {
    final parts = languageCode.split(RegExp(r'[_-]'));
    if (parts.length >= 3) {
      return Locale.fromSubtags(
        languageCode: parts[0],
        scriptCode: parts[1],
        countryCode: parts[2],
      );
    }
    if (parts.length == 2) {
      return Locale.fromSubtags(
        languageCode: parts[0],
        countryCode: parts[1],
      );
    }
    return Locale.fromSubtags(languageCode: parts[0]);
  }

  String _resolveInitial(
    String currentLanguage,
    String? initialLanguage,
    String? fallbackLanguage,
  ) {
    if (initialLanguage != null) return initialLanguage;
    if (_supportedLanguages.containsKey(currentLanguage)) return currentLanguage;
    if (fallbackLanguage != null) return fallbackLanguage;
    if (_supportedLanguages.isNotEmpty) return _supportedLanguages.keys.first;
    return currentLanguage;
  }
}
