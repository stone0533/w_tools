# Demo Page 映射

从 `example/fixtures/nodes-demo.json` 映射出的页面骨架：

```dart
import 'package:app/app/w/toolkit.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 72),
            WText('欢迎回来', variant: WTextVariant.title),
            const WSizeBox.height(24),
            WButton(
              label: '主要操作',
              onTap: () {},
            ),
            const WSizeBox.height(32),
            WText('这是一段说明文字', variant: WTextVariant.body),
          ],
        ),
      ),
    );
  }
}
```

说明：

```text
FRAME       → AppScaffold
TEXT 标题   → WText variant
RECTANGLE   → WButton（实际项目按组件规则映射）
TEXT 说明   → WText
间距        → WSizeBox
```

这里是片段，不是可直接编译的独立 App；实际项目使用自己的
`AppScaffold` / `AppBars` / `WTextVariant`。
