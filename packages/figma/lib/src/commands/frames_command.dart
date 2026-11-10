import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';

/// `frames` 的纯逻辑：从索引或单个缓存文件取行，再做名称 / 页面过滤与稳定排序。
///
/// 打印（表格 / JSON / 跳过损坏缓存的提示）留给调用方。
class FramesCommand {
  FramesCommand(this.store);

  final CacheStore store;

  /// 只读 `_nodes-index.json` 的 FRAME 摘要（不解析缓存文件内容）。
  List<Map<String, Object?>> fromIndex({required Directory root, required bool all}) {
    return framesFromIndex(store, all: all, root: root);
  }

  /// 直接解析一个缓存文件；文件损坏时抛 [StateError] / [FormatException]。
  List<Map<String, Object?>> fromFile(
    File file, {
    required Directory root,
    required bool all,
  }) {
    final frames = <String, Map<String, Object?>>{};
    for (final document in readDocuments(file).values) {
      collectFrames(
        document,
        all: all,
        cacheFile: relativeToRoot(root, file),
        out: frames,
      );
    }
    return frames.values.toList();
  }

  /// 名称 / 页面过滤（大小写不敏感的子串）+ 按 name、id 排序。
  List<Map<String, Object?>> filter(
    List<Map<String, Object?>> rows, {
    String? nameFilter,
    String? pageFilter,
  }) {
    final name = nameFilter?.toLowerCase();
    final page = pageFilter?.toLowerCase();
    return rows.where((row) {
      final rowName = '${row['name']}'.toLowerCase();
      final rowPage = '${row['page']}'.toLowerCase();
      return (name == null || rowName.contains(name)) && (page == null || rowPage.contains(page));
    }).toList()
      ..sort((a, b) {
        final byName = '${a['name']}'.compareTo('${b['name']}');
        // 同名画板按 id 排，脚本拿到的顺序才稳定。
        return byName != 0 ? byName : '${a['id']}'.compareTo('${b['id']}');
      });
  }
}
