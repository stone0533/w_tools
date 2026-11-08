import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// WNavBar / WNavController / WTabBar 的完整演示。
class NavDemoPage extends StatefulWidget {
  const NavDemoPage({super.key});

  @override
  State<NavDemoPage> createState() => _NavDemoPageState();
}

class _NavDemoPageState extends State<NavDemoPage> with TickerProviderStateMixin {
  late final WNavController _nav;
  bool _blockLast = false;
  int _tabTap = -1;
  String _lastTap = '-';

  static const _items = <(IconData, String)>[
    (Icons.home_outlined, '首页'),
    (Icons.search, '搜索'),
    (Icons.favorite_border, '收藏'),
    (Icons.person_outline, '我的'),
  ];

  @override
  void initState() {
    super.initState();
    _nav = WNavController(length: _items.length, vsync: this);
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  Widget _itemBuilder(BuildContext context, int index, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _items[index].$1,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        const SizedBox(height: 2),
        WText(
          text: _items[index].$2,
          variant: WTextVariant.caption,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WScaffold(
      title: 'WNavBar / WNavController / WTabBar',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: 'WNavController：animateTo / currentIndex / 状态',
            subtitle: 'onItemTap 返回 false 可阻止切换',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoBox(
                  height: 140,
                  child: WNavBar(
                    controller: _nav,
                    itemBuilder: _itemBuilder,
                    onItemTap: (index) async {
                      setState(() => _lastTap = '${_items[index].$2}（$index）');
                      if (_blockLast && index == _items.length - 1) {
                        return false;
                      }
                      return true;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    WButton(
                      label: 'animateTo(2)',
                      style: WButtonStyles.of(context).secondary,
                      onTap: () => _nav.animateTo(2),
                    ),
                    WButton(
                      label: 'currentIndex = 0',
                      style: WButtonStyles.of(context).secondary,
                      onTap: () => _nav.currentIndex = 0,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const WText(text: '阻止最后一个 tab', variant: WTextVariant.caption),
                    Switch(
                      value: _blockLast,
                      onChanged: (value) => setState(() => _blockLast = value),
                    ),
                  ],
                ),
                _KeyValue(label: '最后一次点击', value: _lastTap),
                ListenableBuilder(
                  listenable: _nav,
                  builder: (context, _) => Column(
                    children: [
                      _KeyValue(label: 'currentIndex', value: '${_nav.currentIndex}'),
                      _KeyValue(label: 'previousIndex', value: '${_nav.previousIndex}'),
                      _KeyValue(label: 'indexIsChanging', value: '${_nav.indexIsChanging}'),
                      _KeyValue(label: 'offset', value: _nav.offset.toStringAsFixed(2)),
                    ],
                  ),
                ),
                const CodeText(
                  'final nav = WNavController(length: 4, vsync: this);\n'
                  'nav.animateTo(2);\n'
                  'nav.currentIndex = 0;\n'
                  '// dispose 里 nav.dispose()',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WNavBarStyle：外层装饰 / padding',
            child: DemoBox(
              height: 100,
              child: WNavBar(
                controller: _nav,
                itemBuilder: _itemBuilder,
                style: WNavBarStyle(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          DemoSection(
            title: 'WTabBar：style / indicator / divider / scrollable',
            subtitle: 'WTabBar 不自带 controller，需要 DefaultTabController 或外部传入',
            child: DemoBox(
              height: 280,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    WTabBar(
                      style: const WTabBarStyle(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: Color(0xFF4F46E5),
                        indicatorWeight: 3,
                        dividerColor: Color(0x1F000000),
                        overlayColor: Color(0x1F4F46E5),
                      ),
                      tabs: const [
                        Tab(text: '全部'),
                        Tab(text: '进行中'),
                        Tab(text: '已完成'),
                      ],
                      onTap: (index) => setState(() => _tabTap = index),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TabPage(label: '全部', scheme: scheme),
                          _TabPage(label: '进行中', scheme: scheme),
                          _TabPage(label: '已完成', scheme: scheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DemoSection(
            title: 'WTabBarStyle.copyWith',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(label: 'onTap index', value: '$_tabTap'),
                const CodeText(
                  'const base = WTabBarStyle(isScrollable: true);\n'
                  'final style = base.copyWith(indicatorColor: Colors.indigo);',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: WText(text: '$label 内容', variant: WTextVariant.body),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: WText(text: label, variant: WTextVariant.caption)),
          WText(text: value, variant: WTextVariant.bodyStrong),
        ],
      ),
    );
  }
}
