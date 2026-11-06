// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui/src/internal/image_loader.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump();
  await tester.pump();
}

Future<void> _settleUntilCompleted(WidgetTester tester, WImageController controller) async {
  for (var i = 0; i < 12 && !controller.state.value.isCompleted; i++) {
    await _settle(tester);
  }
  expect(
    controller.state.value.status,
    WImageLoadStatus.completed,
    reason: 'image did not finish loading: ${controller.state.value}',
  );
}

class _HangingProvider extends ImageProvider<_HangingProvider> {
  @override
  Future<_HangingProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_HangingProvider>(this);

  @override
  ImageStreamCompleter loadImage(_HangingProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: Completer<ui.Codec>().future,
      scale: 1,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class _ListenerHost extends StatefulWidget {
  const _ListenerHost({super.key});

  @override
  State<_ListenerHost> createState() => _ListenerHostState();
}

class _ListenerHostState extends State<_ListenerHost> {
  final WImageController controller = WImageController();
  WImageSource source = WImageSource.network('https://example.invalid/a.png');

  void setSource(WImageSource next) => setState(() => source = next);

  void rebuild() => setState(() {});

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: WImage.source(
          source: source,
          controller: controller,
          style: const WImageStyle(width: 100, height: 100),
        ),
      ),
    );
  }
}

int _green(Color color) => (color.g * 255).round();

Future<Color> _centerColor(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final x = image.width ~/ 2;
  final y = image.height ~/ 2;
  final index = (y * image.width + x) * 4;
  return Color.fromARGB(bytes[index + 3], bytes[index], bytes[index + 1], bytes[index + 2]);
}

void main() {
  test('WImageStyle 是值对象', () {
    expect(const WImageStyle(width: 10), WImageStyle(width: 10));
    expect(const WImageStyle(width: 10).hashCode, WImageStyle(width: 10).hashCode);
  });

  test('WImageController 创建后即可监听 idle 状态', () {
    final controller = WImageController();
    addTearDown(controller.dispose);
    expect(controller.state.value.isIdle, isTrue);
    expect(controller.state.value.attempt, 0);
  });

  testWidgets('border 绘制在图片之上', (tester) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      _wrap(
        Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: WImage.source(
              source: WImageSource.base64(_redPixel),
              style: const WImageStyle(
                width: 64,
                height: 64,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFF3949AB), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);

    final top = await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final index = (image.width ~/ 2) * 4;
      return bytes.sublist(index, index + 4);
    });
    // 顶部中心在边框上：应能看到蓝色（蓝通道显著高于红通道）。
    expect(
      top![2],
      greaterThan(top[0] + 20),
      reason: 'top edge rgba=$top',
    );
  });

  testWidgets('aspectRatio 作用于图片内容，padding 在外', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            SizedBox(
              width: 200,
              child: WImage.source(
                source: WImageSource.base64(_redPixel),
                style: const WImageStyle(
                  aspectRatio: 2,
                  padding: EdgeInsets.all(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final imageSize = tester.getSize(find.byType(Image));
    expect(imageSize.width / imageSize.height, closeTo(2, 0.01));
    expect(tester.getSize(find.byType(WImage)), const Size(200, 110));
  });

  testWidgets('gaplessPlayback 换 source 时保留上一帧', (tester) async {
    final boundaryKey = GlobalKey();
    final controller = WImageController();
    addTearDown(controller.dispose);
    Widget build(WImageSource source, {required bool gapless}) => _wrap(
      Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: WImage.source(
            source: source,
            controller: controller,
            options: WImageLoadOptions(gaplessPlayback: gapless),
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(WImageSource.base64(_redPixel), gapless: true));
    await _settleUntilCompleted(tester, controller);
    final before = await tester.runAsync(() => _centerColor(boundaryKey));
    expect(_green(before!), lessThan(120));

    await tester.pumpWidget(build(WImageSource.provider(_HangingProvider()), gapless: true));
    await tester.pump();
    final after = await tester.runAsync(() => _centerColor(boundaryKey));
    expect(_green(after!), lessThan(120), reason: 'gapless 应继续显示上一帧');
  });

  testWidgets('gaplessPlayback=false 时换 source 立即回到占位', (tester) async {
    final boundaryKey = GlobalKey();
    final controller = WImageController();
    addTearDown(controller.dispose);
    Widget build(WImageSource source) => _wrap(
      Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: WImage.source(
            source: source,
            controller: controller,
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(WImageSource.base64(_redPixel)));
    await _settleUntilCompleted(tester, controller);
    await tester.pumpWidget(build(WImageSource.provider(_HangingProvider())));
    await tester.pump();

    final after = await tester.runAsync(() => _centerColor(boundaryKey));
    expect(_green(after!), greaterThan(120), reason: '没有 gapless 时应回到主题占位色');
  });

  testWidgets('controller.state 在 build 期通知不会让外部 setState 崩溃', (tester) async {
    final hostKey = GlobalKey<_ListenerHostState>();
    await tester.pumpWidget(_ListenerHost(key: hostKey));
    final host = hostKey.currentState!;
    host.controller.state.addListener(() {
      if (host.mounted) host.rebuild();
    });

    host.setSource(WImageSource.network('https://example.invalid/b.png'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('尺寸提示对同一 State 只打印一次', (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      Widget build() => _wrap(
        Column(
          children: [
            WImage.source(
              source: WImageSource.network('https://example.invalid/a.png'),
              style: WImageStyle(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(build());
      await tester.pump();
      await tester.pumpWidget(build());
      await tester.pump();
      expect(logs.where((line) => line.contains('WImage 在')).length, 1);
    } finally {
      debugPrint = original;
    }
  });

  testWidgets('只有 width 时，高度无界也会提示', (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              WImage.source(
                source: WImageSource.network('https://example.invalid/a.png'),
                style: const WImageStyle(width: 100),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(logs.any((line) => line.contains('WImage 在')), isTrue);
    } finally {
      debugPrint = original;
    }
  });

  test('相同进度的重复上报只回调一次', () {
    final events = <WImageProgress>[];
    final loader = WImageLoader(
      retryCount: 0,
      retryDelay: 1000,
      onProgress: events.add,
    );
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    const progress = WImageProgress(downloadedBytes: 10, totalBytes: 100);
    loader.handleProgress(progress);
    loader.handleProgress(progress);
    expect(events.length, 1);
  });

  test('completed 进度不再伪造 1/1 字节', () {
    final loader = WImageLoader(retryCount: 0, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.reset(retryCount: 0, retryDelay: 1000);
    loader.handleCompleted(notifyProgress: true);
    final progress = loader.state.value.progress!;
    expect(progress.isComplete, isTrue);
    expect(progress.downloadedBytes, isNull);
    expect(progress.totalBytes, isNull);
    expect(progress.fraction, 1.0);
  });

  test('WImageSource.resolve 与 WImage 使用同一套 provider 规则', () async {
    final network = await WImageSource.network(
      'https://example.com/a.png',
      headers: const {'Authorization': 'Bearer x'},
      cacheKey: 'avatar',
    ).resolve(memCacheWidth: 240, memCacheHeight: 120);
    expect(network, isA<CachedNetworkImageProvider>());
    final cni = network as CachedNetworkImageProvider;
    expect(cni.headers, {'Authorization': 'Bearer x'});
    expect(cni.cacheKey, 'avatar');
    expect(cni.maxWidth, 240);
    expect(cni.maxHeight, 120);

    final asset = await WImageSource.asset('a.png').resolve(memCacheWidth: 10);
    expect(asset, isA<ResizeImage>());

    final base64Provider = await WImageSource.base64(_redPixel).resolve(memCacheWidth: 10);
    expect(base64Provider, isA<ResizeImage>());

    final provider = await WImageSource.provider(
      MemoryImage(Uint8List.fromList([1, 2, 3])),
    ).resolve(memCacheWidth: 10);
    expect(provider, isA<ResizeImage>());
  });

  testWidgets('单图 showRetryButton 优先于 WImageTheme 的错误 builder', (tester) async {
    await tester.pumpWidget(
      WImageTheme(
        slots: WImageSlots(
          errorWidgetBuilder: (context, data, error) => const Text('THEME_ERROR'),
        ),
        child: _wrap(
          WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([1, 2, 3]))),
            style: const WImageStyle(width: 160, height: 120),
            slots: const WImageSlots(showRetryButton: true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('THEME_ERROR'), findsNothing);
    expect(find.byType(WImageErrorView), findsOneWidget);
  });
}
