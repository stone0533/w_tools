import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import '../diff/spec_diff.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
import 'fetch_command.dart';

/// `diff` 的结果。
class DiffResult {
  DiffResult({
    required this.fileKey,
    required this.nodeId,
    required this.changes,
    required this.nodes,
    required this.tierCalls,
  });

  final String fileKey;
  final String nodeId;
  final List<SpecChange> changes;
  final List<SpecNodeDelta> nodes;
  final int tierCalls;

  bool get isEmpty => changes.isEmpty && nodes.isEmpty;
}

/// 对比「上次缓存」与「刚拉的最新节点」，列出改动（消耗 1 次 Tier 1）。
class DiffCommand {
  DiffCommand({
    required this.store,
    required this.client,
    this.log = true,
  });

  final CacheStore store;
  final FigmaClient client;
  final bool log;

  /// [oldFile] 是旧缓存文件；没有旧缓存时直接拉新（相当于 fetch）。
  ///
  /// 只有「旧缓存就是待覆盖的目标文件」时才需要先快照成 `.prev`；
  /// 调用方已经给出别的基线文件时不再多拷一份。
  Future<DiffResult> run({
    required String fileKey,
    required String nodeId,
    File? oldFile,
  }) async {
    final target = store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: nodeId);
    final backup = File('${target.path}.prev');
    File? previous = oldFile;
    if (previous == null) {
      if (target.existsSync()) target.copySync(backup.path);
      previous = backup.existsSync() ? backup : null;
    } else if (previous.absolute.path == target.absolute.path) {
      // 基线就是马上要被覆盖的目标文件：先快照，否则会拿新内容当旧内容比。
      previous.copySync(backup.path);
      previous = backup;
    }

    final fetched = await FetchCommand(store: store, client: client, log: log).nodes(
      fileKey: fileKey,
      ids: <String>[nodeId],
      refresh: true,
    );
    final fetchedDocument = readDocument(fetched.file, nodeId);
    final after = fetchedDocument == null ? null : findFigmaNode(fetchedDocument, nodeId);
    if (after == null) {
      throw StateError('最新数据里找不到节点 $nodeId');
    }

    if (previous == null || !previous.existsSync()) {
      _cleanupBackup(backup);
      return DiffResult(
        fileKey: fileKey,
        nodeId: nodeId,
        changes: const [],
        nodes: const [],
        tierCalls: 1,
      );
    }
    final previousDocument = readDocument(previous, nodeId);
    final before = previousDocument == null ? null : findFigmaNode(previousDocument, nodeId);
    if (before == null) {
      throw StateError('旧缓存 ${previous.path} 里找不到节点 $nodeId');
    }

    const differ = SpecDiff();
    final result = DiffResult(
      fileKey: fileKey,
      nodeId: nodeId,
      changes: differ.changes(before, after),
      nodes: differ.nodes(before, after),
      tierCalls: 1,
    );
    _cleanupBackup(backup);
    return result;
  }

  void _cleanupBackup(File backup) {
    if (backup.existsSync()) backup.deleteSync();
  }
}
