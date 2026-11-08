import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

GetPage<dynamic> _page(String name) => GetPage(name: name, page: () => const SizedBox.shrink());

void main() {
  group('WAppOptions 校验', () {
    test('必须提供 home 或 initialRoute + getPages', () {
      expect(() => WAppOptions(title: 'Demo'), throwsArgumentError);
      expect(
        () => WAppOptions(title: 'Demo', initialRoute: '/'),
        throwsArgumentError,
      );
      expect(
        () => WAppOptions(title: 'Demo', getPages: [_page('/')]),
        throwsArgumentError,
      );
    });

    test('home 存在时可以不传 initialRoute / getPages', () {
      final options = WAppOptions(
        title: 'Demo',
        home: const SizedBox.shrink(),
      );
      expect(options.home, isNotNull);
      expect(options.getPages, isNull);
    });

    test('title 不能为空', () {
      expect(
        () => WAppOptions(title: '', home: const SizedBox.shrink()),
        throwsArgumentError,
      );
    });

    test('getPages 不能是空列表', () {
      expect(
        () => WAppOptions(title: 'Demo', initialRoute: '/', getPages: const []),
        throwsArgumentError,
      );
    });
  });

  group('WAppOptions 不可变与比较', () {
    test('入参 list / map 被拷贝，外部修改不影响实例', () {
      final pages = <GetPage<dynamic>>[_page('/')];
      final observers = <NavigatorObserver>[];
      final plugins = <WAppPlugin>[];
      final options = WAppOptions(
        title: 'Demo',
        home: const SizedBox.shrink(),
        getPages: pages,
        navigatorObservers: observers,
        plugins: plugins,
      );

      pages.add(_page('/next'));
      observers.add(_NoopObserver());
      plugins.add(_NoopPlugin());

      expect(options.getPages, hasLength(1));
      expect(options.navigatorObservers, isEmpty);
      expect(options.plugins, isEmpty);
    });

    test('相同配置 == / hashCode 一致', () {
      const home = SizedBox.shrink();
      final a = WAppOptions(title: 'Demo', home: home);
      final b = WAppOptions(title: 'Demo', home: home);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith 可清空可空字段并保留其它字段', () {
      final base = WAppOptions(
        title: 'Demo',
        home: const SizedBox.shrink(),
        theme: WAppTheme(light: ThemeData.light()),
        navigatorObservers: const [],
      );

      final pages = [_page('/')];
      final copy = base.copyWith(
        title: 'Next',
        home: null,
        initialRoute: '/',
        getPages: pages,
      );

      expect(copy.title, 'Next');
      expect(copy.home, isNull);
      expect(copy.initialRoute, '/');
      expect(copy.getPages, hasLength(1));
      expect(copy.theme, same(base.theme));
    });

    test('shouldApplyOrientations 默认 false，theme 默认不干预', () {
      final options = WAppOptions(
        title: 'Demo',
        home: const SizedBox.shrink(),
      );
      expect(options.shouldApplyOrientations, isFalse);
      expect(options.theme, isNull);
    });

    test('WAppOptions.theme 接受 WAppTheme，copyWith 可清空', () {
      final appTheme = WAppTheme(light: ThemeData.light());
      final options = WAppOptions(
        title: 'Demo',
        home: const SizedBox.shrink(),
        theme: appTheme,
      );

      expect(options.theme, same(appTheme));
      expect(options.copyWith(theme: null).theme, isNull);
    });
  });
}

class _NoopPlugin extends WAppPlugin {
  @override
  String get name => 'noop';
}

class _NoopObserver extends NavigatorObserver {}
