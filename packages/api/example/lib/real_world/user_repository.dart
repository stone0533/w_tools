import 'package:w_tools_api/w_tools_api.dart';

import 'api_exception.dart';

/// 用户实体
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );

  final int id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  @override
  String toString() => 'User($id, $name, $email)';
}

/// 本地数据源：示例用内存；真实项目可换成 `WStorage` / 数据库。
class UserLocalDataSource extends BaseLocalDataSource {
  User? _cached;

  /// 当前缓存（测试 / 调试用）
  User? get cached => _cached;

  Future<User?> read() async => _cached;

  Future<void> write(User user) async => _cached = user;
}

/// 远程数据源：只依赖 [Dio]，不关心 token / 基地址。
class UserRemoteDataSource extends BaseRemoteDataSource {
  UserRemoteDataSource(this._dio);

  final Dio _dio;

  Future<User> fetchMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      return User.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      // 在数据源边界把 dio 异常翻译成业务异常，UI 不再依赖 dio。
      throw ApiException.from(error);
    }
  }
}

/// Repository：组合本地缓存与远程数据源，对上层只暴露业务方法。
class UserRepository extends BaseRepository<UserLocalDataSource, UserRemoteDataSource> {
  UserRepository({super.localDataSource, super.remoteDataSource});

  /// 读取当前用户；[forceRefresh] 为 true 时跳过缓存。
  Future<User> me({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localDataSource?.read();
      if (cached != null) return cached;
    }

    final remote = await remoteDataSource!.fetchMe();
    await localDataSource?.write(remote);
    return remote;
  }
}
