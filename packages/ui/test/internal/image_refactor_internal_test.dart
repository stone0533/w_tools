import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_provider_factory.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui/src/components/common/image/image_slots_build.dart';

void main() {
  test('createNetworkImageProvider 保留 headers / cacheKey / 解码尺寸', () {
    final provider = createNetworkImageProvider(
      const WNetworkImageSource(
        'https://example.com/a.png',
        headers: {'X': '1'},
        cacheKey: 'k',
      ),
      const WImageLoadOptions(memCacheWidth: 120, memCacheHeight: 90),
    );
    expect(provider, isA<CachedNetworkImageProvider>());
    final cached = provider as CachedNetworkImageProvider;
    expect(cached.maxWidth, 120);
    expect(cached.maxHeight, 90);
  });

  test('createAssetImageProvider 使用 asset 名称与 package', () {
    final provider = createAssetImageProvider(
      const WAssetImageSource('logo.png', package: 'pkg'),
    );
    expect(provider, isA<AssetImage>());
    final asset = provider as AssetImage;
    expect(asset.assetName, 'logo.png');
    expect(asset.package, 'pkg');
  });
  test('sizedImageSlot 只在配置宽高时包 SizedBox', () {
    const style = WImageStyle(width: 10, height: 20);
    final sized = sizedImageSlot(style, const SizedBox.shrink());
    expect(sized, isA<SizedBox>());
    expect((sized as SizedBox).width, 10);
    expect(sized.height, 20);

    const child = Text('x');
    expect(identical(sizedImageSlot(const WImageStyle(), child), child), isTrue);
  });

  test('buildImageErrorSlot 优先返回业务 errorWidget', () {
    final widget = buildImageErrorSlot(
      context: _FakeBuildContext(),
      slots: WImageSlots(
        errorWidgetBuilder: (context, data, error, retry) => const Text('custom'),
      ),
      style: const WImageStyle(),
      error: const WImageError('x', WImageErrorKind.network),
      onRetry: () {},
    );
    expect(widget, isA<Text>());
  });
  testWidgets('WImageErrorView 小尺寸只保留图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: WImageErrorView(
              error: const WImageError('x', WImageErrorKind.network),
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('WImageErrorView 大尺寸显示文案与重试', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: WImageErrorView(
              error: const WImageError('x', WImageErrorKind.network),
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Network'), findsOneWidget);
  });

  testWidgets('WImageErrorView 中文 Locale 使用中文文案', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('zh'),
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: WImageErrorView(
                  error: const WImageError('x', WImageErrorKind.network),
                  onRetry: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('网络图片加载失败'), findsOneWidget);
  });
}

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
