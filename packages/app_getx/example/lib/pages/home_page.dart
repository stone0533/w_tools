import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';
import 'package:w_tools_async/w_tools_async.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _routeSnapshot;
  String _asyncResult = '未执行';

  /// 演示：插件里注册的 WAsyncExecutor，页面用 Get.find 取，hooks 由 app 统一配置。
  Future<void> _runAsync() async {
    final executor = Get.find<WAsyncExecutor>();
    final result = await executor.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 'executor: ok';
    });
    if (!mounted) return;
    setState(() => _asyncResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final language = WLanguageScope.of(context);
    final app = WApp.of(context);
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
          ValueListenableBuilder<String>(
            valueListenable: language.languageListenable,
            builder: (context, code, _) => Text(
              '当前语言：${language.currentLanguageName} ($code)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
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
                  language.changeLanguage(
                    language.currentLanguage == 'zh_CN' ? 'en_US' : 'zh_CN',
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
                onPressed: _runAsync,
                child: const Text('执行异步任务'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    // 路由栈：WRouteStack（每个 WApp 自己的 app.routeStack）
                    _routeSnapshot = app.routeStack.routes
                        .map((route) => route.settings.name ?? '(unnamed)')
                        .join(' → ');
                  });
                },
                child: const Text('查看路由栈'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('异步执行器：$_asyncResult', style: const TextStyle(fontSize: 14)),
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
                  Text('全局包裹：WAppOptions.builder（Theme/MediaQuery）'),
                  Text('AsyncExecutorPlugin：Get.put(WAsyncExecutor)，页面 Get.find'),
                  Text('最外层包裹：WAppOptions.appWrapper（RepaintBoundary）'),
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
