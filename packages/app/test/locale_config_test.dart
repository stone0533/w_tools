// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  const supported = {'en_US': 'English', 'zh_CN': '简体中文'};

  test('入参 map 被拷贝，外部修改不影响实例', () {
    final map = <String, String>{'en_US': 'English'};
    final config = WLocaleConfig(supportedLanguages: map);
    map['zh_CN'] = '简体中文';

    expect(config.supportedLanguages.containsKey('zh_CN'), isFalse);
    expect(
      () => config.supportedLanguages['zh_CN'] = '简体中文',
      throwsUnsupportedError,
    );
  });

  test('initial / fallback 必须在支持列表内', () {
    expect(
      () => WLocaleConfig(supportedLanguages: supported, initialLanguage: 'fr_FR'),
      throwsArgumentError,
    );
    expect(
      () => WLocaleConfig(supportedLanguages: supported, fallbackLanguage: 'fr_FR'),
      throwsArgumentError,
    );
  });

  test('支持列表不能为空', () {
    expect(
      () => WLocaleConfig(supportedLanguages: const {}),
      throwsArgumentError,
    );
  });

  test('语言码只接受三种形态', () {
    for (final code in ['en', 'en_US', 'zh_Hant_TW', 'en-Latn-US']) {
      expect(
        () => WLocaleConfig(supportedLanguages: {code: code}),
        returnsNormally,
        reason: code,
      );
    }
    for (final code in ['', 'e', 'en_US_POSIX', 'zh_CN_#Hans', 'zh_hant_TW']) {
      expect(
        () => WLocaleConfig(supportedLanguages: {code: code}),
        throwsArgumentError,
        reason: code,
      );
    }
  });

  test('相同内容 == / hashCode 一致', () {
    final a = WLocaleConfig(supportedLanguages: supported);
    final b = WLocaleConfig(supportedLanguages: supported);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('followSystem 与 initialLanguage 互斥', () {
    expect(
      () => WLocaleConfig(
        supportedLanguages: supported,
        followSystem: true,
        initialLanguage: 'zh_CN',
      ),
      throwsArgumentError,
    );
  });

  test('followSystem 参与 == / hashCode', () {
    final a = WLocaleConfig(supportedLanguages: supported);
    final b = WLocaleConfig(supportedLanguages: supported, followSystem: true);

    expect(a, isNot(b));
    expect(a.hashCode, isNot(b.hashCode));
  });
}
