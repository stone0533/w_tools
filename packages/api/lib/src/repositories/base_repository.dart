/// 本地数据源基础类，所有本地数据源都应继承此类
abstract class BaseLocalDataSource {}

/// 网络数据源基础类，所有网络数据源都应继承此类
abstract class BaseRemoteDataSource {}

/// 数据仓库基础类：整合本地数据源与网络数据源
///
/// [LocalDataSourceType] 需继承 [BaseLocalDataSource]，
/// [RemoteDataSourceType] 需继承 [BaseRemoteDataSource]。
abstract class BaseRepository<
  LocalDataSourceType extends BaseLocalDataSource?,
  RemoteDataSourceType extends BaseRemoteDataSource?
> {
  /// 本地数据源实例
  final LocalDataSourceType? localDataSource;

  /// 网络数据源实例
  final RemoteDataSourceType? remoteDataSource;

  /// 构造函数
  ///
  /// @param localDataSource 本地数据源实例
  /// @param remoteDataSource 网络数据源实例
  BaseRepository({this.localDataSource, this.remoteDataSource});
}
