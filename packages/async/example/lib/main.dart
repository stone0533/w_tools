import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'pages/execution_page.dart';
import 'pages/paged_page.dart';
import 'pages/sliver_page.dart';
import 'pages/async_view_page.dart';

void main() {
  runApp(const AsyncExampleApp());
}

class AsyncExampleApp extends StatelessWidget {
  const AsyncExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WAsyncViewDefaults(
      loadingBuilder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('全局 loading'),
          ],
        ),
      ),
      emptyBuilder: (_) => const Center(child: Text('全局 empty：暂无数据')),
      errorBuilder: (context, error, onRetry) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('全局 error：$error'),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
      child: WAsyncSliverDefaults(
        loadingBuilder: (_) => const Center(child: Text('Sliver loading')),
        emptyBuilder: (_) => const Center(child: Text('Sliver empty')),
        errorBuilder: (context, error, onRetry) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sliver error：$error'),
              const SizedBox(height: 8),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
        child: MaterialApp(
          title: 'w_tools_async 示例',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF0EA5E9),
            useMaterial3: true,
          ),
          home: const _ExampleHome(),
        ),
      ),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          AsyncViewPage(),
          PagedPage(),
          SliverPage(),
          ExecutionPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.autorenew_rounded),
            label: '四态',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_rounded),
            label: '分页',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_day_rounded),
            label: 'Sliver',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded),
            label: '执行',
          ),
        ],
      ),
    );
  }
}
