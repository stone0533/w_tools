import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/_image_file_web.dart' as web;
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  test('Web 平台的文件 provider 返回 null（由 WImage 渲染 unsupported）', () {
    expect(web.buildFileImageProvider('/tmp/a.png'), isNull);
  });

  test('unsupported 错误带可读消息', () {
    const error = WImageError('file:///tmp/a.png', WImageErrorKind.unsupported);
    expect(error.message, contains('当前平台不支持'));
    expect(error.toString(), contains('file:///tmp/a.png'));
  });
}
