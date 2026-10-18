import 'dart:async';

// ============== 取消令牌 ==============

/// 协作式取消令牌
///
/// 传入 [WAsync] 各执行方法的 `cancelToken` 后，任务会在开始、结束以及
/// 重试等待等边界处检查取消状态。取消不会中止已经开始执行的 Future，
/// 只会让后续的检查点提前结束。
/// 令牌取消后不可复用：后续任务会在开始前直接返回 null。
class WCancelToken {
  /// 是否已取消
  bool _isCancelled = false;

  /// 取消原因，由 [cancel] 设置
  Object? _cancelReason;

  /// 取消回调集合
  ///
  /// [cancel] 触发后会统一清空，因此所有回调都只执行一次；
  /// 回调自身抛出的异常会被忽略。
  final Set<void Function(Object?)> _listeners = {};

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 取消原因；未取消时为 null
  Object? get cancelReason => _cancelReason;

  /// 添加取消回调
  ///
  /// 若令牌已取消，回调会立即以 [cancelReason] 调用，且不会被登记。
  void addListener(void Function(Object? reason) callback) {
    if (_isCancelled) {
      try {
        callback(_cancelReason);
      } catch (e) {
        // 回调异常不影响取消流程
      }
      return;
    }
    _listeners.add(callback);
  }

  /// 移除取消回调
  ///
  /// 移除未登记的监听不会报错。
  void removeListener(void Function(Object? reason) callback) {
    _listeners.remove(callback);
  }

  /// 取消操作，并通知所有监听
  ///
  /// 重复调用只会更新 [cancelReason]，不再触发回调（监听已在首次取消时清空）。
  void cancel([Object? reason]) {
    _isCancelled = true;
    _cancelReason = reason;
    // 遍历副本，允许回调内部增删监听
    for (final callback in _listeners.toList()) {
      try {
        callback(reason);
      } catch (e) {
        // 回调异常不影响取消流程
      }
    }
    _listeners.clear();
  }

  /// 若已取消则抛出 [WCancellationException]，否则不做任何事
  void throwIfCancelled() {
    if (_isCancelled) {
      throw WCancellationException(_cancelReason);
    }
  }

  /// 清空尚未触发的取消回调
  ///
  /// 不会重置 [isCancelled] / [cancelReason]。
  void clearListeners() {
    _listeners.clear();
  }
}

/// 取消异常
///
/// 由 [WCancelToken.throwIfCancelled] 抛出；[WAsync] 会将其视为正常结束，
/// 不回调 `onError`，并返回 null。
class WCancellationException implements Exception {
  /// 取消原因
  final Object? reason;

  /// 创建取消异常
  WCancellationException(this.reason);

  @override
  String toString() {
    return 'WCancellationException: $reason';
  }
}

// ============== 异步操作配置 ==============

/// 异步操作配置
///
/// 供 [WAsync] 各执行方法复用加载状态与错误回调配置。
/// 各执行方法的 `onSuccess` 未传时，即使操作成功也会返回 null；
/// 需要拿到结果时请显式传入 `onSuccess`。
/// [fallbackOnError] 仅在调用方法时未单独传 `onError` 的情况下生效。
/// 业务异常（`Exception`）会被上报并返回 null；编程错误（`Error`，如
/// `TypeError` / `StateError`）不会被拦截，会向上抛出。
class WAsyncConfig {
  /// 是否跟踪加载状态
  ///
  /// 为 true 时，执行期间会触发 [onLoadingStart] / [onLoadingEnd]；默认 true。
  bool showLoading;

  /// 开始执行时的回调（用于展示加载状态）
  ///
  /// 并发执行时仅在活动操作数 0→1 时触发一次。
  void Function()? onLoadingStart;

  /// 执行结束时的回调
  ///
  /// 并发执行时仅在全部操作结束（活动数 1→0）时触发一次。
  void Function()? onLoadingEnd;

  /// 兜底错误回调
  ///
  /// 仅在调用具体方法时未传 `onError` 的情况下才会被调用。
  void Function(Object? error)? fallbackOnError;

  /// 当前正在执行的操作数，用于合并并发操作的加载状态
  int _activeCount = 0;

  /// 标记一次操作开始：活动数 0→1 时触发 [onLoadingStart]
  void _beginLoading() {
    _activeCount++;
    if (_activeCount == 1) {
      try {
        onLoadingStart?.call();
      } catch (e) {
        // 加载回调异常不影响业务操作
      }
    }
  }

  /// 标记一次操作结束：活动数 1→0 时触发 [onLoadingEnd]
  void _endLoading() {
    if (_activeCount == 0) return;
    _activeCount--;
    if (_activeCount == 0) {
      try {
        onLoadingEnd?.call();
      } catch (e) {
        // 加载回调异常不影响业务操作
      }
    }
  }

  /// 创建异步操作配置
  WAsyncConfig({
    this.showLoading = true,
    this.onLoadingStart,
    this.onLoadingEnd,
    this.fallbackOnError,
  });

  /// 创建当前配置的副本
  ///
  /// 未指定的参数沿用当前值；传入 null 不会把回调清空，
  /// 如需清空请重新创建 [WAsyncConfig]。
  WAsyncConfig copyWith({
    bool? showLoading,
    void Function()? onLoadingStart,
    void Function()? onLoadingEnd,
    void Function(Object? error)? fallbackOnError,
  }) {
    return WAsyncConfig(
      showLoading: showLoading ?? this.showLoading,
      onLoadingStart: onLoadingStart ?? this.onLoadingStart,
      onLoadingEnd: onLoadingEnd ?? this.onLoadingEnd,
      fallbackOnError: fallbackOnError ?? this.fallbackOnError,
    );
  }

  /// 执行单个异步操作
  ///
  /// [task] 要执行的异步函数
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  Future<R?> run<T, R>(
    Future<T> Function() task, {
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.run<T, R>(
      task,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// [task] 要执行的异步函数
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  /// [retryCount] 首次执行失败后的最大重试次数（总执行次数为 retryCount + 1），不能为负数
  /// [retryDelay] 两次尝试之间的等待时间，等待期间可被 [cancelToken] 取消；不能为负数
  /// [retryIf] 判断某个异常是否重试；为空时重试所有 `Exception`，
  ///   返回 false 时立即结束并上报错误
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  Future<R?> runWithRetry<T, R>(
    Future<T> Function() task, {
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(Object error)? retryIf,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.runWithRetry<T, R>(
      task,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      retryCount: retryCount,
      retryDelay: retryDelay,
      retryIf: retryIf,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持超时
  ///
  /// 超时只会结束本次等待，[task] 返回的 Future 不会被取消，仍可能继续执行。
  ///
  /// [task] 要执行的异步函数
  /// [timeout] 超时时间
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或超时返回 null
  Future<R?> runWithTimeout<T, R>(
    Future<T> Function() task,
    Duration timeout, {
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.runWithTimeout<T, R>(
      task,
      timeout,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作（并行）
  ///
  /// 传入的 Future 在调用时已全部启动，本方法只负责等待结果；
  /// 需要限制并发数请使用 [runAllWithConcurrency]。
  /// 等待期间取消会立即返回 null，已启动的 Future 仍会继续执行。
  ///
  /// [futures] Future 列表
  /// [onSuccess] 成功回调，接收按输入顺序排列的所有结果
  /// [onError] 错误回调，接收错误信息
  /// [eagerError] 为 true 时任一 Future 失败立即结束；
  ///   为 false 时等待全部完成后再上报第一个错误
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  Future<R?> wait<T, R>(
    Iterable<Future<T>> futures, {
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.wait<T, R>(
      futures,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      eagerError: eagerError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作（并行，带并发控制）
  ///
  /// [tasks] 为异步任务工厂列表，只有并发槽位可用时才会调用，
  /// 因此能真正限制同时执行的任务数。
  /// [onSuccess] 成功回调，接收按任务顺序排列的所有结果
  /// [onError] 错误回调，接收错误信息
  /// [concurrency] 同时执行的最大任务数，必须大于 0
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  Future<R?> runAllWithConcurrency<T, R>(
    Iterable<Future<T> Function()> tasks, {
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.runAllWithConcurrency<T, R>(
      tasks,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      concurrency: concurrency,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作并返回第一个完成的结果
  ///
  /// 其余 Future 不会被取消，仍会继续执行。
  /// 等待期间取消会立即返回 null。
  ///
  /// [futures] Future 列表
  /// [onSuccess] 成功回调，接收最先完成的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果；空集合、失败或取消返回 null
  Future<R?> any<T, R>(
    Iterable<Future<T>> futures, {
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.any<T, R>(
      futures,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行多个异步操作
  ///
  /// 任一任务失败后立即停止，后续任务不再执行。
  ///
  /// [tasks] 异步函数列表
  /// [onSuccess] 成功回调，接收按顺序排列的所有结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  Future<R?> sequence<T, R>(
    Iterable<Future<T> Function()> tasks, {
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WAsync.sequence<T, R>(
      tasks,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }
}

// ============== 异步操作助手 ==============

/// 异步操作助手
///
/// 统一处理加载回调、错误回调与取消：业务异常（`Exception`）会被捕获，
/// 并通过方法参数 `onError` 或 [WAsyncConfig.fallbackOnError] 上报，
/// 方法返回 null，不向调用方抛出。
/// 编程错误（`Error`，如 `TypeError` / `StateError`）不属于业务异常，
/// 不会被拦截，会原样向上抛出。
/// 加载回调与错误回调自身抛出的异常会被忽略；`onSuccess` 抛出的 `Exception`
/// 按业务异常处理（上报错误并返回 null），抛出的 `Error` 同样向上抛出。
/// 取消是协作式的：[wait] / [any] 在等待期间收到取消会立即返回 null；
/// 正在执行的 Future 不会被中止，仍会继续运行。
/// 参数错误（如 `concurrency < 1`、负数的 `retryCount` / `retryDelay` /
/// `timeout`）会以失败的 Future 返回 [ArgumentError]。
class WAsync {
  // 纯静态工具类，禁止实例化
  WAsync._();

  /// 执行单个异步操作
  ///
  /// 任务开始前与结束后都会检查取消状态。
  ///
  /// [task] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  static Future<R?> run<T, R>(
    Future<T> Function() task, {
    WAsyncConfig? config,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await task();
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// 仅对 [task] 抛出的业务异常（`Exception`）重试，且可通过 [retryIf]
  /// 进一步过滤；重试次数用尽后交给统一的错误处理。
  /// [onSuccess] 抛出的异常不会触发重试。
  /// 取消与编程错误（`Error`）不重试，直接向上抛出。
  ///
  /// [task] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [retryCount] 首次执行失败后的最大重试次数（总执行次数为 retryCount + 1），不能为负数
  /// [retryDelay] 两次尝试之间的等待时间，等待期间可被 [cancelToken] 取消
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  static Future<R?> runWithRetry<T, R>(
    Future<T> Function() task, {
    WAsyncConfig? config,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(Object error)? retryIf,
    WCancelToken? cancelToken,
  }) async {
    if (retryCount < 0) {
      throw ArgumentError.value(retryCount, 'retryCount', '重试次数不能为负数');
    }
    if (retryDelay.isNegative) {
      throw ArgumentError.value(retryDelay, 'retryDelay', '重试间隔不能为负数');
    }

    int attempt = 0;

    return _executeWithLoading<R?>(
      config,
      () async {
        late T result;
        while (true) {
          try {
            cancelToken?.throwIfCancelled();
            attempt++;
            result = await task();
            break;
          } catch (e) {
            // 取消与编程错误（Error）不重试，直接向上抛出
            if (e is WCancellationException || e is Error) {
              rethrow;
            }
            if (attempt <= retryCount && (retryIf?.call(e) ?? true)) {
              await _cancelableDelay(retryDelay, cancelToken);
              continue;
            }
            // 此处不直接调用 onError：最终失败统一由 _executeWithLoading 上报，
            // 保证每次最终失败只回调一次（在此调用会重复上报）。
            rethrow;
          }
        }

        cancelToken?.throwIfCancelled();
        // onSuccess 的异常不触发重试，交由统一错误处理上报
        return onSuccess?.call(result);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持超时
  ///
  /// 超时只会结束本次等待，[task] 返回的 Future 不会被取消，仍可能继续执行；
  /// 超时以 [TimeoutException] 上报给 `onError`。
  ///
  /// [task] 要执行的异步函数
  /// [timeout] 超时时间
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或超时返回 null
  static Future<R?> runWithTimeout<T, R>(
    Future<T> Function() task,
    Duration timeout, {
    WAsyncConfig? config,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    if (timeout.isNegative) {
      throw ArgumentError.value(timeout, 'timeout', '超时时间不能为负数');
    }

    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await task().timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Operation timed out'),
        );
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作（并行）
  ///
  /// 传入的 Future 在调用时已全部启动，本方法只负责等待结果；
  /// 需要限制并发数请使用 [runAllWithConcurrency]。
  /// 等待期间取消会立即返回 null，已启动的 Future 仍会继续执行。
  ///
  /// [futures] Future 列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收按输入顺序排列的所有结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [eagerError] 为 true 时任一 Future 失败立即结束；
  ///   为 false 时等待全部完成后再上报第一个错误
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  static Future<R?> wait<T, R>(
    Iterable<Future<T>> futures, {
    WAsyncConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final waitFuture = Future.wait(futures, eagerError: eagerError);
        final results = cancelToken == null
            ? await waitFuture
            : await _awaitWithCancellation(waitFuture, cancelToken);
        cancelToken?.throwIfCancelled();
        final processedResults = onSuccess?.call(results);
        return processedResults;
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作（并行，带并发控制）
  ///
  /// [tasks] 为异步任务工厂列表，只有并发槽位可用时才会调用，
  /// 因此能真正限制同时在执行的任务数（不会预先创建全部 Future）；
  /// 传入的 Iterable 会立即转换为列表。
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收按任务顺序排列的所有结果
  /// [onError] 错误回调，接收第一个错误
  /// [concurrency] 同时执行的最大任务数，必须大于 0
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 任一任务失败后会停止启动新任务，并以第一个错误结束；
  /// 此时需等待当前在途任务结束后才会返回。
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  static Future<R?> runAllWithConcurrency<T, R>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) async {
    if (concurrency < 1) {
      throw ArgumentError.value(concurrency, 'concurrency', '并发数必须大于 0');
    }

    final taskList = tasks.toList();
    // 按任务下标占位，保证结果顺序与任务顺序一致
    final results = List<T?>.filled(taskList.length, null);

    return _executeWithLoading<R?>(
      config,
      () async {
        int nextIndex = 0;
        bool hasError = false;
        Object? firstError;
        StackTrace? firstStackTrace;

        // 每个 worker 持续领取下一个任务下标，直到任务耗尽或出现错误
        Future<void> worker() async {
          while (!hasError) {
            final index = nextIndex++;
            if (index >= taskList.length) return;

            try {
              cancelToken?.throwIfCancelled();
              results[index] = await taskList[index]();
            } catch (e, stackTrace) {
              if (!hasError) {
                hasError = true;
                firstError = e;
                firstStackTrace = stackTrace;
              }
              return;
            }
          }
        }

        final workerCount = taskList.length < concurrency ? taskList.length : concurrency;
        await Future.wait(List.generate(workerCount, (_) => worker()));

        if (hasError) {
          Error.throwWithStackTrace(
            firstError ?? StateError('任务执行失败'),
            firstStackTrace ?? StackTrace.current,
          );
        }

        cancelToken?.throwIfCancelled();
        return onSuccess?.call(results.cast<T>());
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作并返回第一个完成的结果
  ///
  /// 其余 Future 不会被取消，仍会继续执行；
  /// 空集合直接返回 null（不触发 `onError`）；等待期间取消会立即返回 null。
  ///
  /// [futures] Future 列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收最先完成的结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果；空集合、失败或取消返回 null
  static Future<R?> any<T, R>(
    Iterable<Future<T>> futures, {
    WAsyncConfig? config,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    final futureList = futures.toList();
    // Future.any 对空集合不会完成；空集合也不应触发无意义的 loading 回调
    if (futureList.isEmpty) {
      return null;
    }

    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final anyFuture = Future.any(futureList);
        final result = cancelToken == null
            ? await anyFuture
            : await _awaitWithCancellation(anyFuture, cancelToken);
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行多个异步操作
  ///
  /// 任一任务失败后立即停止，后续任务不再执行。
  ///
  /// [tasks] 异步函数列表，按顺序执行
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收按顺序排列的所有结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：成功返回 [onSuccess] 的结果，失败或取消返回 null
  static Future<R?> sequence<T, R>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        final results = <T>[];
        for (final task in tasks) {
          cancelToken?.throwIfCancelled();
          results.add(await task());
        }
        cancelToken?.throwIfCancelled();
        final processedResults = onSuccess?.call(results);
        return processedResults;
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 等待 [future] 完成，同时响应取消（内部使用）
  ///
  /// 若 [cancelToken] 在等待期间被取消，会立即以 [WCancellationException] 结束，
  /// 不再等待 [future]；[future] 本身不会被中止，仍会继续执行。
  static Future<T> _awaitWithCancellation<T>(
    Future<T> future,
    WCancelToken cancelToken,
  ) async {
    cancelToken.throwIfCancelled();

    final cancelCompleter = Completer<T>();
    void onCancel(Object? _) {
      if (!cancelCompleter.isCompleted) {
        cancelCompleter.completeError(
          WCancellationException(cancelToken.cancelReason),
        );
      }
    }

    cancelToken.addListener(onCancel);
    try {
      // Future.any 会处理两个分支的错误，被放弃的 future 之后报错也不会
      // 变成未处理异常。
      return await Future.any<T>([future, cancelCompleter.future]);
    } finally {
      cancelToken.removeListener(onCancel);
    }
  }

  /// 可被取消的延迟（内部使用）
  ///
  /// 若 [cancelToken] 在等待期间被取消，会立即以 [WCancellationException] 结束，
  /// 不再等待完整时长。
  static Future<void> _cancelableDelay(Duration delay, WCancelToken? cancelToken) async {
    if (cancelToken == null) {
      await Future.delayed(delay);
      return;
    }

    cancelToken.throwIfCancelled();

    final completer = Completer<void>();
    late final Timer timer;

    void onCancel(Object? _) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(WCancellationException(cancelToken.cancelReason));
      }
    }

    timer = Timer(delay, () {
      cancelToken.removeListener(onCancel);
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    cancelToken.addListener(onCancel);
    return completer.future;
  }

  /// 带加载状态的统一执行入口
  ///
  /// 负责触发加载回调、统一处理错误与取消，并在结束时回调加载完成。
  /// 同一 [WAsyncConfig] 上的并发操作会合并加载状态：首个操作开始时回调
  /// [WAsyncConfig.onLoadingStart]，最后一个操作结束时回调
  /// [WAsyncConfig.onLoadingEnd]。
  ///
  /// [config] 配置对象；为空时不做加载跟踪，也不触发兜底错误回调
  /// [executeFunc] 实际执行的异步操作
  /// [onError] 错误回调；为空时改用 [WAsyncConfig.fallbackOnError]
  /// [cancelToken] 取消令牌；若在操作开始前已取消，直接返回 null 且不触发加载回调
  ///
  /// 返回值：成功返回 [executeFunc] 的结果，业务失败或取消返回 null；
  /// 编程错误（[Error]）会原样向上抛出。
  static Future<T?> _executeWithLoading<T>(
    WAsyncConfig? config,
    Future<T> Function() executeFunc,
    void Function(Object?)? onError, {
    WCancelToken? cancelToken,
  }) async {
    // 已取消的操作直接结束，避免 loading 回调出现 0→1→0 的闪烁
    if (cancelToken?.isCancelled == true) {
      return null;
    }

    // 在本次调用开始时就确定是否跟踪加载状态，避免执行期间
    // showLoading 被修改导致 begin/end 不配对。
    final trackLoading = config?.showLoading == true;

    try {
      if (trackLoading) {
        config!._beginLoading();
      }

      final result = await executeFunc();
      return result;
    } catch (e) {
      // 编程错误（Error，如 TypeError / StateError）不属于业务异常，
      // 直接向上抛出，避免被静默吞掉后难以定位。
      if (e is Error) {
        rethrow;
      }

      // 取消属于正常结束：不回调 onError，直接返回 null
      if (e is WCancellationException) {
        return null;
      }

      try {
        onError?.call(e);
      } catch (_) {
        // 忽略错误回调自身的异常，保持「不向调用方抛出」的约定
      }

      // 未提供 onError 时改用兜底回调
      if (onError == null) {
        try {
          config?.fallbackOnError?.call(e);
        } catch (_) {
          // 忽略兜底错误回调自身的异常
        }
      }
      return null;
    } finally {
      if (trackLoading) {
        config!._endLoading();
      }
    }
  }
}
