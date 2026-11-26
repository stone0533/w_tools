// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  const supported = <String, String>{
    'en_US': 'English',
    'zh_CN': '简体中文',
    'zh_Hant_TW': '繁體中文',
  };

  WLanguage languageFrom({
    String? initialLanguage,
    String? fallbackLanguage,
  }) => WLanguage.fromConfig(
    WLocaleConfig(
      supportedLanguages: supported,
      initialLanguage: initialLanguage,
      fallbackLanguage: fallbackLanguage,
    ),
  );

  test('不同实例的语言状态互不影响', () {
    final a = languageFrom();
    final b = languageFrom();

    expect(a.changeLanguage('zh_CN'), isTrue);
    expect(a.currentLanguage, 'zh_CN');
    expect(b.currentLanguage, 'en_US');
  });

  test('fromConfig 使用 initialLanguage 作为启动语言', () {
    final language = languageFrom(initialLanguage: 'zh_CN');

    expect(language.currentLanguage, 'zh_CN');
    expect(language.currentLanguageName, '简体中文');
  });

  test('fromConfig(null) 使用默认语言且不算显式选择', () {
    final language = WLanguage.fromConfig(null);

    expect(language.currentLanguage, 'en_US');
    expect(language.hasExplicitSelection, isFalse);
  });

  test('传入 WLocaleConfig 视为显式选择', () {
    expect(languageFrom().hasExplicitSelection, isTrue);
  });

  test('changeLanguage 拒绝未支持语言并返回 false', () {
    final language = languageFrom();
    final before = language.currentLanguage;

    expect(language.changeLanguage('fr_FR'), isFalse);
    expect(language.currentLanguage, before);
  });

  test('languageChanges 只通知真实变化', () async {
    final language = languageFrom();
    final changes = <String>[];
    final subscription = language.languageChanges.listen(changes.add);
    addTearDown(subscription.cancel);

    expect(language.changeLanguage('en_US'), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(changes, isEmpty);

    expect(language.changeLanguage('zh_CN'), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(changes, ['zh_CN']);
  });

  test('languageListenable 是只读 ValueListenable', () {
    final language = languageFrom();
    expect(language.languageListenable, isA<ValueListenable<String>>());
    expect(language.languageListenable.value, 'en_US');
  });

  test('currentLocale 支持语言码、地区码与脚本码', () {
    expect(
      WLanguage.fromConfig(
        WLocaleConfig(supportedLanguages: const {'en': 'English'}),
      ).currentLocale,
      const Locale('en'),
    );

    final language = languageFrom(initialLanguage: 'zh_Hant_TW');
    expect(language.currentLocale.languageCode, 'zh');
    expect(language.currentLocale.scriptCode, 'Hant');
    expect(language.currentLocale.countryCode, 'TW');
  });

  test('supportedLanguages 是只读视图', () {
    final language = languageFrom();
    expect(
      () => language.supportedLanguages['ja_JP'] = '日本語',
      throwsUnsupportedError,
    );
  });

  group('localeFromCode', () {
    test('接受 lang / lang_COUNTRY / lang_Script_COUNTRY', () {
      expect(WLanguage.localeFromCode('en'), const Locale('en'));
      expect(
        WLanguage.localeFromCode('zh_CN'),
        const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
      );
      expect(
        WLanguage.localeFromCode('zh-Hant-TW'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
    });

    test('拒绝猜测不了的语言码', () {
      for (final code in ['', 'e', 'en_US_POSIX', 'zh_CN_#Hans', 'zh_hant_TW']) {
        expect(
          () => WLanguage.localeFromCode(code),
          throwsArgumentError,
          reason: code,
        );
      }
    });
  });

  test('followSystem：启动不算显式选择，isFollowingSystem 为 true', () {
    final language = WLanguage.fromConfig(
      WLocaleConfig(supportedLanguages: supported, followSystem: true),
    );

    expect(language.isFollowingSystem, isTrue);
    expect(language.hasExplicitSelection, isFalse);
    expect(language.currentLanguage, 'en_US');
  });

  test('userSelected: false 写系统语言，不结束跟随', () {
    final language = WLanguage.fromConfig(
      WLocaleConfig(supportedLanguages: supported, followSystem: true),
    );

    expect(language.changeLanguage('zh_CN', userSelected: false), isTrue);
    expect(language.currentLanguage, 'zh_CN');
    expect(language.isFollowingSystem, isTrue);
    expect(language.hasExplicitSelection, isFalse);
  });

  test('用户显式切语言后不再跟随系统', () {
    final language = WLanguage.fromConfig(
      WLocaleConfig(supportedLanguages: supported, followSystem: true),
    );

    expect(language.changeLanguage('zh_CN'), isTrue);
    expect(language.isFollowingSystem, isFalse);
    expect(language.hasExplicitSelection, isTrue);
  });

  test('dispose 幂等，之后 changeLanguage 抛 StateError', () {
    final language = languageFrom();
    language.dispose();
    language.dispose();

    expect(() => language.changeLanguage('zh_CN'), throwsStateError);
  });
}
