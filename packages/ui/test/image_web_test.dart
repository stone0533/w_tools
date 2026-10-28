import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/_image_file_web.dart' as web;
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

void main() {
  test('Web 平台的文件 provider 返回 null（由 WImage 渲染 unsupported）', () {
    expect(web.buildFileImageProvider('/tmp/a.png'), isNull);
  });

  test('WImageUnsupportedError 暴露 platform 与可读消息', () {
    const error = WImageUnsupportedError('file:///tmp/a.png', 'file://');
    expect(error.platform, 'file://');
    expect(error.message, contains('file://'));
    expect(error.toString(), contains('file:///tmp/a.png'));
  });
}
