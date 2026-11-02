/// Figma 链接里解析出的定位信息。
class FigmaUrlTarget {
  FigmaUrlTarget({required this.fileKey, required this.nodeId});

  final String fileKey;

  /// `1862:9222`（URL 里是 `1862-9222`）
  final String? nodeId;
}

/// 从 Figma 链接解析 `fileKey` 与 `nodeId`。
///
/// 支持：
/// - `https://www.figma.com/design/<key>/<name>?node-id=1862-9222`
/// - `https://www.figma.com/file/<key>/...?node-id=1862-9222`
/// - 直接传 `1862:9222`（只返回 nodeId，fileKey 空）
class UrlCommand {
  const UrlCommand();

  FigmaUrlTarget run(String input) {
    if (input.contains('figma.com')) {
      final uri = Uri.tryParse(input);
      if (uri == null) {
        throw FormatException('不是合法的 URL：$input');
      }
      final segments = uri.pathSegments;
      final keyIndex = segments.indexWhere(
        (s) => s == 'design' || s == 'file' || s == 'proto',
      );
      if (keyIndex < 0 || segments.length <= keyIndex + 1) {
        throw FormatException('URL 里找不到 fileKey：$input');
      }
      final nodeRaw = uri.queryParameters['node-id'];
      return FigmaUrlTarget(
        fileKey: segments[keyIndex + 1],
        nodeId: nodeRaw?.replaceAll('-', ':'),
      );
    }
    if (input.contains(':')) {
      return FigmaUrlTarget(fileKey: '', nodeId: input);
    }
    throw FormatException('既不是 Figma URL 也不是 nodeId：$input');
  }
}
