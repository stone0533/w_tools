import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

class Gift {
  const Gift(this.name);
  final String name;
}

class GiftList extends StatelessWidget {
  const GiftList(this.gifts, {super.key});
  final List<Gift> gifts;

  @override
  Widget build(BuildContext context) {
    return Text(gifts.map((e) => e.name).join(','));
  }
}

final api = _Api();

class _Api {
  Future<List<Gift>> gifts() async => const [Gift('gift')];
  Future<Gift> gift(String id) async => Gift(id);
  Future<List<String>> mobileRegionCodes() async => const ['code'];
  Future<List<String>> registerColumnList() async => const ['column'];
  Future<List<String>> homeBanners() async => const ['banner'];
}

/// README 快速开始的完整形态；保持编译即文档回归。
class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  late final WAsyncController<List<Gift>> _gifts;

  @override
  void initState() {
    super.initState();
    _gifts = WAsyncController.list(() => api.gifts());
    _gifts.load();
  }

  @override
  void dispose() {
    _gifts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WAsyncView<List<Gift>>(
      state: _gifts.state,
      onRetry: _gifts.load,
      readyBuilder: (context, gifts) => GiftList(gifts),
    );
  }
}

void main() {
  testWidgets('README 快速开始可运行', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GiftPage()));
    await tester.pumpAndSettle();
    expect(find.text('gift'), findsOneWidget);
  });

  test('README tryRun 结果解构可编译', () async {
    final result = await WAsync.tryRun(() => api.gift('1'));
    switch (result) {
      case WAsyncSuccess(:final value):
        expect(value.name, '1');
      case WAsyncFailure(
        :final error,
        :final stackTrace,
        :final isProgrammingError,
      ):
        expect(error, isNotNull);
        expect(stackTrace, isNotNull);
        expect(isProgrammingError, isFalse);
      case WAsyncCancelled(:final reason):
        fail('unexpected cancel: $reason');
    }
  });

  test('独立区块 record .wait 示例可编译并保留每个结果', () async {
    final (codes, columns, banners) = await (
      WAsync.tryRun(() => api.mobileRegionCodes()),
      WAsync.tryRun(() => api.registerColumnList()),
      WAsync.tryRun(() => api.homeBanners()),
    ).wait;

    expect(codes, isA<WAsyncSuccess<List<String>>>());
    expect(columns, isA<WAsyncSuccess<List<String>>>());
    expect(banners, isA<WAsyncSuccess<List<String>>>());
  });

  test('parallel<WAsyncResult<Object?>> 示例可编译', () async {
    final results = await WAsync.parallel<WAsyncResult<Object?>>([
      WAsync.tryRun<Object?>(() => api.mobileRegionCodes()),
      WAsync.tryRun<Object?>(() => api.registerColumnList()),
      WAsync.tryRun<Object?>(() => api.homeBanners()),
    ]);

    expect(results, hasLength(3));
    expect(results.every((result) => result.isSuccess), isTrue);
  });

  test('README settle 示例可编译并保留每个结果', () async {
    final results = await WAsync.settle<Gift>([
      () => api.gift('1'),
      () => api.gift('2'),
    ]);

    expect(results, hasLength(2));
    for (final result in results) {
      switch (result) {
        case WAsyncSuccess(:final value):
          expect(value, isA<Gift>());
        case WAsyncFailure(:final error):
          fail('unexpected failure: $error');
        case WAsyncCancelled(:final reason):
          fail('unexpected cancel: $reason');
      }
    }
  });

  test('README retry 退避示例可编译', () async {
    var attempts = 0;
    final value = await WAsync.retry<String>(
      () async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return 'ok';
      },
      retryCount: 1,
      retryDelayBuilder: (attempt) => Duration.zero,
      onRetry: (attempt, error, delay) {},
    );

    expect(value, 'ok');
  });

  test('README listWithToken / replaceData 示例可编译', () async {
    final controller = WAsyncController.listWithToken<Gift>(
      (token) async => const [Gift('gift')],
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.replaceData(const [Gift('local')]);

    expect(controller.state.value.data!.single.name, 'local');
  });
}
