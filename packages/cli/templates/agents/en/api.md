- **Network**: prefer `WApiConfig` + `DioRegistry.forBaseUrl`; a bare `Dio()` must receive `dio:`;
  initialize each baseUrl once; different options/interceptors after the first call throw ArgumentError (dispose first to change config). Store tokens with `w_tools_core`'s `WToken` and inject via
  `WTokenInterceptor` (`tokenGetter` / `tokenClearer` / `tokenRefresher`); 401 retry depends
  on DioRegistry. Use `WLogInterceptor` for logs; sensitive headers are redacted by default.
