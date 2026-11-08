import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Get.testMode = true;
  });

  const supported = <String, String>{
    'en_US': 'English',
    'zh_CN': '简体中文',
    'zh_Hant_TW': '繁體中文',
  };

  group('WLanguage 实例', () {
    test('不同实例的语言状态互不影响', () {
      final a = WLanguage(supportedLanguages: supported);
      final b = WLanguage(supportedLanguages: supported);

      expect(a.changeLanguage('zh_CN'), isTrue);
      expect(a.currentLanguage, 'zh_CN');
      expect(b.currentLanguage, 'en_US');
    });

    test('fromConfig 使用 initialLanguage 作为启动语言', () {
      final language = WLanguage.fromConfig(
        WLocaleConfig(
          supportedLanguages: supported,
          initialLanguage: 'zh_CN',
        ),
      );

      expect(language.currentLanguage, 'zh_CN');
      expect(language.currentLanguageName, '简体中文');
    });

    test('fromConfig 未给 initialLanguage 时使用第一个支持语言', () {
      final language = WLanguage.fromConfig(
        WLocaleConfig(supportedLanguages: supported),
      );

      expect(language.currentLanguage, 'en_US');
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

    test('changeLanguage 只通知真实变化', () async {
      final language = WLanguage(supportedLanguages: supported);
      final changes = <String>[];
      final subscription = language.languageChanges.listen(changes.add);
      addTearDown(subscription.cancel);

      expect(language.changeLanguage('en_US'), isTrue); // 没有变化
      await Future<void>.delayed(Duration.zero);
      expect(changes, isEmpty);

      expect(language.changeLanguage('zh_CN'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(changes, ['zh_CN']);
    });

    test('languageListenable 是只读的 ValueListenable', () {
      final language = WLanguage(supportedLanguages: supported);
      expect(language.languageListenable, isA<ValueListenable<String>>());
      expect(language.languageListenable.value, 'en_US');
    });

    test('currentLanguageName 在未收录时回退为语言码', () {
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
      expect(
        WLanguage(
          supportedLanguages: const {'zh_CN': '简体中文'},
        ).currentLocale,
        const Locale('zh', 'CN'),
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

    test('listenLanguageChange 返回可取消的订阅', () async {
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

    test('构造参数校验：initial / fallback 必须在支持列表内', () {
      expect(
        () => WLanguage.fromConfig(
          WLocaleConfig(
            supportedLanguages: const {'en_US': 'English'},
            initialLanguage: 'zh_CN',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => WLanguage(
          supportedLanguages: const {'en_US': 'English'},
          fallbackLanguage: 'zh_CN',
        ),
        throwsArgumentError,
      );
    });

    test('空支持列表保留显式 currentLanguage', () {
      final language = WLanguage(
        supportedLanguages: const {},
        currentLanguage: 'fr_FR',
      );

      expect(language.currentLanguage, 'fr_FR');
      expect(language.supportedLanguages, isEmpty);
    });
  });
}
