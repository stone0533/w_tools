import '../client/figma_client.dart';

/// `/v1/files/<fileKey>/meta` 的轻量结果。
class FileMeta {
  FileMeta({this.version, this.lastTouchedAt});

  final String? version;
  final String? lastTouchedAt;
}

/// 读取线上文件版本（Tier 3，不占 Tier 1）；`/meta` 没有可用字段时返回 null。
Future<FileMeta?> readFileMeta(FigmaClient client, String fileKey) async {
  final json = await client.fileMeta(fileKey);
  final file = json['file'];
  if (file is! Map) return null;
  String? text(Object? value) {
    final raw = '${value ?? ''}';
    return raw.isEmpty ? null : raw;
  }

  return FileMeta(
    version: text(file['version']),
    lastTouchedAt: text(file['last_touched_at'] ?? file['lastTouchedAt']),
  );
}
