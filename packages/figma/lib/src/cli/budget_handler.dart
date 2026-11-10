import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/usage_command.dart';
import 'args.dart';
import 'cli_io.dart';

void runBudget(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json', 'set'});
  rejectExtraPositional(options, 0);

  final store = CacheStore(Directory(options.root));
  if (options.budgetSet != null) {
    store.dir.createSync(recursive: true);
    // 读-改-写：只覆盖 limit，保住其它字段（存量 month / used 或用户手写的键）。
    final existing = store.read(store.budgetFile) ?? <String, dynamic>{};
    final payload = <String, dynamic>{...existing, 'limit': options.budgetSet};
    store.budgetFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));
    printLine('月度预算已设为 ${options.budgetSet}');
    return;
  }

  final summary = UsageCommand(store).run();
  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.budget/1',
      'limit': summary.limit,
      'used': summary.used,
      'remaining': summary.remaining,
    }));
    return;
  }
  printLine('月度预算 ${summary.limit} 次，本月已用 ${summary.used} 次，剩余 ${summary.remaining} 次');
}
