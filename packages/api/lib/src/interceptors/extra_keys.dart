/// 拦截器之间共享的 `RequestOptions.extra` 键。
///
/// 不对外导出：`WMetricsInterceptor` 需要读 `WRetryInterceptor` /
/// `WTokenInterceptor` 写入的重试计数。放在一处，避免两侧各写一份字符串字面量
/// 后改名不报错、`WMetric.attempt` 静默退回 1。
const String networkRetryCountExtraKey = '_w_tools_network_retry_count';

const String authRetryCountExtraKey = '_w_tools_auth_retry_count';
