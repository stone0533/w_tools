import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_source.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';
import 'package:w_tools_ui/src/utils/assets.dart';

void main() {
  group('WImageSource.parse', () {
    test('识别四种来源', () {
      expect(WImageSource.parse('https://a.com/x.png'), isA<WNetworkImageSource>());
      expect(WImageSource.parse('//cdn.a.com/x.png'), isA<WNetworkImageSource>());
      expect(WImageSource.parse('file:///tmp/x.png'), isA<WFileImageSource>());
      expect(WImageSource.parse('data:image/png;base64,AAAA'), isA<WBase64ImageSource>());
      expect(WImageSource.parse('assets/x.png'), isA<WAssetImageSource>());
    });

    test('保留原始值，同时提供规范化值', () {
      final source = WImageSource.parse('  //cdn.a.com/x.png  ');
      expect(source.raw, '  //cdn.a.com/x.png  ');
      expect(source.value, 'https://cdn.a.com/x.png');
      expect(source.type, WImageType.network);
    });
  });

  group('来源细节', () {
    test('file:// 转文件路径', () {
      expect(WImageSource.file('file:///tmp/x.png').value, '/tmp/x.png');
    });

    test('data: 前缀被剥离（不限于 image/）', () {
      final source = WImageSource.base64('data:application/octet-stream;base64,AAA');
      expect(source.value, 'AAA');
    });

    test('asset prefix 使用 WAssets.imagePath', () {
      final old = WAssets.imagePath;
      addTearDown(() => WAssets.imagePath = old);
      WAssets.imagePath = 'images/';
      expect(WImageSource.asset('logo.png', prefix: true).value, 'images/logo.png');
    });

    test('相等性按内容而不是实例', () {
      expect(
          WImageSource.network('https://a.com/x.png'), WImageSource.network('https://a.com/x.png'));
      expect(WImageSource.asset('a.png'), isNot(WImageSource.asset('b.png')));
      expect(WImageSource.base64('AAAA'), WImageSource.base64('AAAA'));
    });
  });
}
