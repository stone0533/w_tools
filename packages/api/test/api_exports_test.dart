import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  test('barrel 重导出公开 API 里用到的 dio 类型', () {
    final options = BaseOptions(connectTimeout: const Duration(seconds: 1));
    final dio = Dio(options);
    expect(dio.options.connectTimeout, const Duration(seconds: 1));

    final exception = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
    expect(exception.type, DioExceptionType.connectionError);
  });
}
