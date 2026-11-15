import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

WLanguage _language({String initialLanguage = 'en_US'}) => WLanguage.fromConfig(
  WLocaleConfig(
    supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
    initialLanguage: initialLanguage,
  ),
);

void main() {
  testWidgets('WLanguageScope.of 读取当前语言并在切换后重建', (tester) async {
    final language = _language();
    var builds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WLanguageScope(
          language: language,
          child: Builder(
            builder: (context) {
              builds++;
              return Text(WLanguageScope.of(context).currentLanguage);
            },
          ),
        ),
      ),
    );

    expect(find.text('en_US'), findsOneWidget);
    expect(builds, 1);

    language.changeLanguage('zh_CN');
    await tester.pump();

    expect(find.text('zh_CN'), findsOneWidget);
    expect(builds, 2);
  });

  testWidgets('嵌套时取最近的 WLanguageScope', (tester) async {
    final outer = _language();
    final inner = _language(initialLanguage: 'zh_CN');
    late WLanguage seen;

    await tester.pumpWidget(
      WLanguageScope(
        language: outer,
        child: WLanguageScope(
          language: inner,
          child: Builder(
            builder: (context) {
              seen = WLanguageScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(seen, same(inner));
  });

  testWidgets('没有 scope 时 maybeOf 返回 null、of 抛 FlutterError', (tester) async {
    late BuildContext context;

    await tester.pumpWidget(
      Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(WLanguageScope.maybeOf(context), isNull);
    expect(() => WLanguageScope.of(context), throwsFlutterError);
  });
}
