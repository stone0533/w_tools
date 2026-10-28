import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image.dart';

/// 空数据 / 类型判定 / 显式构造 / 解码尺寸 / 布局 / 语义 的回归测试。
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump();
  await tester.pump();
}

/// 剥开 ResizeImage 拿到真正的 provider
ImageProvider _unwrap(ImageProvider provider) {
  return provider is ResizeImage ? provider.imageProvider : provider;
}

void main() {
  late Directory tmpDir;
  late File pngFile;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // 真实文件 IO 必须在测试的 fake-async 区域之外创建
    tmpDir = await Directory.systemTemp.createTemp('wimage_test');
    pngFile = File('${tmpDir.path}/pixel.png');
    await pngFile.writeAsBytes(base64Decode(_pngBase64));
  });

  tearDownAll(() async {
    await tmpDir.delete(recursive: true);
  });

  group('WImage 空 data 防护', () {
    testWidgets("data = '' 不构建任何 Image（否则会 Image.asset('') 报错）", (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WImage(data: ''))),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byType(CachedNetworkImage), findsNothing);
      // 默认错误占位是灰底 + error 图标
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('纯空白同样视为没有图', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WImage(data: '   '))),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('错误对象携带传给 WImage 的原始 data（未 trim）', (tester) async {
      WImageError? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: WImage(
            data: '   ',
            config: WImageConfig()
              ..errorWidgetBuilder = (context, url, error) {
                captured = error;
                return const SizedBox.shrink();
              },
          ),
        ),
      );
      await tester.pump();

      expect(captured, isA<WImageEmptyError>());
      expect(captured!.data, '   ');
    });

    testWidgets('空数据回调的是类型化错误', (tester) async {
      Object? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: WImage(
            data: '',
            config: WImageConfig()
              ..errorWidgetBuilder = (context, url, error) {
                captured = error;
                return const Text('custom-error');
              },
          ),
        ),
      );
      await tester.pump();

      expect(captured, isA<WImageEmptyError>());
      expect(find.text('custom-error'), findsOneWidget);
    });
  });

  group('WImage 类型判定', () {
    Future<void> expectNetwork(WidgetTester tester, String data) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WImage(data: data))),
      );
      expect(
        find.byType(CachedNetworkImage),
        findsOneWidget,
        reason: '$data 应判定为网络图片',
      );
    }

    testWidgets('大写 scheme / 前导空格 / 协议相对地址都算网络图', (tester) async {
      await expectNetwork(tester, 'HTTPS://cdn.example.com/a.png');
      await expectNetwork(tester, '  https://cdn.example.com/a.png  ');
      await expectNetwork(tester, '//cdn.example.com/a.png');
    });

    testWidgets('协议相对地址会补 https，而不是把 // 原样丢给网络层', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WImage(data: '//cdn.example.com/a.png')),
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://cdn.example.com/a.png');
    });

    testWidgets('data: 前缀（非 image/）按 base64 处理并能真正解码', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage(
              data: 'data:application/octet-stream;base64,$_pngBase64',
            ),
          ),
        ),
      );
      await _settle(tester);

      // 判定为 base64 且解码成功：渲染 Image，而不是错误占位
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('asset 路径前后的空白会被裁掉', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WImage.asset('  assets/images/logo.png  ')),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final provider = _unwrap(image.image);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/images/logo.png');
    });
  });

  group('WImage 显式构造', () {
    testWidgets('WImage.asset 不会被 http 前缀带跑偏', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WImage.asset('https://cdn.example.com/a.png')),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      final image = tester.widget<Image>(find.byType(Image));
      expect(_unwrap(image.image), isA<AssetImage>());
    });

    testWidgets('WImage.base64 接受不带 data: 前缀的裸串', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WImage.base64(_pngBase64)),
        ),
      );
      await _settle(tester);

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('WImage.file 读取真实文件', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WImage.file(pngFile.path))),
      );
      await _settle(tester);

      final image = tester.widget<Image>(find.byType(Image));
      expect(_unwrap(image.image), isA<FileImage>());
    });
  });

  group('WImage 解码尺寸', () {
    testWidgets('memCacheWidth / memCacheHeight 透传给 CachedNetworkImage', (tester) async {
      final config = WImageConfig()
        ..memCacheWidth = 240
        ..memCacheHeight = 240;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage(
              config: config,
              data: 'https://cdn.example.com/a.png',
            ),
          ),
        ),
      );

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, 240);
      expect(image.memCacheHeight, 240);
    });

    testWidgets('asset 的 memCache 会变成 ResizeImage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage.asset(
              'assets/images/logo.png',
              config: WImageConfig()..memCacheWidth = 120,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, 120);
    });
  });

  group('WImage 变换', () {
    testWidgets('borderRadius 同时作用于 border', (tester) async {
      const radius = BorderRadius.all(Radius.circular(8));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage(
              data: 'data:image/png;base64,$_pngBase64',
              config: WImageConfig()
                ..width = 10
                ..height = 10
                ..borderRadius = radius
                ..border = Border.all(),
            ),
          ),
        ),
      );
      await _settle(tester);

      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null)
          .toList();
      expect(decorations, isNotEmpty);
      expect(decorations.first.borderRadius, radius);
    });

    testWidgets('padding 在 width/height 之外（当前语义）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage(
              data: 'data:image/png;base64,$_pngBase64',
              config: WImageConfig()
                ..width = 10
                ..height = 10
                ..padding = const EdgeInsets.all(5),
            ),
          ),
        ),
      );
      await _settle(tester);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 10);
      expect(image.height, 10);
      expect(tester.getSize(find.byType(WImage)), const Size(20, 20));
    });
  });

  group('WImage 布局与语义', () {
    testWidgets('aspectRatio 让加载前后的尺寸稳定', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: WImage.asset(
                'assets/images/logo.png',
                config: WImageConfig()..aspectRatio = 2,
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(WImage)), const Size(200, 100));
    });

    testWidgets('semanticLabel / excludeFromSemantics 透传给 Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WImage.asset(
              'assets/images/logo.png',
              config: WImageConfig()
                ..semanticLabel = '门店照片'
                ..excludeFromSemantics = true,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.semanticLabel, '门店照片');
      expect(image.excludeFromSemantics, isTrue);
    });
  });

  group('WImageConfig 可读', () {
    test('所有配置都能读回', () {
      final config = WImageConfig()
        ..width = 10
        ..height = 20
        ..fit = BoxFit.contain
        ..memCacheWidth = 30
        ..memCacheHeight = 40
        ..retryCount = 2
        ..retryDelay = 300
        ..aspectRatio = 1.5
        ..semanticLabel = 'label'
        ..gaplessPlayback = true
        ..filterQuality = FilterQuality.high
        ..httpHeaders = const {'Authorization': 'Bearer x'}
        ..cacheKey = 'k';

      expect(config.width, 10);
      expect(config.height, 20);
      expect(config.fit, BoxFit.contain);
      expect(config.memCacheWidth, 30);
      expect(config.memCacheHeight, 40);
      expect(config.retryCount, 2);
      expect(config.retryDelay, 300);
      expect(config.aspectRatio, 1.5);
      expect(config.semanticLabel, 'label');
      expect(config.gaplessPlayback, isTrue);
      expect(config.filterQuality, FilterQuality.high);
      expect(config.httpHeaders, {'Authorization': 'Bearer x'});
      expect(config.cacheKey, 'k');
    });

    test('WImageProgress.fraction 处理未知总大小', () {
      expect(const WImageProgress().fraction, isNull);
      expect(
        const WImageProgress(downloadedBytes: 5, totalBytes: 10).fraction,
        0.5,
      );
      // 超出总大小时被夹到 1.0
      expect(
        const WImageProgress(downloadedBytes: 20, totalBytes: 10).fraction,
        1.0,
      );
    });
  });
}
