import 'dart:typed_data';

import 'package:w_tools_api/w_tools_api.dart';

/// 示例模型：手写 `fromJson`。
///
/// Dart / Flutter 没有反射，`WApiClient` 不会自动把 JSON 变成模型；
/// 必须把映射显式传给 `decode`（或用 json_serializable / freezed 生成）。
class DemoUser {
  const DemoUser({required this.id, required this.name});

  factory DemoUser.fromJson(Map<String, dynamic> json) => DemoUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

/// 一个领域 API：URL、方法和解码都收敛在这里。
class DemoUserApi {
  DemoUserApi(this._client);

  final WApiClient _client;

  Future<DemoUser> me({int id = 42}) => _client.get(
    '/users/{id}',
    pathParameters: {'id': '$id'},
    query: {'include': 'profile'},
    decode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
  );

  Future<DemoUser> create(String name) => _client.post(
    '/users',
    body: WApiBody.json({'name': name}),
    decode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
  );

  Future<void> remove(int id) => _client.delete<void>(
    '/users/{id}',
    pathParameters: {'id': '$id'},
    decode: (json) {},
  );

  Future<WPage<DemoUser>> page({int page = 1, int pageSize = 20}) => _client.page(
    '/users',
    query: WPageQuery(page: page, pageSize: pageSize),
    itemDecode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
  );

  /// total 在响应头（如 `X-Total-Count`）时，用 readTotalFromResponse。
  Future<WPage<DemoUser>> pageWithHeaderTotal({
    int page = 1,
    int pageSize = 20,
  }) => _client.page(
    '/users',
    query: WPageQuery(page: page, pageSize: pageSize),
    itemDecode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
    readTotalFromResponse: (response) =>
        int.tryParse(response.headers.value('x-total-count') ?? ''),
  );

  /// send 保留 status / headers；普通 get/post 只返回 data。
  Future<WApiResponse<DemoUser>> meRaw({int id = 42}) => _client.send(
    'GET',
    '/users/{id}',
    pathParameters: {'id': '$id'},
    decode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
  );

  /// 单条请求临时覆盖信封，不影响 client 级配置。
  Future<DemoUser> meWithEnvelope({int id = 42}) async {
    final response = await _client.send<DemoUser>(
      'GET',
      '/envelope/users/{id}',
      pathParameters: {'id': '$id'},
      envelope: _envelope,
      decode: (json) => DemoUser.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  /// 下载并保留 headers（文件名 / Content-Type）。
  Future<WApiResponse<Uint8List>> downloadAvatar() => _client.downloadResponse('/users/me/avatar');

  Future<void> uploadAvatar(List<int> bytes) => _client.upload<void>(
    '/users/me/avatar',
    fields: const {'bucket': 'avatar'},
    files: {'file': MultipartFile.fromBytes(bytes, filename: 'avatar.png')},
    decode: WApiDecoders.none,
  );
}

const _envelope = WApiEnvelopeParser(
  readCode: _readCode,
  readData: _readData,
  isSuccess: _isSuccess,
);

Object? _readCode(Object? json) => (json as Map)['code'];
Object? _readData(Object? json) => (json as Map)['data'];
bool _isSuccess(Object? code) => code == 0;
