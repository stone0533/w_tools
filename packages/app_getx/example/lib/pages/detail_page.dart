import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('详情路由')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('这是通过 GetX 路由打开的页面。'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: Get.back,
              child: const Text('返回'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // 移除当前路由即回到上一页，不需要再 Get.back()。
                app.routeStack.removeRouteIfExists('/detail');
              },
              child: const Text('移除当前路由后返回'),
            ),
            TextButton(
              onPressed: () => app.routeStack.popUntilRoute('/'),
              child: const Text('回到首页（app.routeStack.popUntilRoute）'),
            ),
          ],
        ),
      ),
    );
  }
}
