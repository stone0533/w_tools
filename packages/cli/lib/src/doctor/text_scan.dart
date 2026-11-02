import 'context.dart';

/// 一个待扫描的源文件及其行。
class SourceFile {
  const SourceFile(this.path, this.lines);

  final String path;
  final List<String> lines;

  /// 跳过空行和整行注释。
  Iterable<SourceLine> get codeLines sync* {
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i];
      if (text.trimLeft().startsWith('//')) continue;
      yield SourceLine(this, i, text);
    }
  }
}

class SourceLine {
  const SourceLine(this.file, this.index, this.text);

  final SourceFile file;
  final int index; // 0-based
  final String text;

  int get lineNumber => index + 1;

  /// 去掉行尾 `//` 注释；不处理块注释。
  String get code => stripLineComment(text);
}

/// 去掉字符串外的行尾 `//` 注释；简单引号/转义处理，不解析 raw string。
String stripLineComment(String source) {
  String? quote;
  var escaped = false;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
      continue;
    }
    if (char == '/' && i + 1 < source.length && source[i + 1] == '/') {
      return source.substring(0, i);
    }
  }
  return source;
}

/// doctor 规则的轻量文本扫描入口。
class TextScan {
  static Iterable<SourceFile> files(ProjectContext ctx) sync* {
    for (final path in ctx.files) {
      yield SourceFile(path, ctx.read(path).split('\n'));
    }
  }
}
