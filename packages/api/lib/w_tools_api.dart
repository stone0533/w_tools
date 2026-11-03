// w_tools_api 子包统一导出

export 'src/api.dart';
export 'src/api_config.dart';

// 公开 API 里出现了 dio 类型（WApiConfig.baseOptions / DioRegistry.dio / 拦截器），
// 统一从这里取，消费方不必再手动依赖 dio。
export 'package:dio/dio.dart'
    show
        BaseOptions,
        CancelToken,
        Dio,
        DioException,
        DioExceptionType,
        Headers,
        Interceptor,
        Options,
        RequestOptions,
        Response,
        ResponseType;
