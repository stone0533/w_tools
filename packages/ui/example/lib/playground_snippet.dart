/// 生成 Playground 的 WImage 代码片段；与页面状态解耦，便于测试。
String buildPlaygroundSnippet({
  required bool isNetwork,
  required double width,
  required double height,
  required double? aspectRatio,
  required String fitName,
  required int? memCache,
  required double radius,
  required bool withBorder,
  required bool withShadow,
  required bool withMargin,
  required bool customPlaceholder,
  required int retryCount,
}) {
  final buffer = StringBuffer('WImage.source(\n');
  if (isNetwork) {
    buffer.writeln("  source: WImageSource.network('https://…'),");
  } else {
    buffer.writeln("  source: WImageSource.asset('assets/demo.png', prefix: false),");
  }
  buffer.writeln('  style: WImageStyle(');
  if (aspectRatio == null) {
    buffer.writeln('    width: ${width.toStringAsFixed(0)},');
    buffer.writeln('    height: ${height.toStringAsFixed(0)},');
  } else {
    buffer.writeln('    aspectRatio: ${aspectRatio.toStringAsFixed(2)},');
  }
  buffer.writeln('    fit: BoxFit.$fitName,');
  buffer.writeln('    borderRadius: BorderRadius.circular(${radius.toStringAsFixed(0)}),');
  if (withBorder) buffer.writeln('    border: Border.all(...),');
  if (withShadow) buffer.writeln('    boxShadow: WShadows.card,');
  if (withMargin) buffer.writeln('    margin: const EdgeInsets.all(8),');
  buffer.writeln('  ),');
  buffer.writeln('  options: WImageLoadOptions(');
  buffer.writeln('    memCacheWidth: $memCache,');
  buffer.writeln('    memCacheHeight: $memCache,');
  buffer.writeln('    retryCount: $retryCount,');
  buffer.writeln('  ),');
  buffer.writeln('  slots: WImageSlots(');
  if (customPlaceholder) buffer.writeln('    placeholder: const _Placeholder(),');
  buffer.writeln('    errorWidget: const _ErrorBox(),');
  buffer.writeln('  ),');
  buffer.writeln('  controller: controller,');
  buffer.writeln('  onLoadStatusChanged: (status) => ...,');
  buffer.writeln('  onProgress: (progress) => ...,');
  buffer.write(')');
  return buffer.toString();
}
