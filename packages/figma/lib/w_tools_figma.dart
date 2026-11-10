/// 只读的 Figma 取数与规格导出工具。
///
/// CLI 内部实现不在此导出；这里只保留可复用的稳定类型与命令。
library;

export 'src/cache/cache_store.dart' show CacheStore, UsageEntry;
export 'src/client/figma_client.dart' show FigmaClient, FigmaHttpException, HttpFigmaClient;
export 'src/commands/diff_command.dart' show DiffCommand, DiffResult;
export 'src/commands/fetch_command.dart' show FetchCommand, FetchResult;
export 'src/commands/init_command.dart' show InitCommand, InitResult;
export 'src/commands/url_command.dart' show FigmaUrlTarget, UrlCommand;
export 'src/commands/usage_command.dart' show UsageCommand, UsageResult;
export 'src/diff/spec_diff.dart' show SpecChange, SpecDiff, SpecNodeDelta;
export 'src/spec/figma_node.dart' show findFigmaNode, pyFixed;
export 'src/spec/spec_renderer.dart' show FigmaSpecRenderer;
export 'src/tokens/token_collector.dart'
    show ColorUsage, NumberUsage, TextStyleUsage, TokenCollector;
export 'src/tokens/token_renderer.dart' show TokenRenderer;
