import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 组件页中依赖页面状态 / controller 的 sections。
List<Widget> buildComponentsStateSections({
  required BuildContext context,
  required int selectedTag,
  required ValueChanged<int> onSelectedTag,
  required double actionOffset,
  required ValueChanged<double> onActionOffset,
  required WNavController navController,
  required double? scrollPercent,
  required ValueChanged<double> onScrollPercent,
}) {
  return [
    const DemoSectionTitle('WListViewSliver.grid / Row / Column'),
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
    const DemoSectionTitle('WSelectableRow 横向单选'),
    WSelectableRow(
      itemCount: 6,
      selectedIndex: selectedTag,
      onSelected: onSelectedTag,
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
    const DemoSectionTitle('WActionRow 横向滚动操作行'),
    WActionRow(
      spacing: 8,
      padding: const EdgeInsets.symmetric(vertical: 4),
      onScroll: onActionOffset,
      children: [
        for (var i = 0; i < 12; i++)
          ActionChip(
            label: Text('动作 $i'),
            onPressed: () {},
          ),
      ],
    ),
    Text('onScroll offset: ${actionOffset.toStringAsFixed(1)}'),
    const SizedBox(height: 24),
    const DemoSectionTitle('Material TabBar 顶部 Tab'),
    const SizedBox(
      height: 180,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
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
    const DemoSectionTitle('WNavBar 底部导航'),
    SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: WNavBar(
          controller: navController,
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
    const DemoSectionTitle('WNotificationListener 滚动百分比'),
    WNotificationListener<ScrollNotification>(
      onNotificationPercentage: onScrollPercent,
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
    ),
    const SizedBox(height: 8),
    Text(
      scrollPercent == null ? '滚动上面的列表查看百分比' : '滚动百分比：${(scrollPercent * 100).round()}%',
    ),
    const SizedBox(height: 24),
  ];
}
