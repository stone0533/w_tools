import 'context.dart';

/// 一个待扫描的源文件及其行。
class SourceFile {
  SourceFile(this.path, this.lines) : _code = stripComments(lines.join('\n')).split('\n');

  final String path;
  final List<String> lines;
  final List<String> _code;

  /// 跳过空行和只含注释的行；`text` 已去掉块注释 / 行注释 / 字符串。
  Iterable<SourceLine> get codeLines sync* {
    for (var i = 0; i < _code.length; i++) {
      final text = _code[i];
      if (text.trim().isEmpty) continue;
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

  /// 已去注释的可扫描文本（字符串保留，供 R9 等匹配）
  String get code => text;
}

/// 去掉 Dart 源码里的行注释 / 块注释，保留字符串内容与换行。
///
/// 支持 `'...'`、`"..."`、三引号、raw string（`r'...'`）；块注释内的代码
/// 会被替换成空格，但仍保留行号。
String stripComments(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final char = source[i];

    if (char == '/' && i + 1 < source.length && source[i + 1] == '/') {
      while (i < source.length && source[i] != '\n') {
        out.write(' ');
        i++;
      }
      continue;
    }
    if (char == '/' && i + 1 < source.length && source[i + 1] == '*') {
      out.write('  ');
      i += 2;
      while (i < source.length) {
        if (source[i] == '*' && i + 1 < source.length && source[i + 1] == '/') {
          out.write('  ');
          i += 2;
          break;
        }
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      continue;
    }

    final raw =
        (char == 'r' || char == 'R') &&
        i + 1 < source.length &&
        (source[i + 1] == "'" || source[i + 1] == '"');
    if (raw) {
      out.write(char);
      i++;
    }
    if (i < source.length && (source[i] == "'" || source[i] == '"')) {
      final quote = source[i];
      final triple = i + 2 < source.length && source[i + 1] == quote && source[i + 2] == quote;
      final delimiter = triple ? '$quote$quote$quote' : quote;
      out.write(delimiter);
      i += delimiter.length;
      while (i < source.length) {
        if (!raw && source[i] == '\\' && i + 1 < source.length) {
          out.write(source.substring(i, i + 2));
          i += 2;
          continue;
        }
        if (source.startsWith(delimiter, i)) {
          out.write(delimiter);
          i += delimiter.length;
          break;
        }
        out.write(source[i]);
        i++;
      }
      continue;
    }

    out.write(char);
    i++;
  }
  return out.toString();
}

/// 去掉字符串外的行尾 `//` 注释（保留给旧调用 / 单行场景）。
String stripLineComment(String source) {
  final stripped = stripComments(source);
  final newline = stripped.indexOf('\n');
  return newline < 0 ? stripped.trimRight() : stripped.substring(0, newline).trimRight();
}

/// doctor 规则的轻量文本扫描入口。
class TextScan {
  static Iterable<SourceFile> files(ProjectContext ctx) sync* {
    for (final path in ctx.files) {
      yield SourceFile(path, ctx.read(path).split('\n'));
    }
  }
}
