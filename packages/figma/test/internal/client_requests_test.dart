import 'package:test/test.dart';
import 'package:w_tools_figma/src/client/figma_client.dart';

class _Fake implements FigmaClient {
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    return const <String, dynamic>{};
  }

  @override
  void close() {}
}

void main() {
  test('FigmaClientRequests 的类型化端点', () async {
    final client = _Fake();

    await client.fileNodes('K', '1:2', depth: 2);
    await client.fileImages('K', '1:2', scale: 3);
    await client.fileMeta('K');
    await client.me();

    expect(client.calls.map((uri) => uri.toString()), <String>[
      'https://api.figma.com/v1/files/K/nodes?ids=1:2&depth=2',
      'https://api.figma.com/v1/images/K?ids=1:2&format=png&scale=3',
      'https://api.figma.com/v1/files/K/meta',
      'https://api.figma.com/v1/me',
    ]);
  });
}
