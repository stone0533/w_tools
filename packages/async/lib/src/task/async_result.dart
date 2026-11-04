/// 异步执行结果。
///
/// 显式区分成功、失败与取消，避免用 `null` 同时表示三种语义。
sealed class WAsyncResult<T> {
  const WAsyncResult();

  /// 是否成功。
  bool get isSuccess => this is WAsyncSuccess<T>;

  /// 是否失败。
  bool get isFailure => this is WAsyncFailure<T>;

  /// 是否被取消。
  bool get isCancelled => this is WAsyncCancelled<T>;
}

/// 执行成功。
final class WAsyncSuccess<T> extends WAsyncResult<T> {
  const WAsyncSuccess(this.value);

  final T value;
}

/// 执行失败。
final class WAsyncFailure<T> extends WAsyncResult<T> {
  const WAsyncFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  /// 是否为编程错误（`Error`，如 TypeError / StateError）。
  bool get isProgrammingError => error is Error;
}

/// 执行被取消（协作式取消，不代表底层 Future 已中止）。
final class WAsyncCancelled<T> extends WAsyncResult<T> {
  const WAsyncCancelled([this.reason]);

  final Object? reason;
}
