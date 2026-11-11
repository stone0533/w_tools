// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui/src/internal/image_loader.dart';
import 'package:w_tools_ui/src/components/common/image/image_size_hint.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });
  setUp(debugResetWImageSizeHintCache);

  group('WImageStyle', () {
    test('字段可读，copyWith 产生新实例', () {
      const style = WImageStyle(
        width: 100,
        height: 200,
        fit: BoxFit.cover,
      );
      expect(style.width, 100);
      expect(style.height, 200);
      expect(style.fit, BoxFit.cover);

      final next = style.copyWith(width: 10);
      expect(next.width, 10);
      expect(style.width, 100);
    });

    test('非法配置触发 assert', () {
      expect(
        () => WImage.source(
          source: WImageSource.parse('x'),
          options: const WImageLoadOptions(retryCount: -1),
        ),
        throwsAssertionError,
      );
      expect(
        () => WImage.source(
          source: WImageSource.parse('x'),
          options: const WImageLoadOptions(retryDelay: -1),
        ),
        throwsAssertionError,
      );
      expect(
        () => WImage.source(
          source: WImageSource.parse('x'),
          options: const WImageLoadOptions(memCacheWidth: 0),
        ),
        throwsAssertionError,
      );
      expect(
        () => WImage.source(
          source: WImageSource.parse('x'),
          options: const WImageLoadOptions(memCacheHeight: 0),
        ),
        throwsAssertionError,
      );
      expect(
        () => WImage.source(
          source: WImageSource.parse('x'),
          style: const WImageStyle(aspectRatio: 0),
        ),
        throwsAssertionError,
      );
      expect(
        () => WImage.source(source: WImageSource.parse('x'), style: const WImageStyle(width: -1)),
        throwsAssertionError,
      );
    });

    test('validate 捕获 aspectRatio 与固定宽高的冲突', () {
      expect(
        () => const WImageStyle(aspectRatio: 2, width: 10, height: 10).validate(),
        throwsAssertionError,
      );
    });
  });

  group('WImageLoader', () {
    testWidgets('retry 配置变化会取消已排队重试', (tester) async {
      final loader = WImageLoader(retryCount: 1, retryDelay: 1000);
      loader.handleError(
        Exception('network'),
        const WImageError('x', WImageErrorKind.network),
        retry: true,
      );
      expect(loader.retryScheduled, isTrue);

      loader.syncRetryConfig(retryCount: 3, retryDelay: 200);
      expect(loader.retryScheduled, isFalse);
      loader.dispose();
    });

    testWidgets('失败后修改 retry 配置保留 error 状态', (tester) async {
      final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
      loader.handleError(
        Exception('network'),
        const WImageError('x', WImageErrorKind.network),
      );
      expect(loader.status, WImageLoadStatus.failed);
      expect(loader.error, isNotNull);

      loader.syncRetryConfig(retryCount: 1, retryDelay: 200);
      expect(loader.status, WImageLoadStatus.failed);
      expect(loader.error, isNotNull);
      loader.dispose();
    });

    testWidgets('reset 会取消已排队的 retry', (tester) async {
      final loader = WImageLoader(retryCount: 1, retryDelay: 1000);
      loader.handleError(
        Exception('network'),
        const WImageError('x', WImageErrorKind.network),
        retry: true,
      );
      expect(loader.retryScheduled, isTrue);

      loader.reset(retryCount: 0, retryDelay: 1000);
      expect(loader.retryScheduled, isFalse);
      loader.dispose();
    });

    testWidgets('dispose 会取消重试状态', (tester) async {
      final loader = WImageLoader(retryCount: 1, retryDelay: 1000);
      loader.handleError(
        Exception('network'),
        const WImageError('x', WImageErrorKind.network),
        retry: true,
      );
      expect(loader.retryScheduled, isTrue);

      loader.dispose();
      expect(loader.retryScheduled, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(loader.retryScheduled, isFalse);
    });
  });

  testWidgets('WImageController 解绑后状态保留且 retry 安全', (tester) async {
    final controller = WImageController();
    await tester.pumpWidget(
      MaterialApp(
        home: WImage.source(source: WImageSource.base64('invalid'), controller: controller),
      ),
    );
    expect(controller.isAttached, isTrue);
    final state = controller.state;
    expect(state, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(controller.isAttached, isFalse);
    expect(controller.state, same(state));

    expect(controller.retry, returnsNormally);
  });

  group('WImage', () {
    test('should build with config', () {
      const style = WImageStyle(width: 100, height: 100);
      final image = WImage.source(source: WImageSource.parse('test_image.png'), style: style);

      expect(image.style.width, 100);
      expect(image.style.height, 100);
      expect(image.source.type, WImageType.asset);
    });

    test('WImage.source + WImageStyle', () {
      final image = WImage.source(
        source: WImageSource.base64('AAAA'),
        style: const WImageStyle(width: 10, height: 10),
      );
      expect(image.source, isA<WBase64ImageSource>());
      expect(image.style.width, 10);
      expect(image.source.type, WImageType.base64);
    });

    testWidgets('style 固定占位符优先于 defaults', (tester) async {
      await tester.pumpWidget(
        WImageTheme(
          slots: WImageSlots(
            placeholderBuilder: (context, data) => const Text('theme'),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: WImage.source(
                source: WImageSource.parse('data:image/png;base64,@@bad@@'),
                slots: const WImageSlots(placeholder: Text('style')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('style'), findsOneWidget);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('WImageTheme 覆盖默认占位符', (tester) async {
      await tester.pumpWidget(
        WImageTheme(
          slots: WImageSlots(
            placeholderBuilder: (context, data) => const Text('themed'),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: WImage.source(source: WImageSource.parse('data:image/png;base64,@@bad@@')),
            ),
          ),
        ),
      );
      expect(find.text('themed'), findsOneWidget);
    });

    testWidgets('WImageTheme.errorBuilder 接收错误类型', (tester) async {
      await tester.pumpWidget(
        WImageTheme(
          slots: WImageSlots(
            errorWidgetBuilder: (context, data, error) => Text('ERR:${error.runtimeType}'),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: WImage.source(source: WImageSource.parse('data:image/png;base64,@@bad@@')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('ERR:WImageError'), findsOneWidget);
    });

    test('memory / provider 类型', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final memory = WImage.source(source: WImageSource.provider(MemoryImage(bytes)));
      expect(memory.source.type, WImageType.provider);
      expect(memory.source, isA<WProviderImageSource>());
    });

    testWidgets('memory 图片可渲染', (tester) async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.provider(MemoryImage(bytes)),
            style: const WImageStyle(width: 10, height: 10),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('showRetryButton 使用内置错误视图并可重试', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([1, 2, 3]))),
            controller: controller,
            style: const WImageStyle(width: 160, height: 120),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WImageErrorView), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(controller.state.value.attempt, 1);
    });

    testWidgets('不可重试的错误不显示重试按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.parse('data:image/png;base64,@@bad@@'),
            style: const WImageStyle(width: 160, height: 120),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WImageErrorView), findsOneWidget);
      expect(find.text('重试'), findsNothing);
    });

    testWidgets('小尺寸错误视图只显示图标，不溢出', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.parse('data:image/png;base64,@@bad@@'),
            style: const WImageStyle(width: 40, height: 40),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WImageErrorView), findsOneWidget);
      expect(find.text('重试'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('同一 provider 重建时复用', (tester) async {
      final provider = MemoryImage(Uint8List.fromList([9, 9, 9]));
      Widget build() => MaterialApp(
        home: WImage.source(
          source: WImageSource.provider(provider),
          style: const WImageStyle(width: 10, height: 10),
        ),
      );

      await tester.pumpWidget(build());
      final first = tester.widget<Image>(find.byType(Image)).image;
      await tester.pumpWidget(build());
      final second = tester.widget<Image>(find.byType(Image)).image;
      expect(identical(first, second), isTrue);
    });

    testWidgets('160x90 的可重试错误优先显示重试按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([1, 2, 3]))),
            style: const WImageStyle(width: 160, height: 90),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WImageErrorView), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('100x100 错误视图显示文案但不显示按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.parse('data:image/png;base64,@@bad@@'),
            style: const WImageStyle(width: 100, height: 100),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      );
      await tester.pump();
      final view = tester.widget<WImageErrorView>(find.byType(WImageErrorView));
      expect(view.compact, isFalse);
      expect(find.text('Base64 解码失败'), findsOneWidget);
      expect(find.text('重试'), findsNothing);
    });

    testWidgets('provider 解码失败使用 WImageProviderError', (tester) async {
      WImageError? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([1, 2, 3]))),
            style: const WImageStyle(width: 64, height: 64),
            onLoadStatusChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      // 通过 errorWidgetBuilder 捕获更直接
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([4, 5, 6]))),
            style: const WImageStyle(width: 64, height: 64),
            slots: WImageSlots(
              errorWidgetBuilder: (context, url, error) {
                captured = error;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(captured?.kind, WImageErrorKind.provider);
    });

    test('命名构造带显式类型', () {
      expect(WImage.source(source: WImageSource.asset('a.png')).source.type, WImageType.asset);
      expect(
        WImage.source(source: WImageSource.network('https://x/y.png')).source.type,
        WImageType.network,
      );
      expect(WImage.source(source: WImageSource.file('/tmp/a.png')).source.type, WImageType.file);
      expect(WImage.source(source: WImageSource.base64('AAAA')).source.type, WImageType.base64);
    });
  });

  group('WImage 回归', () {
    testWidgets('fitContain() 应使用 BoxFit.contain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.asset('no_such_asset_for_test.png'),
            style: const WImageStyle(fit: BoxFit.contain),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('Base64 解码失败时应渲染 errorWidget 并回调 failed', (tester) async {
      WImageLoadStatus? status;
      Object? capturedError;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: WImage.source(
              source: WImageSource.parse('data:image/png;base64,@@invalid@@'),
              slots: WImageSlots(
                errorWidgetBuilder: (context, url, error) {
                  capturedError = error;
                  return const Text('base64-error');
                },
              ),
              onLoadStatusChanged: (s) => status = s,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      // 触发一次重建（拿到错误快照）并执行 post-frame 回调
      await tester.pump();
      await tester.pump();

      expect(find.text('base64-error'), findsOneWidget);
      expect(status, WImageLoadStatus.failed);
      expect((capturedError as WImageError?)?.kind, WImageErrorKind.decode);
    });

    testWidgets('父级重建不会重复通知同一加载状态', (tester) async {
      final statuses = <WImageLoadStatus>[];

      Widget build() => MaterialApp(
        home: WImage.source(
          source: WImageSource.parse('data:image/png;base64,@@invalid@@'),
          slots: const WImageSlots(errorWidget: Text('base64-error')),
          onLoadStatusChanged: statuses.add,
        ),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(build());
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump();

      // 同一 state 重建：Future 与状态均已缓存，不应再次通知 failed
      await tester.pumpWidget(build());
      await tester.pump();
      await tester.pump();

      expect(statuses.where((s) => s == WImageLoadStatus.failed).length, 1);
    });
  });

  group('WImageTheme', () {
    testWidgets('of 在无 scope 时返回默认配置，maybeOf 返回 null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(WImageTheme.maybeOf(context), isNull);
              expect(WImageTheme.of(context), isA<WImageSlots>());
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('WImage 尺寸提示（debug）', () {
    testWidgets('无尺寸且父级在高度方向无界 → 提示', (tester) async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  WImage.source(source: WImageSource.network('https://example.com/a.png')),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          logs.any((line) => line.contains('WImage 在')),
          isTrue,
          reason: '应提示加载前 0 尺寸会导致空白',
        );
      } finally {
        debugPrint = original;
      }
    });

    testWidgets('有界父级不提示', (tester) async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                height: 100,
                child: WImage.source(source: WImageSource.network('https://example.com/a.png')),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          logs.any((line) => line.contains('WImage 在')),
          isFalse,
        );
      } finally {
        debugPrint = original;
      }
    });

    testWidgets('有 aspectRatio 时不提示', (tester) async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  WImage.source(
                    source: WImageSource.network('https://example.com/a.png'),
                    style: const WImageStyle(aspectRatio: 16 / 9),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          logs.any((line) => line.contains('WImage 在')),
          isFalse,
        );
      } finally {
        debugPrint = original;
      }
    });
  });
  group('WImage 选项命名', () {
    testWidgets('WImage.source 接受 options:', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.source(
            source: WImageSource.network('https://example.com/a.png'),
            options: const WImageLoadOptions(retryCount: 1, memCacheWidth: 120),
          ),
        ),
      );
      final image = tester.widget<WImage>(find.byType(WImage));
      expect(image.options.retryCount, 1);
      expect(image.options.memCacheWidth, 120);
    });
  });

  testWidgets('同一 controller 绑定第二张图时报错且保留第一张', (tester) async {
    final controller = WImageController();
    addTearDown(controller.dispose);
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              WImage.source(
                source: WImageSource.network('https://example.com/a.png'),
                controller: controller,
              ),
              WImage.source(
                source: WImageSource.network('https://example.com/b.png'),
                controller: controller,
              ),
            ],
          ),
        ),
      );
      expect(errors, isNotEmpty);
      expect(controller.isAttached, isTrue);
    } finally {
      FlutterError.onError = original;
    }
  });
}
