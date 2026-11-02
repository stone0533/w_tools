import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import '../diff/spec_diff.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';

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
  DiffCommand({required this.store, required this.client, this.log = true});

  final CacheStore store;
  final FigmaClient client;
  final bool log;

  /// [oldFile] 是旧缓存文件；没有旧缓存时直接拉新（相当于 fetch）。
  Future<DiffResult> run({
    required String fileKey,
    required String nodeId,
    File? oldFile,
  }) async {
    final target = store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: nodeId);
    final backup = File('${target.path}.prev');
    if (target.existsSync()) target.copySync(backup.path);

    final fetched = await _fetchFresh(fileKey: fileKey, nodeId: nodeId, target: target);
    final fetchedDocument = readDocument(fetched, nodeId);
    final after = fetchedDocument == null ? null : findFigmaNode(fetchedDocument, nodeId);
    if (after == null) {
      throw StateError('最新数据里找不到节点 $nodeId');
    }

    final previous = oldFile ?? (backup.existsSync() ? backup : null);
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

  Future<File> _fetchFresh({
    required String fileKey,
    required String nodeId,
    required File target,
  }) async {
    final json = await client.getJson(
      Uri.parse('https://api.figma.com/v1/files/$fileKey/nodes?ids=$nodeId'),
    );
    store.write(target, json);
    if (log) {
      store.logUsage(kind: 'nodes', cacheFile: target.uri.pathSegments.last);
    }
    return target;
  }
}
