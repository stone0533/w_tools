import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// WScaffold / WAppBar / WScreen / WAssets 的完整参数演示。
class ScaffoldDemoPage extends StatelessWidget {
  const ScaffoldDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = WScreen.of(context);
    final scheme = Theme.of(context).colorScheme;

    return WScaffold(
      title: 'WScaffold / WAppBar / WScreen',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: 'WScaffold：title + actions + onBack + FAB',
            subtitle: 'title 会自动构建 WAppBar；onBack 优先于 canPop',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoBox(
                  height: 280,
                  child: WScaffold(
                    title: '订单详情',
                    actions: [
                      IconButton(
                        tooltip: '搜索',
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                      ),
                    ],
                    onBack: () {},
                    floatingActionButton: FloatingActionButton.small(
                      onPressed: () {},
                      child: const Icon(Icons.add),
                    ),
                    body: const Center(
                      child: WText(text: 'WScaffold.body', variant: WTextVariant.body),
                    ),
                  ),
                ),
                const CodeText(
                  "WScaffold(\n"
                  "  title: '订单详情',\n"
                  "  actions: [IconButton(...)],\n"
                  "  onBack: () {},\n"
                  "  floatingActionButton: FloatingActionButton.small(...),\n"
                  "  body: ...,\n"
                  ")",
                ),
              ],
            ),
          ),
          const DemoSection(
            title: 'WScaffold：appBarBottom + bottomNavigationBar',
            subtitle: '有 bottomNavigationBar 时，body 不再重复加底部安全区',
            child: DemoBox(
              height: 280,
              child: WScaffold(
                title: 'Tab 页',
                appBarBottom: PreferredSize(
                  preferredSize: Size.fromHeight(40),
                  child: Center(child: WText(text: 'appBarBottom')),
                ),
                bottomNavigationBar: SizedBox(
                  height: 48,
                  child: Center(child: WText(text: 'bottomNavigationBar')),
                ),
                body: Center(
                  child: WText(text: 'body', variant: WTextVariant.body),
                ),
              ),
            ),
          ),
          DemoSection(
            title: 'WScaffold：underlayWidget + 状态栏样式 + 顶部安全区',
            subtitle: 'underlay 在 body 之下，适合渐变背景',
            child: DemoBox(
              height: 300,
              child: WScaffold(
                title: '渐变背景',
                backgroundColor: Colors.transparent,
                includeTopSafeArea: true,
                systemStatusBarStyle: SystemUiOverlayStyle.light,
                underlayWidget: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: WGradients.diagonal([
                      scheme.primary,
                      scheme.tertiary,
                    ]),
                  ),
                ),
                body: const Center(
                  child: WText(
                    text: 'underlayWidget + systemStatusBarStyle',
                    variant: WTextVariant.body,
                  ),
                ),
              ),
            ),
          ),
          const DemoSection(
            title: 'WScaffold：appBar 完全覆盖',
            subtitle: '传 appBar 时，WScaffold 上的 title/leading/actions 必须保持默认',
            child: DemoBox(
              height: 260,
              child: WScaffold(
                appBar: WAppBar(
                  title: '自定义 WAppBar',
                  centerTitle: false,
                  actions: [Icon(Icons.more_horiz)],
                ),
                body: Center(
                  child: WText(text: 'appBar: WAppBar(...)', variant: WTextVariant.body),
                ),
              ),
            ),
          ),
          const DemoSection(
            title: 'WAppBar：title / titleWidget / leading / actions / bottom',
            subtitle: '单独使用时建议 includeStatusBar: false，避免重复状态栏内边距',
            child: Column(
              children: [
                DemoBox(
                  height: 56,
                  child: WAppBar(title: '默认标题', includeStatusBar: false),
                ),
                SizedBox(height: 8),
                DemoBox(
                  height: 56,
                  child: WAppBar(
                    title: '左对齐 + 返回',
                    centerTitle: false,
                    onBack: _noop,
                    includeStatusBar: false,
                  ),
                ),
                SizedBox(height: 8),
                DemoBox(
                  height: 56,
                  child: WAppBar(
                    titleWidget: WText(
                      text: 'titleWidget',
                      variant: WTextVariant.title,
                    ),
                    leading: Icon(Icons.menu),
                    actions: [
                      Icon(Icons.favorite_border),
                      Icon(Icons.share_outlined),
                    ],
                    includeStatusBar: false,
                  ),
                ),
                SizedBox(height: 8),
                DemoBox(
                  height: 96,
                  child: WAppBar(
                    title: '带 bottom',
                    includeStatusBar: false,
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(40),
                      child: Center(child: WText(text: 'bottom')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WAppBarStyle：背景 / 渐变 / 高度 / 标题 / overlay',
            subtitle: 'backgroundColor 与 gradient 只能选一个（debug 断言）',
            child: Column(
              children: [
                const DemoBox(
                  height: 64,
                  child: WAppBar(
                    title: '渐变 + 64 高',
                    includeStatusBar: false,
                    style: WAppBarStyle(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                      ),
                      foregroundColor: Colors.white,
                      height: 64,
                      titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      titleSpacing: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DemoBox(
                  height: 56,
                  child: WAppBar(
                    title: '纯色背景',
                    includeStatusBar: false,
                    style: WAppBarStyle(
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WScreen：树内尺寸 / 安全区 / 适配委托',
            subtitle: '优先 WScreen.of(context)；静态 getter 读平台 view',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(
                  label: 'WScreen.of(context).width',
                  value: screen.width.toStringAsFixed(1),
                ),
                _KeyValue(label: 'height', value: screen.height.toStringAsFixed(1)),
                _KeyValue(
                  label: 'statusBarHeight',
                  value: screen.statusBarHeight.toStringAsFixed(1),
                ),
                _KeyValue(
                  label: 'bottomSafeAreaHeight',
                  value: screen.bottomSafeAreaHeight.toStringAsFixed(1),
                ),
                _KeyValue(label: 'screen.w(16)', value: screen.w(16).toStringAsFixed(1)),
                _KeyValue(label: 'screen.h(16)', value: screen.h(16).toStringAsFixed(1)),
                _KeyValue(label: 'screen.sp(14)', value: screen.sp(14).toStringAsFixed(1)),
                const CodeText(
                  '// 与 flutter_screenutil 共存：在 App 根节点注入 scope\n'
                  'WScreenScope(\n'
                  '  widthScaler: (v) => ScreenUtil().setWidth(v),\n'
                  '  heightScaler: (v) => ScreenUtil().setHeight(v),\n'
                  '  fontScaler: (v) => ScreenUtil().setSp(v),\n'
                  '  child: app,\n'
                  ')',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WAssets：资源前缀唯一开关',
            subtitle: 'setter 会自动补齐末尾 /；空字符串表示不添加前缀',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(label: 'WAssets.imagePath', value: WAssets.imagePath),
                _KeyValue(label: "'logo.png'.assetImagePath", value: 'logo.png'.assetImagePath),
                const CodeText(
                  "WAssets.imagePath = 'assets/images/';\n"
                  "WImage.source(source: WImageSource.asset('logo.png', prefix: true))",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

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
          Expanded(
            child: WText(text: label, variant: WTextVariant.caption),
          ),
          WText(text: value, variant: WTextVariant.bodyStrong),
        ],
      ),
    );
  }
}
