- **Network**: use `WApiConfig` + `DioRegistry.forBaseUrl`, never `Dio()` directly;
  initialize each baseUrl once; different options/interceptors after the first call throw ArgumentError (dispose first to change config). Store tokens with `w_tools_core`'s `WToken` and inject via
  `WTokenInterceptor` (`tokenGetter` / `tokenClearer` / `tokenRefresher`); 401 retry depends
  on DioRegistry. Use `WLogInterceptor` for logs; sensitive headers are redacted by default.
