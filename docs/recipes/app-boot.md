# 应用启动：用 WApp 串起各子包

一个能跑的应用除了页面，还要在启动期把几件事做对：存储、网络、全局提示、异步执行器、
屏幕适配、首帧收尾。这份配方给出**一份 `WApp` 版本的完整启动代码**，以及每个子包的
启动期要求该放在哪里。

> 只用根包 / 裸 `MaterialApp` 的写法见 [App 根装配](app-shell-theme.md)；那份配方只讲
> 主题与全局提示，不管启动顺序。WApp 项目以本文为准。

## 依赖

```yaml
dependencies:
  w_tools_app_getx: ^3.3.0
  w_tools_core: ^3.2.0
  w_tools_api: ^6.5.0
  w_tools_async: ^8.2.0
  w_tools_toast: ^2.1.1
  w_tools_ui: ^14.2.0

dev_dependencies:
  w_tools_e2e: ^0.3.0   # 只在 tool/main_e2e.dart 里 import
```

可选：需要 ScreenUtil 的 `.w` / `.sp` 时加 `flutter_screenutil`（见下文 `builder`）。

## 完整启动代码

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_core/w_tools_core.dart';
import 'package:w_tools_toast/w_tools_toast.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 1) 存储：必须最先完成，后续 token / 会话都依赖它。
class StoragePlugin extends WAppPlugin {
  @override
  String get name => 'storage';

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  Future<void> onInit() => WStorage.init();
}

/// 2) 网络：依赖存储（token 读取）+ 统一 BaseOptions / 拦截器。
class ApiPlugin extends WAppPlugin {
  @override
  String get name => 'api';

  @override
  List<String> get dependsOn => const ['storage'];

  @override
  Future<void> onInit() async {
    WApiSettings.baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    );
    DioRegistry.forBaseUrl(
      'https://api.example.com',
      interceptors: [
        WTokenInterceptor(
          tokenGetter: WToken.getToken,
          tokenClearer: WToken.clearToken,
          tokenRefresher: () async {
            final refresh = WToken.getRefreshToken();
            if (refresh == null) return null;
            // 换成你的鉴权服务；成功时把新 token 写回 WToken。
            return AuthService.refresh(refresh);
          },
        ),
      ],
    );
  }
}

/// 3) 全局异步执行器：页面 / 仓储用 Get.find<WAsyncExecutor>().run(...)。
class AsyncExecutorPlugin extends WAppPlugin {
  @override
  String get name => 'async-executor';

  @override
  List<String> get dependsOn => const ['api'];

  @override
  Future<void> onInit() async {
    Get.put(
      WAsyncExecutor(
        WAsyncHooks(
          onStart: () => WToast.showLoading(message: '加载中...'),
          onError: WToast.showError,
          onFinally: WToast.hideLoading,
        ),
      ),
    );
  }
}

/// 4) 全局提示的导航观察者（`BotToastInit` 在 builder 里，见下面）。
class ToastPlugin extends WAppPlugin {
  @override
  String get name => 'toast';

  @override
  List<NavigatorObserver>? get navigatorObservers => [BotToastNavigatorObserver()];
}

/// 可选：原生闪屏收尾。没有闪屏插件就删掉。
class SplashPlugin extends WAppPlugin {
  @override
  String get name => 'native-splash';

  @override
  Future<void> onFirstFrame() async {
    // FlutterNativeSplash.remove();
  }
}

Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'Demo',
      home: const HomePage(), // 或 initialRoute + getPages
      localeConfig: WLocaleConfig(
        supportedLanguages: const {'zh_CN': '简体中文', 'en_US': 'English'},
        fallbackLanguage: 'en_US',
        followSystem: true, // 需要固定启动语言时改成 initialLanguage
      ),
      theme: WAppTheme(
        light: AppTheme.light,
        dark: AppTheme.dark,
        mode: ThemeMode.system,
      ),
      plugins: [
        StoragePlugin(),
        ApiPlugin(),
        AsyncExecutorPlugin(),
        ToastPlugin(),
        SplashPlugin(),
      ],
      // MaterialApp 外：没有 Theme / MediaQuery，只放 InheritedWidget 类包装。
      appWrapper: (child) => WAsyncTheme(
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        emptyBuilder: (_) => const Center(child: Text('暂无数据')),
        child: WToastTheme(style: WToastStyle.defaults, child: child),
      ),
      // MaterialApp 内：这里才有 Theme / MediaQuery；.sp 也只能在这里算。
      builder: (context, child) => BotToastInit()(
        context,
        Theme(
          data: Theme.of(context).withWTextStyles(
            WTextStyles.fromTextTheme(Theme.of(context).textTheme),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );

  await app.start();
}
```

需要 ScreenUtil 时把 `builder` 的 `Theme` 外面再包一层（`flutter_screenutil` 的 `.sp`
必须在这里算，不能放 `main()` 顶层）：

```dart
builder: (context, child) => BotToastInit()(
  context,
  ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => WScreenScope(
      widthScaler: (value) => value.w,
      heightScaler: (value) => value.h,
      fontScaler: (value) => value.sp,
      child: child ?? const SizedBox.shrink(),
    ),
  ),
),
```

## 每个子包的启动期要求放哪儿

| 包 | 启动期要求 | 放在 |
|---|---|---|
| `w_tools_core` | `await WStorage.init()` 后才能读写 | 插件 `onInit`（最先，`timeout` 兜底） |
| `w_tools_api` | `WApiSettings.baseOptions`；`DioRegistry.forBaseUrl`；token 读取 | 插件 `onInit`，`dependsOn: ['storage']` |
| `w_tools_toast` | `BotToastInit()` 在 MaterialApp 内；`BotToastNavigatorObserver` | `builder` + 插件 `navigatorObservers` |
| `w_tools_async` | `WAsyncTheme` 子树注入；`WAsyncExecutor` 实例注册 | `appWrapper` + 插件 `onInit`（`Get.put`） |
| `w_tools_async_ui` | 依赖 `WAsyncTheme` | 随 async |
| `w_tools_ui` | `WScreenScope` / `WTextStyles` 在 build 期构建 | `builder` |
| `w_tools_form` | `localizationsDelegates` | `WAppOptions.localizationsDelegates`（默认已含常用语言） |
| `w_tools_qr` | 相机权限 / 生命周期 | 页面级（`WQrView` / `WQrController`），不进启动插件 |
| `w_tools_map_google` | API key / 原生配置 | 平台工程配置，不进启动插件 |
| `w_tools_e2e` | 首屏就绪标记 `E2eSignals.ready`；测试登录 | `tool/main_e2e.dart` 的插件 `onFirstFrame` + `start()` 之后 `E2eLogin.run` |

## E2E 入口（只在 `tool/main_e2e.dart`）

```dart
class E2eReadyPlugin extends WAppPlugin {
  @override
  String get name => 'e2e-ready';

  @override
  Future<void> onFirstFrame() async => E2eSignals.ready();
}

Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'Demo',
      home: const HomePage(),
      plugins: [E2eReadyPlugin()],
    ),
  );
  await app.start();
  await E2eLogin.run(
    login: (email, password) => AuthService.login(email, password),
    afterLogin: () => Get.offAllNamed('/home'),
    beforeLogin: AuthService.clearSession,
  );
}
```

生产 `lib/main.dart` 不得 import `w_tools_e2e`；细节见 [E2E 免登录入口](e2e-login.md)。

## 顺序与常见坑

- 顺序只靠 `WAppPlugin.dependsOn`：不要依赖注册顺序的“恰好”；同层按注册顺序**串行**。
- 关键插件失败会抛 `WAppPluginInitException`（带插件名）；启动失败的兜底页属于应用壳，
  自己 catch + 重试 `start()`。非关键插件（`critical: false`）失败不阻塞启动，再次 `init()`
  只重试失败的插件。
- `appWrapper` 在 MaterialApp **外**：拿不到 Theme / MediaQuery；需要它们放 `builder`。
- `BotToastInit` 必须在 MaterialApp **内**（`builder`），`BotToastNavigatorObserver` 只挂一次：
  插件 `navigatorObservers` 和 `WAppOptions.navigatorObservers` 二选一。
- `WAsyncTheme` / `WToastTheme` 是 `InheritedWidget`，放 `appWrapper` 即可；页面自动读到。
- 语言：`followSystem: true` 时系统变化自动跟随，用户 `app.language.changeLanguage(...)`
  后停止跟随；持久化自己存，恢复时在 `start()` 之前 `changeLanguage(saved)`。
- 主题：`app.setThemeMode(ThemeMode.dark)` 运行时切换；`WAppTheme.mode` 只是初值。
- 测试：`tearDown` 调 `app.dispose()`（移除语言 / 系统语言 / 主题监听）。
