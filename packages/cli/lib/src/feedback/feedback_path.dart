/// 校验 `--package`：只允许小写字母/数字/下划线，防止 `../` 穿越到反馈目录之外。
///
/// 返回规范化后的包名；`null` / 空串视为「不指定包」，返回 null。
String? validatePackageName(String? package) {
  if (package == null || package.isEmpty) return null;
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(package)) {
    throw FormatException('--package 只允许小写字母/数字/下划线：$package');
  }
  return package;
}
