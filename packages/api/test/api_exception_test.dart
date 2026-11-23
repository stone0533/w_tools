import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  RequestOptions request() => RequestOptions(path: '/x');

  test('connectionError 映射成 network', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.connectionError,
    );

    final exception = WApiException.from(error);

    expect(exception.kind, WApiErrorKind.network);
    expect(exception.statusCode, isNull);
    expect(exception.cause, same(error));
  });

  test('badCertificate 映射成 network', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.badCertificate,
    );

    final exception = WApiException.from(error);

    expect(exception.kind, WApiErrorKind.network);
    expect(exception.statusCode, isNull);
  });

  test('没有响应的 unknown 保持 unknown', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.unknown,
      message: 'boom',
    );

    final exception = WApiException.from(error);

    expect(exception.kind, WApiErrorKind.unknown);
    expect(exception.statusCode, isNull);
    expect(exception.message, 'boom');
  });
}
