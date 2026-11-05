import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _Plugin extends WAppPlugin {
  @override
  String get name => 'test';
}

class _DepPlugin extends _Plugin {
  @override
  String get name => 'service';
  @override
  List<String> get dependsOn => const ['env'];
}

class _WrappedPlugin extends _Plugin {
  @override
  String get name => 'wrapped';
  @override
  Widget wrapApp(Widget child) => ColoredBox(color: const Color(0xFF000000), child: child);
  @override
  TransitionBuilder? get builderWrapper =>
      (context, child) => child ?? const SizedBox.shrink();
}

void main() {
  test('WAppPlugin 默认钩子无副作用', () async {
    final plugin = _Plugin();
    expect(plugin.dependsOn, isEmpty);
    expect(plugin.navigatorObservers, isNull);
    await plugin.onInit();
    expect(plugin.wrapApp(const SizedBox.shrink()), isA<SizedBox>());
  });

  test('dependsOn 默认为空，可覆写顺序', () {
    expect(_Plugin().dependsOn, isEmpty);
    expect(_DepPlugin().dependsOn, const ['env']);
  });

  test('wrapApp / builderWrapper 保留 child', () {
    const child = SizedBox(key: ValueKey('child'));
    final plugin = _WrappedPlugin();
    expect(plugin.wrapApp(child), isA<ColoredBox>());
    expect(
      plugin.builderWrapper!(_FakeContext(), child),
      same(child),
    );
  });

  test('navigatorObservers 默认为 null', () {
    expect(_Plugin().navigatorObservers, isNull);
  });
}

class _FakeContext extends Fake implements BuildContext {}
