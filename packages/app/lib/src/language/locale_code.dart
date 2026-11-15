import 'dart:ui' show Locale;

/// 语言码只允许三种形态：`lang` / `lang_COUNTRY` / `lang_Script_COUNTRY`。
///
/// 分隔符 `_` 与 `-` 等价；语言 2~3 位字母，脚本 4 位首字母大写，地区 2 位大写
/// 字母或 3 位数字（UN M.49）。不认识的形态直接抛 `ArgumentError`，避免
/// `en_US_POSIX` 这类字符串被静默解释成脚本码。
final RegExp _languageCode = RegExp(r'^[A-Za-z]{2,3}$');
final RegExp _scriptCode = RegExp(r'^[A-Z][a-z]{3}$');
final RegExp _countryCode = RegExp(r'^(?:[A-Z]{2}|[0-9]{3})$');

/// 把语言码解析为 [Locale]；非法语言码抛 [ArgumentError]。
Locale parseLocaleCode(String code) {
  final parts = code.split(RegExp(r'[_-]'));
  if (parts.length == 1 && _languageCode.hasMatch(parts[0])) {
    return Locale.fromSubtags(languageCode: parts[0]);
  }
  if (parts.length == 2 && _languageCode.hasMatch(parts[0])) {
    if (_scriptCode.hasMatch(parts[1])) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    if (_countryCode.hasMatch(parts[1])) {
      return Locale.fromSubtags(languageCode: parts[0], countryCode: parts[1]);
    }
  }
  if (parts.length == 3 &&
      _languageCode.hasMatch(parts[0]) &&
      _scriptCode.hasMatch(parts[1]) &&
      _countryCode.hasMatch(parts[2])) {
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }
  throw ArgumentError.value(
    code,
    'languageCode',
    '只支持 lang / lang_COUNTRY / lang_Script_COUNTRY（例：en / en_US / zh_Hant_TW）',
  );
}
