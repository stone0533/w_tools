import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _routeSnapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('w_tools_app 示例')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '启动与插件',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...startupEvents.map(
            (event) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(event),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            // 读取 Rx 才会让 Obx 订阅语言变化。
            final code = WLanguage().languageStream.value;
            return Text(
              '当前语言：${WLanguage().currentLanguageName} ($code)',
              style: const TextStyle(fontSize: 16),
            );
          }),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => Get.toNamed('/detail'),
                child: const Text('打开详情路由'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  WLanguage().changeLanguage(
                    WLanguage().currentLanguage == 'zh_CN' ? 'en_US' : 'zh_CN',
                  );
                },
                child: const Text('切换语言'),
              ),
              OutlinedButton(
                onPressed: () => WBottomSheet.show(
                  const _DemoSheet(),
                ),
                child: const Text('底部弹窗'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _routeSnapshot = WRouteStack.defaultStack.routes
                        .map((route) => route.settings.name ?? '(unnamed)')
                        .join(' → ');
                  });
                },
                child: const Text('查看路由栈'),
              ),
            ],
          ),
          if (_routeSnapshot != null) ...[
            const SizedBox(height: 16),
            Text(
              '路由栈：$_routeSnapshot',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 16),
          ValueListenableBuilder<List<String>>(
            valueListenable: routeEvents,
            builder: (context, events, _) => Text(
              '路由事件：${events.join(' / ')}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('启动顺序', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('WApp.init → 系统设置 → 插件 onInit → run'),
                  Text('插件：FeaturePlugin 依赖 EnvPlugin，先 env 后 feature'),
                  Text('WRouteObserver 由 WApp 自动追加'),
                  Text('PresentationPlugin: builderWrapper + wrapApp'),
                  Text('WApp.builder / appWrapper 也已启用'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoSheet extends StatelessWidget {
  const _DemoSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'WBottomSheet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('点击内容上方的空白区域可以关闭弹窗。'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: Get.back,
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}
