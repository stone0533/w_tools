import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  group('WImageProgress.fraction', () {
    test('正常值按比例并 clamp', () {
      expect(const WImageProgress(downloadedBytes: 50, totalBytes: 100).fraction, 0.5);
      expect(const WImageProgress(downloadedBytes: 150, totalBytes: 100).fraction, 1.0);
      expect(const WImageProgress(totalBytes: 100).fraction, 0.0);
    });

    test('总大小未知 / 非法时返回 null', () {
      expect(const WImageProgress(downloadedBytes: 10).fraction, isNull);
      expect(const WImageProgress(downloadedBytes: 10, totalBytes: 0).fraction, isNull);
      expect(const WImageProgress(downloadedBytes: 10, totalBytes: -1).fraction, isNull);
    });

    test('相等性与 toString', () {
      const a = WImageProgress(downloadedBytes: 1, totalBytes: 2);
      const b = WImageProgress(downloadedBytes: 1, totalBytes: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('1'));
    });
  });

  group('WImageError.message', () {
    const expected = {
      WImageErrorKind.empty: '图片数据为空',
      WImageErrorKind.network: '网络图片加载失败',
      WImageErrorKind.asset: '本地资源加载失败',
      WImageErrorKind.decode: 'Base64 解码失败',
      WImageErrorKind.provider: '图片解码失败',
      WImageErrorKind.file: '本地文件读取失败',
      WImageErrorKind.unsupported: '当前平台不支持该图片源',
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} → ${entry.value}', () {
        final error = WImageError('raw', entry.key);
        expect(error.message, entry.value);
        expect(error.toString(), contains('raw'));
      });
    }
  });

  group('WImageLoadSnapshot', () {
    test('相等性 / hashCode / toString', () {
      const a = WImageLoadSnapshot(
        status: WImageLoadStatus.loading,
        attempt: 1,
        retryScheduled: true,
        retryDelayMs: 200,
      );
      const b = WImageLoadSnapshot(
        status: WImageLoadStatus.loading,
        attempt: 1,
        retryScheduled: true,
        retryDelayMs: 200,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isLoading, isTrue);
      expect(a.isCompleted, isFalse);
      expect(a.isFailed, isFalse);
      expect(a.toString(), contains('loading'));
    });
  });
}
