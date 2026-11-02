import 'dart:io';

import '../commands/init_command.dart';
import '../cache/cache_store.dart';
import 'args.dart';

void runInit(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'force'});
  final store = CacheStore(Directory(options.root));
  final result = InitCommand(store).run(force: options.force);
  stderr.writeln(result.tokenCreated ? '已创建 .figma-token（记得填入 figd_ 令牌）' : '.figma-token 已存在');
  if (result.gitignoreAdded.isNotEmpty) {
    stderr.writeln('.gitignore 已追加：${result.gitignoreAdded.join(', ')}');
  }
  stderr.writeln('缓存目录：${result.cacheDir.path}');
}
