import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('来源工厂', () {
    test('每个工厂返回对应类型', () {
      expect(WImageSource.network('https://a.com/x.png').type, WImageType.network);
      expect(WImageSource.asset('assets/x.png').type, WImageType.asset);
      expect(WImageSource.file('/tmp/x.png').type, WImageType.file);
      expect(WImageSource.base64('AAAA').type, WImageType.base64);
      expect(
        WImageSource.provider(MemoryImage(Uint8List.fromList([1]))).type,
        WImageType.provider,
      );
    });

    test('网络来源保留原始值，协议相对地址补 https', () {
      final source = WImageSource.network('  //cdn.a.com/x.png  ');
      expect(source.raw, '  //cdn.a.com/x.png  ');
      expect(source.value, 'https://cdn.a.com/x.png');
    });
  });

  group('来源细节', () {
    test('file:// 转文件路径', () {
      expect(WImageSource.file('file:///tmp/x.png').value, '/tmp/x.png');
    });

    test('file: 前缀大小写不敏感', () {
      final file = WImageSource.file('FILE:///tmp/x.png');
      expect(file.type, WImageType.file);
      expect(file.value, '/tmp/x.png');
    });

    test('base64 的 data: 前缀被剥离（不限于 image/）', () {
      final source = WImageSource.base64('data:application/octet-stream;base64,AAA');
      expect(source.value, 'AAA');
    });

    test('asset 直接使用完整路径', () {
      expect(WImageSource.asset('assets/images/logo.png').value, 'assets/images/logo.png');
    });

    test('相等性按内容而不是实例', () {
      expect(
        WImageSource.network('https://a.com/x.png'),
        WImageSource.network('https://a.com/x.png'),
      );
      expect(WImageSource.asset('a.png'), isNot(WImageSource.asset('b.png')));
      expect(WImageSource.base64('AAAA'), WImageSource.base64('AAAA'));
    });
  });

  test('resolve 大 Base64 与 WImage 使用同一解码结果', () async {
    final raw = base64Encode(List<int>.filled(150 * 1024, 7));
    final provider = await WImageSource.base64(raw).resolve(memCacheWidth: 64);
    expect(provider, isA<ResizeImage>());
  });
}
