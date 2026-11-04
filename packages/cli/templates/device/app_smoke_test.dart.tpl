// 复制到新项目的 integration_test/app_keepalive_smoke_test.dart。
// 依赖：dev_dependencies 加 `integration_test`（SDK）；项目需启用 w_tools_ui；
//       运行时代码依赖 w_tools_ui（WKeepAliveWrapper）。
//
// 只验证「组件机制在真实引擎上成立」，不依赖项目业务：
//   1. WKeepAliveWrapper：切走再回来，State 与滚动位置保留
//   2. 不可见页的 TickerMode 关闭（生产里由项目的 WPageActivity 负责，这里内联等价实现）
//
// 刷新 TTL 属于业务策略（TabRefreshMixin 的触发入口是私有 Worker），
// 放在项目自己的 test/ 里用 NavController 驱动验证。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tab keep-alive + inactive ticker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Harness()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('inc')));
    await tester.pump();
    expect(find.text('count=1'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('list')), const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 300));
    final offsetBefore = _HarnessState.scrollOffset(0);
    expect(offsetBefore, greaterThan(0));
    expect(_HarnessState.tickerEnabled(0), isTrue);

    _HarnessState.switchTo(1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_HarnessState.tickerEnabled(0), isFalse,
        reason: 'inactive tab must stop ticker');

    _HarnessState.switchTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('count=1'), findsOneWidget, reason: 'keep-alive keeps State');
    expect(_HarnessState.scrollOffset(0), closeTo(offsetBefore, 1.0));
  });
}

/// 复刻生产里的三层包装：PageView + 可见性（TickerMode）+ WKeepAliveWrapper。
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with TickerProviderStateMixin {
  static _HarnessState? _current;
  static void switchTo(int i) => _current?._switch(i);
  static double scrollOffset(int i) => _current?._scrolls[i]?.offset ?? 0;
  static bool tickerEnabled(int i) {
    final ctx = _current?._keys[i]?.currentContext;
    return ctx != null && TickerMode.valuesOf(ctx).enabled;
  }

  int _index = 0;
  late final PageController _pages = PageController();
  final _scrolls = <int, ScrollController>{};
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    _pages.dispose();
    for (final c in _scrolls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _switch(int i) {
    setState(() => _index = i);
    _pages.jumpToPage(i);
  }

  Widget _tab(int i, Widget child) => TickerMode(
        enabled: _index == i,
        child: WKeepAliveWrapper(child: child),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: PageView(
            controller: _pages,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 2; i++)
                _tab(
                  i,
                  _CounterPage(
                    key: (_keys[i] ??= GlobalKey()),
                    index: i,
                    scroll: (_scrolls[i] ??= ScrollController()),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _CounterPage extends StatefulWidget {
  const _CounterPage({super.key, required this.index, required this.scroll});
  final int index;
  final ScrollController scroll;
  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Column(
        key: ValueKey('page-${widget.index}'),
        children: [
          TextButton(
            key: const ValueKey('inc'),
            onPressed: () => setState(() => _count++),
            child: Text('count=$_count'),
          ),
          // 只播一次的动画：无限动画会让 pumpAndSettle 卡死
          const SizedBox(height: 24, child: _OnceAnimation()),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('list'),
              controller: widget.scroll,
              itemCount: 40,
              itemBuilder: (_, i) => SizedBox(height: 60, child: Text('item $i')),
            ),
          ),
        ],
      );
}

class _OnceAnimation extends StatefulWidget {
  const _OnceAnimation();
  @override
  State<_OnceAnimation> createState() => _OnceAnimationState();
}

class _OnceAnimationState extends State<_OnceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: const Icon(Icons.refresh, size: 16));
}
