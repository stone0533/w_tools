import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 组件页的概览 sections：文字 / 骨架 / 徽章 / 裁剪 / 进度 / 步骤 / 基础列表。
List<Widget> buildComponentsOverviewSections(BuildContext context) {
  return [
    const DemoSectionTitle('WText 语义文字'),
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
    const DemoSectionTitle('WIconText 图标 + 文字'),
    const Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        WIconText(icon: Icons.star, text: '收藏'),
        WIconText(
          icon: Icons.location_on,
          text: '上海市',
          variant: WTextVariant.caption,
        ),
        WIconText(
          icon: Icons.info_outline,
          text: '说明',
          color: Colors.indigo,
          iconOffset: Offset(0, 1),
        ),
      ],
    ),
    const SizedBox(height: 24),
    const DemoSectionTitle('WScaffold / WAppBar'),
    SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: const WScaffold.basic(
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
    const DemoSectionTitle('WScreen / BoxDecoration / 扩展'),
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
        Text('WScreen.of(context).w(16) = ${WScreen.of(context).w(16)}'),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 32,
          decoration: const BoxDecoration()
              .withGradient(
                WGradients.vertical([
                  Colors.indigo,
                  Colors.lightBlue,
                ]),
              )
              .withBorderRadius(const BorderRadius.all(Radius.circular(8)))
              .withShadow(WShadows.card),
        ),
      ],
    ),
    const SizedBox(height: 24),
    const DemoSectionTitle('WBadge 角标'),
    const Row(
      children: [
        WBadge(
          badgeContent: Text('3'),
          child: Icon(Icons.notifications, size: 32),
        ),
      ],
    ),
    const SizedBox(height: 12),
    const DemoSectionTitle('WBadge：center / showBadge:false / 空内容'),
    const Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        WBadge(
          position: WBadgePosition.center(),
          badgeContent: Text('NEW'),
          child: Icon(Icons.mail_outline, size: 32),
        ),
        WBadge(
          showBadge: false,
          badgeContent: Text('hidden'),
          child: Icon(Icons.inbox_outlined, size: 32),
        ),
        WBadge(
          child: Icon(Icons.notifications_none, size: 32),
        ),
      ],
    ),
    const SizedBox(height: 4),
    const Text('badgeContent 为空时静默不渲染（不报错）'),
    const SizedBox(height: 24),
    const DemoSectionTitle('WBadge.count / WBadge.dot'),
    Row(
      children: [
        WBadge.count(
          count: 120,
          maxCount: 99,
          child: const Icon(Icons.notifications, size: 32),
        ),
        const SizedBox(width: 32),
        WBadge.dot(child: const Icon(Icons.mark_email_unread_outlined, size: 32)),
      ],
    ),
    const SizedBox(height: 4),
    const Text('count 超过 maxCount 显示 99+；dot 不显示数字'),
    const SizedBox(height: 24),
    const DemoSectionTitle('ClipRRect 圆角裁剪'),
    ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
    const DemoSectionTitle('ClipRRect 非对称圆角 / 默认值'),
    const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: SizedBox(
            width: 96,
            height: 64,
            child: ColoredBox(color: Colors.indigo),
          ),
        ),
        ClipRRect(
          child: SizedBox(
            width: 96,
            height: 64,
            child: ColoredBox(color: Colors.indigo),
          ),
        ),
      ],
    ),
    const SizedBox(height: 24),
    const DemoSectionTitle('WGradientCircularProgressIndicator'),
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
    const DemoSectionTitle('WStep 步骤'),
    WStep(
      current: 2,
      labels: const ['选择', '确认', '完成'],
    ),
    const SizedBox(height: 24),
    const DemoSectionTitle('WListView 列表'),
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
  ];
}
