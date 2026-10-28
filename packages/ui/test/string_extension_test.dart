import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WImageConfig.copy', () {
    test('复制全部字段，引用类型共享', () {
      final headers = <String, String>{'Authorization': 'x'};
      final config = WImageConfig()
        ..width = 10
        ..height = 20
        ..fit = BoxFit.contain
        ..memCacheWidth = 100
        ..memCacheHeight = 200
        ..retryCount = 2
        ..retryDelay = 500
        ..aspectRatio = 1.5
        ..semanticLabel = '头像'
        ..excludeFromSemantics = true
        ..gaplessPlayback = true
        ..filterQuality = FilterQuality.high
        ..alignment = Alignment.topCenter
        ..httpHeaders = headers
        ..cacheKey = 'k';

      final copy = config.copy();
      expect(copy.width, 10);
      expect(copy.height, 20);
      expect(copy.fit, BoxFit.contain);
      expect(copy.memCacheWidth, 100);
      expect(copy.memCacheHeight, 200);
      expect(copy.retryCount, 2);
      expect(copy.retryDelay, 500);
      expect(copy.aspectRatio, 1.5);
      expect(copy.semanticLabel, '头像');
      expect(copy.excludeFromSemantics, isTrue);
      expect(copy.gaplessPlayback, isTrue);
      expect(copy.filterQuality, FilterQuality.high);
      expect(copy.alignment, Alignment.topCenter);
      expect(copy.httpHeaders, same(headers));
      expect(copy.cacheKey, 'k');
    });
  });

  group('toImage', () {
    test('size 只作为 fallback，显式 width/height 优先', () {
      final onlySize = 'x'.toImage(size: 20);
      expect(onlySize.config.width, 20);
      expect(onlySize.config.height, 20);

      final both = 'x'.toImage(size: 20, width: 100, height: 50);
      expect(both.config.width, 100);
      expect(both.config.height, 50);

      final half = 'x'.toImage(size: 20, width: 100);
      expect(half.config.width, 100);
      expect(half.config.height, 20);
    });

    test('fit / semanticLabel 覆盖配置', () {
      final w = 'x'.toImage(fit: BoxFit.contain, semanticLabel: '头像');
      expect(w.config.fit, BoxFit.contain);
      expect(w.config.semanticLabel, '头像');
    });

    test('传入的 config 不会被修改', () {
      final base = WImageConfig()
        ..width = 10
        ..height = 10
        ..borderRadius = BorderRadius.circular(8);
      final w = 'x'.toImage(config: base, width: 30);
      expect(base.width, 10);
      expect(w.config.width, 30);
      expect(w.config.height, 10);
      expect(w.config.borderRadius, same(base.borderRadius));
    });

    test('type 透传，不传则保持自动判定', () {
      expect('x'.toImage(type: WImageType.base64).type, WImageType.base64);
      expect('x'.toImage().type, isNull);
    });

    test('key / controller / 回调透传', () {
      const key = Key('image');
      final controller = WImageController();
      void onStatus(WImageLoadStatus _) {}
      void onProgress(WImageProgress _) {}

      final w = 'x'.toImage(
        key: key,
        controller: controller,
        onLoadStatusChanged: onStatus,
        onProgress: onProgress,
      );
      expect(w.key, key);
      expect(w.controller, same(controller));
      expect(w.onLoadStatusChanged, same(onStatus));
      expect(w.onProgress, same(onProgress));
    });

    test('空串不抛异常，交给 WImage 处理', () {
      expect(''.toImage().data, '');
    });
  });

  group('命名便捷方法', () {
    test('toAssetImage 默认拼 WAssets.imagePath', () {
      final w = 'logo.png'.toAssetImage();
      expect(w.data, 'assets/images/logo.png');
      expect(w.type, WImageType.asset);
    });

    test('toAssetImage(prefix: false) 使用完整路径', () {
      final w = 'assets/icons/logo.png'.toAssetImage(prefix: false);
      expect(w.data, 'assets/icons/logo.png');
      expect(w.type, WImageType.asset);
    });

    test('toBase64Image / toFileImage / toNetworkImage 强制类型', () {
      expect('iVBORw0KG'.toBase64Image().type, WImageType.base64);
      expect('/tmp/a.png'.toFileImage().type, WImageType.file);
      expect('https://a.com/a.png'.toNetworkImage().type, WImageType.network);
    });
  });
}
