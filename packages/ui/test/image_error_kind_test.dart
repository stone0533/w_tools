// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';
import 'package:w_tools_ui/src/components/common/image/image_config.dart';

void main() {
  test('错误子类映射到 WImageErrorKind', () {
    expect(const WImageEmptyError('x').kind, WImageErrorKind.empty);
    expect(const WImageNetworkError('x', null).kind, WImageErrorKind.network);
    expect(const WImageAssetError('x', null).kind, WImageErrorKind.asset);
    expect(const WImageDecodeError('x', null).kind, WImageErrorKind.decode);
    expect(const WImageProviderError('x', null).kind, WImageErrorKind.provider);
    expect(const WImageFileError('x', null).kind, WImageErrorKind.file);
    expect(const WImageUnsupportedError('x', 'Web').kind, WImageErrorKind.unsupported);
  });

  test('WImageConfig 是 WImageLoadConfig 的弃用别名', () {
    const WImageConfig legacy = WImageLoadConfig(retryCount: 2);
    expect(legacy.retryCount, 2);
  });
}
