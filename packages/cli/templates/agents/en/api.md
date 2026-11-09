- **Network** (`WApiConfig` + `DioRegistry.forBaseUrl`): never a bare `Dio()`; a raw Dio must receive
  `dio:`; tokens via `WToken` + `WTokenInterceptor`, logging via `WLogInterceptor`.
  Details: `explain WApiConfig`.
