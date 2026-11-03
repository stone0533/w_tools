import 'async_state_builder.dart';

/// 兼容别名；新代码使用 [WAsyncStateBuilder]。
///
/// remove-in: 2.0.0
@Deprecated('Use WAsyncStateBuilder instead')
typedef WAsyncBuilder<T> = WAsyncStateBuilder<T>;
