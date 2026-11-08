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

  test('不同实例的语言状态互不影响', () {
    final a = WLanguage(supportedLanguages: supported);
    final b = WLanguage(supportedLanguages: supported);

    expect(a.changeLanguage('zh_CN'), isTrue);
    expect(a.currentLanguage, 'zh_CN');
    expect(b.currentLanguage, 'en_US');
  });

  test('fromConfig 使用 initialLanguage 作为启动语言', () {
    final language = WLanguage.fromConfig(
      WLocaleConfig(supportedLanguages: supported, initialLanguage: 'zh_CN'),
    );

    expect(language.currentLanguage, 'zh_CN');
    expect(language.currentLanguageName, '简体中文');
  });

  test('fallbackLanguage 在当前语言不受支持时生效', () {
    final language = WLanguage(
      supportedLanguages: const {'en_US': 'English'},
      currentLanguage: 'fr_FR',
      fallbackLanguage: 'en_US',
    );

    expect(language.currentLanguage, 'en_US');
  });

  test('changeLanguage 拒绝未支持语言并返回 false', () {
    final language = WLanguage(supportedLanguages: supported);
    final before = language.currentLanguage;

    expect(language.changeLanguage('fr_FR'), isFalse);
    expect(language.currentLanguage, before);
  });

  test('languageChanges 只通知真实变化', () async {
    final language = WLanguage(supportedLanguages: supported);
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
    final language = WLanguage(supportedLanguages: supported);
    expect(language.languageListenable, isA<ValueListenable<String>>());
    expect(language.languageListenable.value, 'en_US');
  });

  test('listenLanguageChange 返回可取消订阅', () async {
    final language = WLanguage(supportedLanguages: supported);
    final changes = <String>[];
    final subscription = language.listenLanguageChange(changes.add);

    language.changeLanguage('zh_CN');
    await Future<void>.delayed(Duration.zero);
    expect(changes, ['zh_CN']);

    await subscription.cancel();
    language.changeLanguage('en_US');
    await Future<void>.delayed(Duration.zero);
    expect(changes, ['zh_CN']);
  });

  test('bindLocaleUpdater 接收 Locale 回调', () {
    final language = WLanguage(supportedLanguages: supported);
    Locale? applied;
    language.bindLocaleUpdater((locale) => applied = locale);

    language.changeLanguage('zh_CN');
    expect(applied?.languageCode, 'zh');
    expect(applied?.countryCode, 'CN');
  });

  test('currentLanguageName 未收录时回退为语言码', () {
    final language = WLanguage(
      supportedLanguages: const {},
      currentLanguage: 'fr_FR',
    );
    expect(language.currentLanguageName, 'fr_FR');
  });

  test('currentLocale 支持语言码、地区码与脚本码', () {
    expect(
      WLanguage(supportedLanguages: const {'en': 'English'}).currentLocale,
      const Locale('en'),
    );
    final language = WLanguage(
      supportedLanguages: const {'zh_Hant_TW': '繁體中文'},
      currentLanguage: 'zh_Hant_TW',
    );
    expect(language.currentLocale.languageCode, 'zh');
    expect(language.currentLocale.scriptCode, 'Hant');
    expect(language.currentLocale.countryCode, 'TW');
  });

  test('supportedLanguages 是只读视图', () {
    final language = WLanguage(supportedLanguages: supported);
    expect(
      () => language.supportedLanguages['ja_JP'] = '日本語',
      throwsUnsupportedError,
    );
  });
}
