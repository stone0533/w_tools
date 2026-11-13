import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';
import 'lists_page_sections.dart';

/// WListView / WListViewSliver / 通知 / 保活的完整演示。
class ListsDemoPage extends StatefulWidget {
  const ListsDemoPage({super.key});

  @override
  State<ListsDemoPage> createState() => _ListsDemoPageState();
}

class _ListsDemoPageState extends State<ListsDemoPage> {
  bool _showEmpty = false;
  bool _keepAlive = false;
  bool _prevent = false;
  final ValueNotifier<int> _notifications = ValueNotifier<int>(0);
  final ValueNotifier<int> _bubbled = ValueNotifier<int>(0);
  final ValueNotifier<double?> _percent = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _notifications.dispose();
    _bubbled.dispose();
    _percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WScaffold.basic(
      title: 'WListView / 通知 / keepAlive',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: 'WListViewSliver.list：header / footer / empty',
            subtitle: '空态、页头、页尾都交给 sliver；外层只负责滚动',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const WText(text: '展示空态', variant: WTextVariant.caption),
                    Switch(
                      value: _showEmpty,
                      onChanged: (value) => setState(() => _showEmpty = value),
                    ),
                  ],
                ),
                DemoBox(
                  height: 260,
                  child: WListView(
                    sliver: WListViewSliver.list(
                      padding: const EdgeInsets.all(8),
                      itemCount: _showEmpty ? 0 : 6,
                      itemBuilder: (context, index) => SizedBox(
                        height: 44,
                        child: Center(
                          child: WText(
                            text: 'item $index',
                            variant: WTextVariant.body,
                          ),
                        ),
                      ),
                      header: const Padding(
                        padding: EdgeInsets.all(8),
                        child: WText(text: 'header', variant: WTextVariant.caption),
                      ),
                      footer: const Padding(
                        padding: EdgeInsets.all(8),
                        child: WText(text: 'footer', variant: WTextVariant.caption),
                      ),
                      empty: const Center(
                        child: WText(
                          text: '暂无数据（empty）',
                          variant: WTextVariant.caption,
                        ),
                      ),
                    ),
                  ),
                ),
                const CodeText(
                  'WListView(\n'
                  '  sliver: WListViewSliver.list(\n'
                  '    itemCount: 0,\n'
                  '    itemBuilder: ...,\n'
                  '    header: ..., footer: ..., empty: ...,\n'
                  '  ),\n'
                  ')',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'emptyFill：空态填满剩余视口',
            subtitle: 'shrinkWrap: true 时不能与 emptyFill 同时用（debug 断言）',
            child: DemoBox(
              height: 220,
              child: WListView(
                sliver: WListViewSliver.list(
                  itemCount: 0,
                  emptyFill: true,
                  itemBuilder: (context, index) => const SizedBox.shrink(),
                  empty: const Center(
                    child: WText(text: 'emptyFill', variant: WTextVariant.title),
                  ),
                ),
              ),
            ),
          ),
          DemoSection(
            title: 'separated / grid',
            child: Column(
              children: [
                DemoBox(
                  height: 200,
                  child: WListView(
                    sliver: WListViewSliver.separated(
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: scheme.outlineVariant),
                      itemBuilder: (context, index) => SizedBox(
                        height: 40,
                        child: Center(
                          child: WText(
                            text: 'separated $index',
                            variant: WTextVariant.body,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DemoBox(
                  height: 220,
                  child: WListView(
                    sliver: WListViewSliver.grid(
                      padding: const EdgeInsets.all(8),
                      itemCount: 8,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: WText(
                            text: '$index',
                            variant: WTextVariant.caption,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'overlap：固定 itemExtent + 叠压',
            subtitle: '只支持垂直、非 reverse；overlap 必须小于 itemExtent',
            child: DemoBox(
              height: 280,
              child: WListView(
                sliver: WListViewSliver.overlap(
                  itemCount: 6,
                  itemExtent: 80,
                  overlap: 24,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: WText(
                        text: 'overlap $index',
                        variant: WTextVariant.body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          DemoSection(
            title: '横向列表 + addAutomaticKeepAlives',
            subtitle: 'addAutomaticKeepAlives 启用保活；子项用 WKeepAliveWrapper 请求保留 State',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const WText(text: 'addAutomaticKeepAlives', variant: WTextVariant.caption),
                    Switch(
                      value: _keepAlive,
                      onChanged: (value) => setState(() => _keepAlive = value),
                    ),
                  ],
                ),
                DemoBox(
                  height: 120,
                  child: WListView(
                    scrollDirection: Axis.horizontal,
                    sliver: WListViewSliver.list(
                      itemCount: 20,
                      itemExtent: 84,
                      addAutomaticKeepAlives: _keepAlive,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) => _CounterTile(
                        index: index,
                        keepAlive: _keepAlive,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...buildListsNotificationSections(
            context: context,
            notifications: _notifications,
            bubbled: _bubbled,
            percent: _percent,
            prevent: _prevent,
            onPreventChanged: (value) => setState(() => _prevent = value),
            keepAlive: _keepAlive,
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatefulWidget {
  const _CounterTile({required this.index, required this.keepAlive});

  final int index;
  final bool keepAlive;

  @override
  State<_CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<_CounterTile> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return WKeepAliveWrapper(
      keepAlive: widget.keepAlive,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _count++),
            child: Center(
              child: WText(
                text: '${widget.index}\n×$_count',
                variant: WTextVariant.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
