import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WNetworkImageWithRetry — 构造 & 基础渲染', () {
    testWidgets('required params — 组件正常渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              defaultPlaceholder: Text('LOAD'),
              defaultErrorWidget: Text('ERR'),
              retryCount: 3,
              retryDelay: 100,
            ),
          ),
        ),
      );

      expect(find.byType(WNetworkImageWithRetry), findsOneWidget);
      // 初始显示 defaultPlaceholder
      expect(find.text('LOAD'), findsOneWidget);
    });

    testWidgets('可选 params — width / height / fit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              width: 100,
              height: 200,
              fit: BoxFit.cover,
              defaultPlaceholder: SizedBox.shrink(),
              defaultErrorWidget: SizedBox.shrink(),
              retryCount: 2,
              retryDelay: 50,
            ),
          ),
        ),
      );

      expect(find.byType(WNetworkImageWithRetry), findsOneWidget);
    });

    testWidgets('State 初始重试计数为 0（ValueKey 携带 retry=0）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              defaultPlaceholder: Text('LOAD'),
              defaultErrorWidget: Text('ERR'),
              retryCount: 3,
              retryDelay: 100,
            ),
          ),
        ),
      );

      // 内部 State 已私有化，改为断言重试计数绑定的 ValueKey
      expect(
        find.byKey(const ValueKey('https://example.com/img.png#retry=0')),
        findsOneWidget,
      );
      // 注意：isLoading 在第一次 build → placeholder 回调触发后被置为 false
      // 所以不能在 pumpWidget 后验证 isLoading=true
    });

    testWidgets('progressIndicatorBuilder 分支正常构建', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              progressIndicatorBuilder: (_, __, ___) => const Text('PROG'),
              defaultPlaceholder: const Text('LOAD'),
              defaultErrorWidget: const Text('ERR'),
              retryCount: 1,
              retryDelay: 10,
            ),
          ),
        ),
      );

      // 有 progressIndicatorBuilder → 走第一分支 (源码 if 分支)
      expect(find.byType(WNetworkImageWithRetry), findsOneWidget);
      expect(find.text('PROG'), findsOneWidget);
    });
  });

  group('onLoadStatusChanged 回调 wiring', () {
    testWidgets('首次 pump 触发 loading 状态', (tester) async {
      final statuses = <WImageLoadStatus>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              defaultPlaceholder: const Text('LOAD'),
              defaultErrorWidget: const Text('ERR'),
              retryCount: 2,
              retryDelay: 10,
              onLoadStatusChanged: (s) => statuses.add(s),
            ),
          ),
        ),
      );

      await tester.pump();
      // 源码 isLoading=true → placeholder 里调 onLoadStatusChanged(loading)
      expect(statuses, contains(WImageLoadStatus.loading));
    });
  });

  group('placeholder 覆盖默认值', () {
    testWidgets('placeholder 非空 → 覆盖 defaultPlaceholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WNetworkImageWithRetry(
              imageUrl: 'https://example.com/img.png',
              placeholder: (_, __) => const Text('CUSTOM_LOAD'),
              defaultPlaceholder: const Text('DEFAULT_LOAD'),
              defaultErrorWidget: const Text('ERR'),
              retryCount: 2,
              retryDelay: 10,
            ),
          ),
        ),
      );

      // 源码 placeholder?.call(...) ?? defaultPlaceholder
      expect(find.text('CUSTOM_LOAD'), findsOneWidget);
      expect(find.text('DEFAULT_LOAD'), findsNothing);
    });
  });

  group('WImageLoadStatus enum', () {
    test('枚举值齐全且顺序正确', () {
      expect(WImageLoadStatus.values, hasLength(3));
      expect(WImageLoadStatus.values[0], WImageLoadStatus.loading);
      expect(WImageLoadStatus.values[1], WImageLoadStatus.completed);
      expect(WImageLoadStatus.values[2], WImageLoadStatus.failed);
    });
  });
}
