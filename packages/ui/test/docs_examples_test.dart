import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

/// README 片段的编译 / 运行回归；保持与 README 的快速开始和 WImage 配方同步。
void main() {
  test('README 不包含 7.0 已删除的 API', () {
    final readme = File('README.md').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(readme, contains('w_tools_ui: ^$version'));
    expect(readme, contains('options: WImageLoadOptions'));
    expect(readme, isNot(contains('config: WImageLoadConfig')));
    expect(readme, isNot(contains('WHexColor')));
    expect(readme, isNot(contains('WImageStyleX')));
  });

  testWidgets('README 快速开始可渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          title: '快速开始',
          body: WText(text: 'Hello w_tools_ui', variant: WTextVariant.title),
        ),
      ),
    );
    expect(find.text('快速开始'), findsOneWidget);
    expect(find.text('Hello w_tools_ui'), findsOneWidget);
  });

  testWidgets('README WImage options / slots 配方可编译并渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WImage.source(
              source: WImageSource.base64(_redPixel),
              style: const WImageStyle(width: 32, height: 32),
              options: const WImageLoadOptions(memCacheWidth: 64),
              slots: const WImageSlots(showRetryButton: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('README 导航 / 角标 / 裁剪片段可渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              WTabBar(
                style: WTabBarStyle(),
                tabs: [Text('全部'), Text('已完成')],
              ),
              Expanded(
                child: TabBarView(children: [Text('全部内容'), Text('已完成内容')]),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(WTabBar), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WBadge(badgeContent: Text('3'), child: Icon(Icons.notifications)),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  test('README 扩展段落使用新扩展名', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('WColorExtension'));
    expect(readme, contains('WImageStyleExtension'));
  });
}
