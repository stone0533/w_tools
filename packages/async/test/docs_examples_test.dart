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
}
