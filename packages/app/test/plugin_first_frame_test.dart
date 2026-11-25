import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _SplashPlugin extends WAppPlugin {
  _SplashPlugin(this.binding);

  final WidgetsBinding binding;

  @override
  String get name => 'splash';

  @override
  Future<void> onFirstFrame() async {
    // 与 FlutterNativeSplash.remove() 相同：只 allowFirstFrame，不自己排帧。
    binding.allowFirstFrame();
  }
}

void main() {
  testWidgets('firstFrame 在 post-frame 里 allowFirstFrame 后会补排一帧', (tester) async {
    final binding = tester.binding;
    binding.deferFirstFrame();

    await tester.pumpWidget(const SizedBox());
    await tester.pump(); // 首帧被 defer，未 composite

    final runner = WAppPluginRunner([_SplashPlugin(binding)]);
    await runner.init();

    late Future<void> firstFrame;
    binding.addPostFrameCallback((_) {
      firstFrame = runner.firstFrame();
    });
    binding.scheduleFrame();
    await tester.pump(); // 回调处于 postFrameCallbacks
    await firstFrame;

    // 没有补排这一帧时，allowFirstFrame 的 scheduleWarmUpFrame 在
    // postFrameCallbacks 阶段直接 return，hasScheduledFrame 为 false。
    expect(binding.hasScheduledFrame, isTrue);

    await tester.pump();
    expect(binding.sendFramesToEngine, isTrue);
  });
}
