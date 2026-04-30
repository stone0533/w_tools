import 'dart:async';
import 'package:flutter/material.dart';

/// 取消令牌类，用于取消异步操作
class WCancelToken {
  /// 取消状态
  bool _isCancelled = false;

  /// 取消原因
  dynamic _cancelReason;

  /// 取消回调集合
  final Set<Function(dynamic)> _cancelCallbacks = {};

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 取消原因
  dynamic get cancelReason => _cancelReason;

  /// 添加取消回调
  void addCancelCallback(Function(dynamic) callback) {
    _cancelCallbacks.add(callback);
  }

  /// 添加一次性取消回调
  void onceCancel(Function(dynamic) callback) {
    _cancelCallbacks.add(callback);
  }

  /// 移除取消回调
  void removeCancelCallback(Function(dynamic) callback) {
    _cancelCallbacks.remove(callback);
  }

  /// 取消操作
  void cancel([dynamic reason]) {
    _isCancelled = true;
    _cancelReason = reason;
    // 触发所有取消回调
    for (final callback in _cancelCallbacks) {
      try {
        callback(reason);
      } catch (e) {
        // 忽略回调执行错误
      }
    }
    // 清空回调列表
    _cancelCallbacks.clear();
  }

  /// 如果已取消则抛出异常
  void throwIfCancelled() {
    if (_isCancelled) {
      throw WCancellationException(_cancelReason);
    }
  }

  /// 清理资源
  void dispose() {
    _cancelCallbacks.clear();
  }
}

/// 取消异常类
class WCancellationException implements Exception {
  /// 取消原因
  final dynamic reason;

  /// 构造函数
  WCancellationException(this.reason);

  @override
  String toString() {
    return 'WCancellationException: $reason';
  }
}

/// 异步操作配置类
class WFutureConfig {
  /// 是否显示加载中
  bool showLoading;

  /// 加载中回调函数
  VoidCallback? loadingCallback;

  /// 加载完成回调函数
  VoidCallback? loadingCompleteCallback;

  /// 自定义错误处理回调
  void Function(dynamic error)? errorHandler;

  /// 构造函数
  WFutureConfig({
    this.showLoading = true,
    this.loadingCallback,
    this.loadingCompleteCallback,
    this.errorHandler,
  });

  /// 创建一个新的配置对象，允许部分修改配置
  ///
  /// 未指定的参数将保持当前值
  ///
  /// @param showLoading 是否显示加载中
  /// @param loadingCallback 加载中回调函数
  /// @param loadingCompleteCallback 加载完成回调函数
  /// @param errorHandler 自定义错误处理回调
  /// @return 新的 WFutureConfig 实例
  WFutureConfig copyWith({
    bool? showLoading,
    VoidCallback? loadingCallback,
    VoidCallback? loadingCompleteCallback,
    void Function(dynamic error)? errorHandler,
  }) {
    return WFutureConfig(
      showLoading: showLoading ?? this.showLoading,
      loadingCallback: loadingCallback ?? this.loadingCallback,
      loadingCompleteCallback: loadingCompleteCallback ?? this.loadingCompleteCallback,
      errorHandler: errorHandler ?? this.errorHandler,
    );
  }

  /// 执行单个异步操作
  ///
  /// [func] 要执行的异步函数
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  ///
  /// 返回值：操作成功返回结果，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.one(
  ///   () async => 'Hello World',
  ///   config: WFutureConfig(
  ///     showLoading: true,
  ///     loadingCallback: () => print('Loading...'),
  ///     loadingCompleteCallback: () => print('Loading complete'),
  ///   ),
  ///   onSuccess: (data) => print('Success: $data'),
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// ```
  Future<R?> one<T, R>(
    Future<T> Function() func, {
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WFuture.one<T, R>(
      func,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// [func] 要执行的异步函数
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  /// [retryCount] 重试次数
  /// [retryDelay] 重试间隔
  Future<R?> oneWithRetry<T, R>(
    Future<T> Function() func, {
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    WCancelToken? cancelToken,
  }) async {
    return WFuture.oneWithRetry<T, R>(
      func,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      retryCount: retryCount,
      retryDelay: retryDelay,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持超时
  ///
  /// [func] 要执行的异步函数
  /// [timeout] 超时时间
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  Future<R?> oneWithTimeout<T, R>(
    Future<T> Function() func,
    Duration timeout, {
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WFuture.oneWithTimeout<T, R>(
      func,
      timeout,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行多个异步操作（并行）
  ///
  /// [futures] Future列表
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  /// [eagerError] 是否在第一个错误时立即失败
  Future<R?> wait<T, R>(
    Iterable<Future<T>> futures, {
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) async {
    return WFuture.wait<T, R>(
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
  /// [futures] Future列表
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  /// [concurrency] 并发数
  Future<R?> waitWithConcurrency<T, R>(
    Iterable<Future<T>> futures, {
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) async {
    return WFuture.waitWithConcurrency<T, R>(
      futures,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      concurrency: concurrency,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行多个异步操作
  ///
  /// [funcs] 泛型异步函数列表，按顺序执行
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  Future<R?> series<T, R>(
    List<Future<T> Function()> funcs, {
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return WFuture.series<T, R>(
      funcs,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }
}

/// 异步操作助手
class WFuture {
  /// 执行单个异步操作
  ///
  /// [func] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.one<int, String>(
  ///   () async => 42,
  ///   config: WFutureConfig(
  ///     showLoading: true,
  ///     loadingCallback: () => print('Loading...'),
  ///     loadingCompleteCallback: () => print('Loading complete'),
  ///   ),
  ///   onSuccess: (data) => 'The answer is $data',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: The answer is 42
  /// ```
  static Future<R?> one<T, R>(
    Future<T> Function() func, {
    WFutureConfig? config,
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await func();
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// [func] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [retryCount] 重试次数
  /// [retryDelay] 重试间隔
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.oneWithRetry<int, String>(
  ///   () async {
  ///     // 模拟网络请求，可能失败
  ///     if (Random().nextBool()) {
  ///       throw Exception('Network error');
  ///     }
  ///     return 42;
  ///   },
  ///   retryCount: 3,
  ///   retryDelay: Duration(seconds: 1),
  ///   onSuccess: (data) => 'Success: $data',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: Success: 42
  /// ```
  static Future<R?> oneWithRetry<T, R>(
    Future<T> Function() func, {
    WFutureConfig? config,
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    WCancelToken? cancelToken,
  }) async {
    int attempt = 0;

    return _executeWithLoading<R?>(
      config,
      () async {
        while (true) {
          try {
            cancelToken?.throwIfCancelled();
            attempt++;
            final result = await func();
            cancelToken?.throwIfCancelled();
            final processedResult = onSuccess?.call(result);
            return processedResult;
          } catch (e) {
            if (e is WCancellationException) {
              rethrow;
            }
            if (attempt <= retryCount) {
              cancelToken?.throwIfCancelled();
              await Future.delayed(retryDelay);
              continue;
            }
            onError?.call(e);
            rethrow;
          }
        }
      },
      onError,
      cancelToken,
    );
  }

  /// 执行单个异步操作并支持超时
  ///
  /// [func] 要执行的异步函数
  /// [timeout] 超时时间
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.oneWithTimeout<int, String>(
  ///   () async {
  ///     // 模拟耗时操作
  ///     await Future.delayed(Duration(seconds: 2));
  ///     return 42;
  ///   },
  ///   Duration(seconds: 1), // 1秒超时
  ///   onSuccess: (data) => 'Success: $data',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 可能输出: Error: Operation timed out
  /// ```
  static Future<R?> oneWithTimeout<T, R>(
    Future<T> Function() func,
    Duration timeout, {
    WFutureConfig? config,
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await func().timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Operation timed out'),
        );
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作（并行）
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [eagerError] 是否在第一个错误时立即失败
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.wait<int, int>(
  ///   [
  ///     Future.delayed(Duration(seconds: 1), () => 1),
  ///     Future.delayed(Duration(seconds: 2), () => 2),
  ///     Future.delayed(Duration(seconds: 3), () => 3),
  ///   ],
  ///   onSuccess: (data) => data.reduce((a, b) => a + b),
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: 6
  /// ```
  static Future<R?> wait<T, R>(
    Iterable<Future<T>> futures, {
    WFutureConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final results = await Future.wait(
          futures,
          eagerError: eagerError,
        );
        cancelToken?.throwIfCancelled();
        final processedResults = onSuccess?.call(results);
        return processedResults;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作（并行，带并发控制）
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [concurrency] 并发数
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.waitWithConcurrency<int, String>(
  ///   [
  ///     Future.delayed(Duration(seconds: 1), () => 1),
  ///     Future.delayed(Duration(seconds: 1), () => 2),
  ///     Future.delayed(Duration(seconds: 1), () => 3),
  ///     Future.delayed(Duration(seconds: 1), () => 4),
  ///     Future.delayed(Duration(seconds: 1), () => 5),
  ///   ],
  ///   concurrency: 2, // 最多同时执行2个
  ///   onSuccess: (data) => 'Results: ${data.join(', ')}',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: Results: 1, 2, 3, 4, 5
  /// ```
  static Future<R?> waitWithConcurrency<T, R>(
    Iterable<Future<T>> futures, {
    WFutureConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) async {
    final futureList = futures.toList();
    final results = <T>[];

    return _executeWithLoading<R?>(
      config,
      () async {
        int index = 0;
        while (index < futureList.length) {
          cancelToken?.throwIfCancelled();
          // 计算当前批次的大小
          int batchSize = (futureList.length - index) > concurrency
              ? concurrency
              : (futureList.length - index);
          // 执行当前批次
          final batchFutures = futureList.sublist(index, index + batchSize);
          final batchResults = await Future.wait(batchFutures);
          results.addAll(batchResults);
          index += batchSize;
        }
        cancelToken?.throwIfCancelled();
        final processedResults = onSuccess?.call(results);
        return processedResults;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作并返回第一个完成的结果
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.any<int, String>(
  ///   [
  ///     Future.delayed(Duration(seconds: 3), () => 1),
  ///     Future.delayed(Duration(seconds: 1), () => 2), // 这个会先完成
  ///     Future.delayed(Duration(seconds: 2), () => 3),
  ///   ],
  ///   onSuccess: (data) => 'First result: $data',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: First result: 2
  /// ```
  static Future<R?> any<T, R>(
    Iterable<Future<T>> futures, {
    WFutureConfig? config,
    R? Function(T)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await Future.any(futures);
        cancelToken?.throwIfCancelled();
        final processedResult = onSuccess?.call(result);
        return processedResult;
      },
      onError,
      cancelToken,
    );
  }

  /// 按顺序执行多个异步操作
  ///
  /// [funcs] 异步函数列表，按顺序执行
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果并返回处理后的结果
  /// [onError] 错误回调，接收错误信息
  /// [cancelToken] 取消令牌，用于取消操作
  ///
  /// 返回值：操作成功返回 onSuccess 的返回值，失败返回 null
  ///
  /// 示例：
  /// ```dart
  /// final result = await WFuture.series<int, String>(
  ///   [
  ///     () => Future.delayed(Duration(seconds: 1), () => 1),
  ///     () => Future.delayed(Duration(seconds: 1), () => 2),
  ///     () => Future.delayed(Duration(seconds: 1), () => 3),
  ///   ],
  ///   onSuccess: (data) => 'Results: ${data.join(', ')}',
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// print(result); // 输出: Results: 1, 2, 3
  /// ```
  static Future<R?> series<T, R>(
    List<Future<T> Function()> funcs, {
    WFutureConfig? config,
    R? Function(List<T>)? onSuccess,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _executeWithLoading<R?>(
      config,
      () async {
        final results = <T>[];
        for (int i = 0; i < funcs.length; i++) {
          cancelToken?.throwIfCancelled();
          final result = await funcs[i]();
          results.add(result);
        }
        cancelToken?.throwIfCancelled();
        final processedResults = onSuccess?.call(results);
        return processedResults;
      },
      onError,
      cancelToken,
    );
  }

  /// 带加载状态的通用执行方法
  static Future<T?> _executeWithLoading<T>(
    WFutureConfig? config,
    Future<T> Function() executeFunc,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  ) async {
    try {
      if (config?.showLoading == true) {
        config?.loadingCallback?.call();
      }

      final result = await executeFunc();
      return result;
    } catch (e) {
      // 处理取消异常
      if (e is WCancellationException) {
        return null;
      }

      onError?.call(e);

      // 只在未提供 onError 的情况下执行自定义错误处理回调
      if (onError == null) {
        config?.errorHandler?.call(e);
      }
      return null;
    } finally {
    
      if (config?.showLoading == true) {
        config?.loadingCompleteCallback?.call();
      }
    }
  }

  /// 清理资源
  ///
  /// 用于释放 WFuture 相关的资源，防止内存泄漏
  static void cleanup() {
    // 清理资源
  }
}
