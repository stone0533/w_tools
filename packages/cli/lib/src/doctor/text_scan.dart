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
}

/// doctor 规则的轻量文本扫描入口。
class TextScan {
  static Iterable<SourceFile> files(ProjectContext ctx) sync* {
    for (final path in ctx.files) {
      yield SourceFile(path, ctx.read(path).split('\n'));
    }
  }
}
