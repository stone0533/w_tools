// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'buttons_page.dart';
import 'components_page.dart';
import 'more_page.dart';
import 'playground_page.dart';
import 'recipes_page.dart';
import 'states_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 进程级缓存预算；占位符/错误占位默认值交给 WImageDefaultsScope。
  PaintingBinding.instance.imageCache
    ..maximumSize = 300
    ..maximumSizeBytes = 300 * 1024 * 1024;

  runApp(
    WImageDefaultsScope(
      defaults: WImageLoadConfig(
        placeholderBuilder: (context, data) => const Center(child: CircularProgressIndicator()),
        errorWidgetBuilder: (context, data, error) => const Icon(Icons.broken_image),
      ),
      child: const WUiExampleApp(),
    ),
  );
}

class WUiExampleApp extends StatelessWidget {
  const WUiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'w_tools_ui · 示例',
      // 一次装好 TextTheme 与 WTextStyles：Material 组件（form/toast/async）
      // 与 WText 看到同一套字号。
      theme: base.withWTextStyles(
        WTextStyles.fromTextTheme(base.textTheme),
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

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final WNavController _navController;

  static const _pages = <Widget>[
    PlaygroundPage(),
    StatesPage(),
    RecipesPage(),
    ButtonsPage(),
    ComponentsPage(),
    MorePage(),
  ];

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.tune, label: 'Playground'),
    (icon: Icons.grid_view, label: '状态矩阵'),
    (icon: Icons.receipt_long, label: '常用配方'),
    (icon: Icons.smart_button, label: '按钮'),
    (icon: Icons.widgets, label: '组件'),
    (icon: Icons.more_horiz, label: '更多'),
  ];

  @override
  void initState() {
    super.initState();
    // 让 WImage.source(source: WImageSource.asset('demo.png', prefix: true)) 指向 example/assets/demo.png。
    WAssets.imagePath = 'assets/';
    _navController = WNavController(
      length: _destinations.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WScaffold(
      title: 'w_tools_ui 示例',
      body: ListenableBuilder(
        listenable: _navController,
        builder: (context, _) => IndexedStack(
          index: _navController.currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: WNavBar(
        config: const WNavBarConfig(),
        controller: _navController,
        itemBuilder: (context, index, selected) {
          final item = _destinations[index];
          final color = selected ? Colors.indigo : Colors.grey;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(height: 2),
              WText(
                text: item.label,
                variant: WTextVariant.caption,
                color: color,
              ),
            ],
          );
        },
      ),
    );
  }
}
