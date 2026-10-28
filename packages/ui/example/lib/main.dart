import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'playground_page.dart';
import 'recipes_page.dart';
import 'states_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 进程级缓存预算；占位符默认值交给 WImageTheme。
  WImageCachePolicy.configure(
    maxSize: 300,
    maxMemoryBytes: 300 * 1024 * 1024,
  );

  runApp(
    const WImageTheme(
      data: WImageThemeData(
        defaultPlaceholder: Center(child: CircularProgressIndicator()),
        defaultErrorWidget: Icon(Icons.broken_image),
      ),
      child: WImageExampleApp(),
    ),
  );
}

class WImageExampleApp extends StatelessWidget {
  const WImageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_ui · WImage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  void initState() {
    super.initState();
    // 让 WImage.assetImage('demo.png') 指向 example/assets/demo.png。
    WAssets.imagePath = 'assets/';
  }

  static const _pages = <Widget>[
    PlaygroundPage(),
    StatesPage(),
    RecipesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WImage 示例')),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Playground',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: '状态矩阵',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: '常用配方',
          ),
        ],
      ),
    );
  }
}
