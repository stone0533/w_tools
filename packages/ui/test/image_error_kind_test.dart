import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  test('WImageError 用 kind 区分分类与文案', () {
    expect(const WImageError('x', WImageErrorKind.empty).kind, WImageErrorKind.empty);
    expect(const WImageError('x', WImageErrorKind.network).message, '网络图片加载失败');
    expect(const WImageError('x', WImageErrorKind.asset).message, '本地资源加载失败');
    expect(const WImageError('x', WImageErrorKind.decode).message, 'Base64 解码失败');
    expect(const WImageError('x', WImageErrorKind.provider).message, '图片解码失败');
    expect(const WImageError('x', WImageErrorKind.file).message, '本地文件读取失败');
    expect(const WImageError('x', WImageErrorKind.unsupported).message, '当前平台不支持该图片源');
  });
}
