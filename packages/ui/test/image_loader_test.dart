import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image_loader.dart';
import 'package:w_tools_ui/src/components/common/image_types.dart';

void main() {
  test('reset / beginAttempt 会推送快照', () {
    final loader = WImageLoader(retryCount: 3, retryDelay: 1000);
    addTearDown(loader.dispose);
    final snapshots = <WImageLoadSnapshot>[];
    loader.state.addListener(() => snapshots.add(loader.state.value));

    loader.reset(retryCount: 3, retryDelay: 1000);
    expect(loader.state.value.attempt, 0);

    loader.beginAttempt();
    expect(loader.state.value.attempt, 1);
    expect(snapshots, isNotEmpty);
  });

  test('status / progress 进入快照', () {
    final loader = WImageLoader(retryCount: 3, retryDelay: 1000);
    addTearDown(loader.dispose);
    loader.markStatus(WImageLoadStatus.loading);
    loader.pendingProgress = const WImageProgress(downloadedBytes: 1, totalBytes: 2);
    loader.emit();
    expect(loader.state.value.isLoading, isTrue);
    expect(loader.state.value.progress?.fraction, 0.5);
  });
}
