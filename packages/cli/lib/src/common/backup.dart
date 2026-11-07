import 'dart:io';

import 'package:path/path.dart' as p;

/// 覆盖项目配置前留底：首次写 `.bak`，已存在时写 `.bak.<timestamp>`。
///
/// 返回实际备份文件名；调用方用它写 warning / JSON，避免只报一个固定 `.bak`
/// 而实际写的是带时间戳文件。
String backupFile(File file) {
  final base = File('${file.path}.bak');
  if (!base.existsSync()) {
    file.copySync(base.path);
    return p.basename(base.path);
  }
  final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
  final alt = File('${file.path}.bak.$stamp');
  file.copySync(alt.path);
  return p.basename(alt.path);
}
