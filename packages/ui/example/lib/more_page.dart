import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';
import 'extensions_page.dart';
import 'lists_page.dart';
import 'nav_page.dart';
import 'scaffold_page.dart';
import 'steps_page.dart';
import 'text_page.dart';

/// 二级示例入口：按能力拆分，避免主 Tab 塞太多页。
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <(String, String, WidgetBuilder)>[
      (
        'WScaffold / WAppBar / WScreen',
        '页面骨架、状态栏、安全区、屏幕适配、资源前缀',
        (_) => const ScaffoldDemoPage(),
      ),
      (
        'WText / WTextStyles',
        '11 个 variant、覆盖参数、自定义品牌样式',
        (_) => const TextDemoPage(),
      ),
      (
        '扩展方法',
        '数字 / 字符串 / 颜色 / 文字样式 / Widget / BoxDecoration / GlobalKey',
        (_) => const ExtensionsDemoPage(),
      ),
      (
        'WListView / 通知 / keepAlive',
        'list / separated / grid / overlap / 空态 / 百分比 / 保活',
        (_) => const ListsDemoPage(),
      ),
      (
        'WNavBar / WNavController / WTabBar',
        '切换动画、onBeforeTap 拦截、WNavBarStyle、WTabBar 配置',
        (_) => const NavDemoPage(),
      ),
      (
        'WStep / WStepFlow',
        'WStepStyle、itemBuilder / separatorBuilder、流程复用',
        (_) => const StepsDemoPage(),
      ),
    ];

    return WScaffold(
      title: '更多示例',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WText(
            text: '按能力拆分的二级示例页，每个页面覆盖一组公开 API。',
            variant: WTextVariant.caption,
          ),
          const SizedBox(height: 16),
          for (final demo in demos)
            DemoEntryTile(
              title: demo.$1,
              description: demo.$2,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: demo.$3),
              ),
            ),
        ],
      ),
    );
  }
}
