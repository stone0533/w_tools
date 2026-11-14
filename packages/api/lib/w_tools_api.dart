// w_tools_api 子包统一导出

export 'src/api.dart';

// 公开 API 里出现了 dio 类型（WApiSettings.baseOptions / DioRegistry.dio / 拦截器），
// 统一从这里取，消费方不必再手动依赖 dio。自定义拦截器需要的 handler 也一并导出。
export 'package:dio/dio.dart'
    show
        BaseOptions,
        CancelToken,
        Dio,
        DioException,
        DioExceptionType,
        ErrorInterceptorHandler,
        FormData,
        Headers,
        HttpClientAdapter,
        Interceptor,
        InterceptorsWrapper,
        ListFormat,
        MultipartFile,
        Options,
        ProgressCallback,
        QueuedInterceptor,
        RequestInterceptorHandler,
        RequestOptions,
        Response,
        ResponseBody,
        ResponseInterceptorHandler,
        ResponseType;
