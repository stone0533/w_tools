- **Network** (`WApiSettings` + `DioRegistry.forBaseUrl`): never a bare `Dio()`; a raw Dio must receive
  `dio:`; tokens via `WToken` + `WTokenInterceptor`, logging via `WLogInterceptor`.
  Details: `explain WApiSettings`.
- **Calls** (`WApiClient`): GET/POST/PUT/PATCH/DELETE via `WApiClient`; always pass an explicit
  `decode`; never hand-cast `response.data`. Details: `explain WApiClient`.
