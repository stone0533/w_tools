/// 业务信封解析器。
///
/// 很多后端返回 `{code, message, data}`；`WApiClient` 默认不假设信封，
/// 传 [WApiEnvelopeParser] 后才启用：
///
/// ```dart
/// final client = WApiClient(
///   registry.dio,
///   envelope: WApiEnvelopeParser(
///     readCode: (json) => (json as Map)['code'],
///     readData: (json) => (json as Map)['data'],
///     readMessage: (json) => (json as Map)['message'] as String?,
///     isSuccess: (code) => code == 0 || code == 200,
///   ),
/// );
/// ```
///
/// 业务码失败会抛 `WApiException(kind: WApiErrorKind.business)`，
/// 带上 [WApiException.businessCode] 和原始 [WApiException.payload]。
///
/// 无响应体（204 / 空 body）不会自动绕过信封：`readCode(null)` 必须自己返回
/// 成功码，或把这类请求的 `decode` 设为 `WApiDecoders.none` 并确保 `readCode`
/// 对 null 安全。
class WApiEnvelopeParser {
  /// 创建解析器。
  const WApiEnvelopeParser({
    required this.readCode,
    required this.readData,
    required this.isSuccess,
    this.readMessage,
    this.authFailureCodes = const {},
  });

  /// 读取业务码
  final Object? Function(Object? json) readCode;

  /// 读取业务数据（成功时传给 `decode`）
  final Object? Function(Object? json) readData;

  /// 业务码是否表示成功
  final bool Function(Object? code) isSuccess;

  /// 读取业务提示信息（可选）
  final String? Function(Object? json)? readMessage;

  /// 视为「登录失效」的业务码。
  ///
  /// 命中时 `WApiClient` 抛 `WApiException(kind: unauthorized)` 并调用
  /// `WApiClient.onAuthFailure`，与 HTTP 401 走同一条登出链路。
  final Set<Object?> authFailureCodes;
}
