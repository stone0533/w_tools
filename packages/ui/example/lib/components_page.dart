// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 覆盖非 WImage 的核心组件：文字、徽标、裁剪、进度、步骤、
/// 列表、横向按钮、Tab、底部导航、通知与保活。
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> with TickerProviderStateMixin {
  late final WNavController _navController;
  int _selectedTag = 0;
  late final WImageController _imageController;
  double? _scrollPercent;
  double _actionOffset = 0;

  @override
  void initState() {
    super.initState();
    _navController = WNavController(length: 3, vsync: this);
    _imageController = WImageController();
  }

  @override
  void dispose() {
    _navController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('WText 语义文字'),
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            WText(text: 'title', variant: WTextVariant.title),
            WText(text: 'body', variant: WTextVariant.body),
            WText(text: 'caption', variant: WTextVariant.caption),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WScaffold / WAppBar'),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const WScaffold(
              title: 'WScaffold',
              body: Center(
                child: WText(
                  text: 'WScaffold + WAppBar',
                  variant: WTextVariant.body,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WScreen / BoxDecoration / 扩展'),
        Row(
          children: [
            const SizedBox(width: 32, height: 32),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 32,
                height: 32,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
            const Text('1234 → '),
            Text(1234.toThousandsSeparated),
            const SizedBox(width: 8),
            const Text(' #FF5733 → '),
            Container(
              width: 16,
              height: 16,
              color: '#FF5733'.toColor(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('WScreen.w(16) = ${WScreen.w(16)}'),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 32,
              decoration: const BoxDecoration()
                  .withGradient(WGradients.vertical([
                    Colors.indigo,
                    Colors.lightBlue,
                  ]))
                  .withBorderRadius(const BorderRadius.all(Radius.circular(8)))
                  .withShadow(WShadows.card),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WBadge 角标'),
        Row(
          children: [
            WBadge(
              config: WBadgeConfig.topRight(top: 0, end: 0),
              badgeContent: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              child: const Icon(Icons.notifications, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _SectionTitle('WBadge：center / showBadge:false / 空内容'),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            WBadge(
              config: WBadgeConfig.center(),
              badgeContent: const Text('NEW'),
              child: const Icon(Icons.mail_outline, size: 32),
            ),
            const WBadge(
              config: WBadgeConfig(showBadge: false),
              badgeContent: Text('hidden'),
              child: Icon(Icons.inbox_outlined, size: 32),
            ),
            const WBadge(
              child: Icon(Icons.notifications_none, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('badgeContent 为空时静默不渲染（不报错）'),
        const SizedBox(height: 24),
        const _SectionTitle('WClipRRect 圆角裁剪'),
        WClipRRect(
          config: WClipRRectConfig.all(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 120,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
              ),
            ),
            child: const Center(
              child: WText(
                text: 'clip',
                variant: WTextVariant.bodyStrong,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionTitle('WClipRRect 配置变体'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            WClipRRect(
              config: WClipRRectConfig.all(8).copyWith(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const SizedBox(
                width: 96,
                height: 64,
                child: ColoredBox(color: Colors.indigo),
              ),
            ),
            const WClipRRect(
              child: SizedBox(
                width: 96,
                height: 64,
                child: ColoredBox(color: Colors.indigo),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WGradientCircularProgressIndicator'),
        const Center(
          child: WGradientCircularProgressIndicator(
            radius: 32,
            value: 0.65,
            semanticsLabel: '加载中',
            colors: [Colors.indigo, Colors.lightBlue],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            WGradientCircularProgressIndicator(
              radius: 24,
              value: 0.35,
              strokeWidth: 4,
              strokeCapRound: true,
              colors: [Colors.deepOrange, Colors.orangeAccent],
            ),
            WGradientCircularProgressIndicator(
              radius: 24,
              value: 0.7,
              totalAngle: 4.7,
              backgroundColor: Color(0xFFE0E7FF),
              colors: [Colors.indigo, Colors.lightBlue],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WStep 步骤'),
        const WStep(
          current: 2,
          labels: ['选择', '确认', '完成'],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WListView 列表'),
        SizedBox(
          height: 150,
          child: WListView(
            sliver: WListViewSliver.separated(
              itemCount: 20,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('列表项 ${index + 1}'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WListViewSliver.grid / Row / Column'),
        SizedBox(
          height: 140,
          child: WListView(
            sliver: WListViewSliver.grid(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => Container(
                alignment: Alignment.center,
                color: Colors.indigo.shade50,
                child: Text('格 $index'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 12, color: Colors.indigo),
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WText(text: 'Row + Column', variant: WTextVariant.bodyStrong),
                WText(text: 'min 主轴尺寸', variant: WTextVariant.caption),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WSelectableRow 横向单选'),
        WSelectableRow(
          itemCount: 6,
          selectedIndex: _selectedTag,
          onSelected: (index) => setState(() => _selectedTag = index),
          spacing: 8,
          builder: (context, index, selected) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.indigo : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '标签 $index',
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WActionRow 横向滚动操作行'),
        WActionRow(
          spacing: 8,
          padding: const EdgeInsets.symmetric(vertical: 4),
          onScroll: (offset) => setState(() => _actionOffset = offset),
          children: [
            for (var i = 0; i < 12; i++)
              ActionChip(
                label: Text('动作 $i'),
                onPressed: () {},
              ),
          ],
        ),
        Text('onScroll offset: ${_actionOffset.toStringAsFixed(1)}'),
        const SizedBox(height: 24),
        const _SectionTitle('WTabBar 顶部 Tab'),
        const SizedBox(
          height: 180,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                WTabBar(
                  config: WTabBarConfig(),
                  tabs: [
                    Tab(text: '全部'),
                    Tab(text: '进行中'),
                    Tab(text: '已完成'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Center(child: Text('全部内容')),
                      Center(child: Text('进行中内容')),
                      Center(child: Text('已完成内容')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WNavBar 底部导航'),
        SizedBox(
          height: 64,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: WNavBar(
              config: const WNavBarConfig(),
              controller: _navController,
              itemBuilder: (context, index, selected) {
                const icons = [Icons.home, Icons.message, Icons.person];
                return Icon(
                  icons[index],
                  color: selected ? Colors.indigo : Colors.grey,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WNotificationListenerBuilder 滚动百分比'),
        WNotificationListenerBuilder<ScrollNotification>(
          child: SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: 30,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                title: Text('滚动项 $index'),
              ),
            ),
          ),
        ).onNotificationPercentage((value) {
          if (mounted) setState(() => _scrollPercent = value);
        }).build(),
        const SizedBox(height: 8),
        Text(
          _scrollPercent == null ? '滚动上面的列表查看百分比' : '滚动百分比：${(_scrollPercent! * 100).round()}%',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WImageController 手动重试'),
        WImage.source(
            source: WImageSource.network('https://example.invalid/controller.png'),
            controller: _imageController,
            style: const WImageStyle(width: 160, height: 90),
            slots: const WImageSlots(showRetryButton: true)),
        TextButton(
          onPressed: _imageController.retry,
          child: const Text('controller.retry()'),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('WKeepAliveWrapper 列表保活'),
        SizedBox(
          height: 96,
          child: WListView(
            scrollDirection: Axis.horizontal,
            sliver: WListViewSliver.list(
              itemCount: 8,
              itemExtent: 96,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WKeepAliveWrapper(
                  child: _CounterTile(index: index),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CounterTile extends StatefulWidget {
  const _CounterTile({required this.index});

  final int index;

  @override
  State<_CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<_CounterTile> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _count++),
        child: Center(
          child: Text(
            '#${widget.index}\n$_count',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
