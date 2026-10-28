import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

class _ChunkProvider extends ImageProvider<_ChunkProvider> {
  _ChunkProvider(this.bytes);

  final Uint8List bytes;

  @override
  Future<_ChunkProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ChunkProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ChunkProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunks = StreamController<ImageChunkEvent>();
    final completer = Completer<ui.Codec>();
    () async {
      try {
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final codec = await decode(buffer);
        chunks.add(
          const ImageChunkEvent(
            cumulativeBytesLoaded: 1,
            expectedTotalBytes: 2,
          ),
        );
        await chunks.close();
        completer.complete(codec);
      } catch (error, stack) {
        completer.completeError(error, stack);
        await chunks.close();
      }
    }();

    return MultiFrameImageStreamCompleter(
      codec: completer.future,
      chunkEvents: chunks.stream,
      scale: 1.0,
    );
  }
}

void main() {
  testWidgets('WImageTheme.defaultProgressBuilder 用于网络/字节进度', (tester) async {
    final provider = _ChunkProvider(base64Decode(_redPixel));

    await tester.pumpWidget(
      WImageTheme(
        data: WImageThemeData(
          defaultProgressBuilder: (context, url, progress) => const Text('THEME_PROGRESS'),
        ),
        child: MaterialApp(
          home: WImage.provider(
            provider,
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('THEME_PROGRESS'), findsOneWidget);
  });
}
