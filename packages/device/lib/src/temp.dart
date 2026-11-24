import 'dart:io';

var _seq = 0;

/// 内部临时文件路径（截图 / 指纹 / devicectl JSON）。
///
/// 同一进程内用自增序号区分：并发命令不会互相覆盖。
String tempPath(String prefix, String ext) =>
    '${Directory.systemTemp.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}.$ext';

/// 生成临时文件、执行 [body]、无论成功失败都删掉它。
Future<T> withTempFile<T>(
  String prefix,
  String ext,
  Future<T> Function(String path) body,
) async {
  final path = tempPath(prefix, ext);
  try {
    return await body(path);
  } finally {
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } on FileSystemException {
        // 临时文件删不掉不该影响命令结果。
      }
    }
  }
}
