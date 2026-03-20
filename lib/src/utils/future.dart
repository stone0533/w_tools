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

/// 错误处理策略枚举
enum ErrorHandlingStrategy {
  returnNull,    // 返回 null
  rethrowError,  // 重新抛出异常
  custom,        // 自定义处理
}

/// 异步操作配置类
class WFutureConfig {
  /// 是否显示加载中
  final bool showLoading;

  /// 加载中回调函数
  final VoidCallback? loadingCallback;

  /// 加载完成回调函数
  final VoidCallback? loadingCompleteCallback;

  /// 错误处理策略
  final ErrorHandlingStrategy errorStrategy;

  /// 自定义错误处理回调，用于 ErrorHandlingStrategy.custom 策略
  final Future<dynamic> Function(dynamic error)? customErrorHandler;

  /// 构造函数
  const WFutureConfig({
    this.showLoading = true,
    this.loadingCallback,
    this.loadingCompleteCallback,
    this.errorStrategy = ErrorHandlingStrategy.returnNull,
    this.customErrorHandler,
  });

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
  Future<T?> one<T>(
    Future<T> Function() func,
    {
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.one(
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
  Future<T?> oneWithRetry<T>(
    Future<T> Function() func,
    {
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      int retryCount = 3,
      Duration retryDelay = const Duration(seconds: 1),
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.oneWithRetry(
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
  Future<T?> oneWithTimeout<T>(
    Future<T> Function() func,
    Duration timeout,
    {
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.oneWithTimeout(
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
  Future<List<T>?> wait<T>(
    Iterable<Future<T>> futures,
    {
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      bool eagerError = true,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.wait(
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
  Future<List<T>?> waitWithConcurrency<T>(
    Iterable<Future<T>> futures,
    {
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      int concurrency = 4,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.waitWithConcurrency(
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
  /// [funcs] 异步函数列表，按顺序执行
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  Future<List<dynamic>?> series(
    List<Future<dynamic> Function()> funcs,
    {
      void Function(List<dynamic>)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.series(
      funcs,
      config: this,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行多个异步操作（泛型版本）
  ///
  /// [funcs] 泛型异步函数列表，按顺序执行
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  Future<List<T>?> seriesWithType<T>(
    List<Future<T> Function()> funcs,
    {
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    return WFuture.seriesWithType<T>(
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
  /// 缓存的默认配置
  static const WFutureConfig _defaultConfig = WFutureConfig();

  /// 执行单个异步操作
  ///
  /// [func] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
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
  static Future<T?> one<T>(
    Future<T> Function() func,
    {
      WFutureConfig? config,
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;

    return _executeWithLoading(
      configData,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await func();
        cancelToken?.throwIfCancelled();
        onSuccess?.call(result);
        return result;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// [func] 要执行的异步函数
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  /// [retryCount] 重试次数
  /// [retryDelay] 重试间隔
  static Future<T?> oneWithRetry<T>(
    Future<T> Function() func,
    {
      WFutureConfig? config,
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      int retryCount = 3,
      Duration retryDelay = const Duration(seconds: 1),
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;
    int attempt = 0;

    return _executeWithLoading(
      configData,
      () async {
        while (true) {
          try {
            cancelToken?.throwIfCancelled();
            attempt++;
            final result = await func();
            cancelToken?.throwIfCancelled();
            onSuccess?.call(result);
            return result;
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
  /// [onSuccess] 成功回调，接收操作结果
  /// [onError] 错误回调，接收错误信息
  static Future<T?> oneWithTimeout<T>(
    Future<T> Function() func,
    Duration timeout,
    {
      WFutureConfig? config,
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;

    return _executeWithLoading(
      configData,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await func().timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Operation timed out'),
        );
        cancelToken?.throwIfCancelled();
        onSuccess?.call(result);
        return result;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作（并行）
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  /// [eagerError] 是否在第一个错误时立即失败
  static Future<List<T>?> wait<T>(
    Iterable<Future<T>> futures,
    {
      WFutureConfig? config,
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      bool eagerError = true,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;

    return _executeWithLoading(
      configData,
      () async {
        cancelToken?.throwIfCancelled();
        final results = await Future.wait(
          futures,
          eagerError: eagerError,
        );
        cancelToken?.throwIfCancelled();
        onSuccess?.call(results);
        return results;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作（并行，带并发控制）
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  /// [concurrency] 并发数
  static Future<List<T>?> waitWithConcurrency<T>(
    Iterable<Future<T>> futures,
    {
      WFutureConfig? config,
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      int concurrency = 4,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;
    final futureList = futures.toList();
    final results = <T>[];

    return _executeWithLoading(
      configData,
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
        onSuccess?.call(results);
        return results;
      },
      onError,
      cancelToken,
    );
  }

  /// 执行多个异步操作并返回第一个完成的结果
  ///
  /// [futures] Future列表
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收结果
  /// [onError] 错误回调，接收错误信息
  static Future<T?> any<T>(
    Iterable<Future<T>> futures,
    {
      WFutureConfig? config,
      void Function(T)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;

    return _executeWithLoading(
      configData,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await Future.any(futures);
        cancelToken?.throwIfCancelled();
        onSuccess?.call(result);
        return result;
      },
      onError,
      cancelToken,
    );
  }

  /// 按顺序执行多个异步操作
  ///
  /// [funcs] 异步函数列表，按顺序执行
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  static Future<List<dynamic>?> series(
    List<Future<dynamic> Function()> funcs,
    {
      WFutureConfig? config,
      void Function(List<dynamic>)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    return seriesWithType<dynamic>(
      funcs,
      config: config,
      onSuccess: onSuccess,
      onError: onError,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行多个异步操作（泛型版本）
  ///
  /// [funcs] 泛型异步函数列表，按顺序执行
  /// [config] 配置对象，控制加载状态和回调
  /// [onSuccess] 成功回调，接收所有结果
  /// [onError] 错误回调，接收错误信息
  static Future<List<T>?> seriesWithType<T>(
    List<Future<T> Function()> funcs,
    {
      WFutureConfig? config,
      void Function(List<T>)? onSuccess,
      void Function(dynamic)? onError,
      WCancelToken? cancelToken,
    }
  ) async {
    final configData = config ?? _defaultConfig;

    return _executeWithLoading(
      configData,
      () async {
        final results = <T>[];
        for (int i = 0; i < funcs.length; i++) {
          cancelToken?.throwIfCancelled();
          final result = await funcs[i]();
          results.add(result);
        }
        cancelToken?.throwIfCancelled();
        onSuccess?.call(results);
        return results;
      },
      onError,
      cancelToken,
    );
  }

  /// 带加载状态的通用执行方法
  static Future<T?> _executeWithLoading<T>(
    WFutureConfig config,
    Future<T> Function() executeFunc,
    void Function(dynamic)? onError,
    WCancelToken? cancelToken,
  ) async {
    try {
      if (config.showLoading) {
        config.loadingCallback?.call();
      }

      final result = await executeFunc();
      return result;
    } catch (e) {
      onError?.call(e);

      // 处理取消异常
      if (e is WCancellationException) {
        return null;
      }

      // 根据错误处理策略处理
      switch (config.errorStrategy) {
        case ErrorHandlingStrategy.returnNull:
          return null;
        case ErrorHandlingStrategy.rethrowError:
          rethrow;
        case ErrorHandlingStrategy.custom:
          if (config.customErrorHandler != null) {
            final customResult = await config.customErrorHandler!(e);
            return customResult as T?;
          }
          return null;
      }
    } finally {
      if (config.showLoading) {
        config.loadingCompleteCallback?.call();
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


