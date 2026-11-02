import 'dart:io';

/// 写 stdout；管道被 `head` 关闭时静默退出（避免 Broken pipe 崩溃）。
void printOut(String text) {
  try {
    stdout.write(text);
  } on FileSystemException {
    // 下游已经关闭（如 `| head`），不算错误
  }
}

void printLine(String text) {
  try {
    stdout.writeln(text);
  } on FileSystemException {
    // 同上
  }
}

/// 缺少 / 非法 token；退出码 4。
class FigmaTokenException implements Exception {
  const FigmaTokenException(this.message);

  final String message;

  @override
  String toString() => message;
}
