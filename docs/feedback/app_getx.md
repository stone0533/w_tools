# w_tools_app_getx 反馈

## 待处理

（暂无）

## 已确认




### [已确认] app_getx: WAppTheme.systemUiOverlayStyle 只是一次性设置：从浅色状态栏页面返回后不恢复（缺全局兜底）

- 包/版本：w_tools_app_getx 3.1.0（本地检出；`WAppTheme.systemUiOverlayStyle` 字段在 w_tools_app 4.0.1）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26、iPhone 17 模拟器（iOS 26.2）；Android 同理（同一个「缺兜底」问题，iOS 上最明显）
- 命令 / 输入：最小复现（App 声明深色状态栏 → 壳页不标注 → push 一个浅色标注页 → pop）
  ```dart
  const dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,   // Android
    statusBarBrightness: Brightness.light,      // iOS（浅底 → 深色图标）
  );
  const light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  await WApp.options(WAppOptions(
    title: 'demo',
    home: const ShellPage(),                    // 壳页：WScaffold(systemStatusBarStyle: null) / 普通 Scaffold
    theme: const WAppTheme(systemUiOverlayStyle: dark),
  )).start();

  // 壳页里 push 一个「顶部是深色大图」的详情页：
  Get.to(() => const WScaffold(systemStatusBarStyle: light, body: /* ... */));
  // 返回后：状态栏图标仍是浅色（应为深色），直到重启 App 或再遇到一个带 AppBar 的页面。
  ```
- 期望：从浅色状态栏页面返回后，状态栏自动恢复到 `WAppTheme.systemUiOverlayStyle` 声明的样式（本项目是深色图标）。
- 实际：返回后保持浅色。原因：`WApp` 只在启动时**一次性**设置过样式——
  - `packages/app_getx/lib/src/app.dart:159` `_setupSystemUI()` → `:162` `SystemChrome.setSystemUIOverlayStyle(style)`，只在 `start()` 里调一次（`:107`）；
  - `packages/ui/lib/src/components/layout/scaffold.dart:109-114`：`WScaffold` 只有在 `systemStatusBarStyle != null` 时才包 `AnnotatedRegion`，null 就是**完全不标注**；
  - 于是一旦某个页面用 `AnnotatedRegion`（浅色）把状态栏改掉，pop 之后标注随路由销毁，而底层页面没有任何标注 → 引擎保留最后一次的浅色，没有「回落」可言。
  - 反证：本项目里从「兌換獎賞」入口（有 AppBar，`AppBars.style` 里 `systemOverlayStyle: 深色`）进同一个详情再返回，状态栏能正常恢复——说明缺的不是详情页的写法，而是「无标注页面的全局兜底」。
- 影响（我因此做错了什么 / 多花了什么）：iOS 上从「找優惠」tab 进任一详情（兌換詳情 / 優惠券詳情 / 加入申請）返回后，浅色图标压在浅色页面上，状态栏看不清。排查时会先怀疑引擎 / 第三方插件 / 某个页面的 `SystemChrome` 调用，实际是 `WAppTheme.systemUiOverlayStyle` 的「一次性」语义——它看起来像全局默认，但不持久。所有接同一套 `WApp` 管线的项目都会踩，且补在业务侧只能逐个壳页补（漏一个壳就复发）。
- 建议：把「全局样式」从一次性调用升级为**根级兜底 `AnnotatedRegion`**，在 `WApp.run()` 里 `GetMaterialApp` 构建之后（`app.dart:228` 之后、`appWrapper` 之前）加：
  ```dart
  final fallback = _appTheme.systemUiOverlayStyle;
  if (!kIsWeb && fallback != null) {
    app = AnnotatedRegion<SystemUiOverlayStyle>(value: fallback, child: app);
  }
  ```
  - 语义：**页面自己的标注优先**（`WScaffold.systemStatusBarStyle` / `AppBar.systemOverlayStyle`），页面没标注时回落到这里；
  - 保留启动时那次 `SystemChrome` 调用，让首帧之前就是深色，避免启动瞬间闪一下；
  - 不新增必填参数、不改签名；对「完全没用 `AnnotatedRegion` 的项目」行为不变，只修复「有浅色页面」的项目。想留逃生门可以加 `WAppOptions.systemUiFallback: bool = true`；
  - 建议补测试：pump `WApp` 后断言树的根级存在 `AnnotatedRegion<SystemUiOverlayStyle>` 且值 == `WAppTheme.systemUiOverlayStyle`；再 push 一个自带浅色标注的页面，断言两者共存（引擎取最上层）；
  - CHANGELOG / 文档写清：`systemUiOverlayStyle` 是 **fallback**，页面覆盖优先，并说明修复了「从浅色状态栏页面返回后不恢复」。
- 复现数据：
  - 本项目配置：`lib/app/bootstrap.dart` → `theme: const WAppTheme(systemUiOverlayStyle: appSystemUiOverlayStyle)`，`appSystemUiOverlayStyle` 在 `lib/app/ui/app_system_ui.dart`（`statusBarIconBrightness: dark` / `statusBarBrightness: light`）。
  - 壳页无标注：`lib/app/modules/nav/views/nav_view.dart` 的 `AppScaffold(backgroundColor: Colors.white, body: Stack(...))`；`lib/app/modules/mCardExchange/views/m_card_exchange_view.dart` 的 tab 分支 `AppScaffold(body: SafeArea(...))`。
  - 浅色详情页（三处同样的写法）：`lib/app/modules/mCardExchangeDetail/views/m_card_exchange_detail_view.dart`、`lib/app/modules/mCardRequestJoin/views/m_card_request_join_view.dart`、`lib/app/modules/mCardCouponDetail/views/m_card_coupon_detail_view.dart`，都是 `AppScaffold(systemStatusBarStyle: appSystemUiOverlayStyle.copyWith(statusBarIconBrightness: light, statusBarBrightness: dark))`。
  - 有 AppBar 的对照组正常：`lib/app/ui/app_bars.dart` 的 `WAppBarStyle.systemOverlayStyle` = 深色 → 这类页面返回后能恢复。
  - 现象：进入详情后状态栏变浅色，返回列表仍是浅色，重启 App 才恢复深色。
- 关联 issue：#407
- 状态变更：2026-11-25 已确认 → #407

### [已确认] app_getx: 启动期没有可观测性：插件耗时/顺序无日志，行为变化（并行→串行）无人察觉

- 包/版本：w_tools_app_getx 3.1.0（本地检出 `packages/app_getx`；插件契约在 w_tools_app 4.0.1）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；项目 ureward_member_app，启动期 6 个插件（log / env / app-service / pbe / native-splash / toast）
- 命令 / 输入：
  ```dart
  // lib/app/bootstrap.dart:38
  await app.start();   // 没有任何插件耗时/顺序的输出
  ```
- 期望：启动期能被观测——debug 下每个插件打一行（名字、耗时、成功/失败），启动结束打一行摘要，最好还能拿到结构化的 `WAppStartupReport`；这样「谁阻塞了启动」「为什么这次启动变慢」不用靠猜。
- 实际：`_doInit`（`packages/app_getx/lib/src/app.dart:102-117`）只有 `await _pluginRunner.init()`，**没有任何日志或计时**；插件失败只表现为整个 `start()` 抛出。
  更直接的证据：w_tools_app 4.0.0 把「同层插件并行」改成了「按注册顺序串行」（CHANGELOG 有写），但本项目 `lib/app/w/w_plugins.dart:62` 至今还留着「WApp.init() 里所有插件的 onInit 是并行执行的」——**行为变了，项目侧无从察觉**，因为运行时没有任何输出。
- 影响（我因此做错了什么 / 多花了什么）：排查启动慢/启动卡住时只能加临时 `print` 或读源码；插件顺序变化（并行→串行）带来的启动耗时变化无法归因；新同事/CI 也没有稳定的启动诊断信息。
- 建议：
  1. debug（或 `WAppOptions.debugStartupLog: true`）下逐插件输出：`[WApp] plugin env 120ms ok`、`[WApp] plugin pbe 2.0s failed: ...`；
  2. 启动结束输出摘要：`[WApp] started in 480ms（plugins 420ms, first frame 60ms）`；
  3. 暴露 `WAppStartupReport`（每插件耗时/结果、总耗时、首帧时间），测试与埋点可直接断言；
  4. 在 CHANGELOG/README 里把「并行 → 串行」这类**行为变化**标注成需要项目留意的变更（配合上面的日志，项目才能发现）。
- 复现数据：
  - `packages/app_getx/lib/src/app.dart:102-117`（`_doInit`：ensureInitialized → 系统设置 → `_pluginRunner.init()` → customTasks → postFrame，无日志/计时）；
  - `packages/app/lib/src/plugins/app_plugin.dart:11`（文档已写「同层按注册顺序串行」）、w_tools_app CHANGELOG 4.0.0「Changed：同层插件改为串行」；
  - 本项目 `lib/app/w/w_plugins.dart:61-63`（注释仍写「所有插件的 onInit 是并行执行的」——已过期）。
- 关联 issue：#407
- 状态变更：2026-11-25 已确认 → #407

### [已确认] app_getx: 插件 onInit 无超时/关键性标记，启动失败直接白屏没有兜底页

- 包/版本：w_tools_app_getx 3.1.0（本地检出 `packages/app_getx`；`WAppPlugin.onInit` 在 w_tools_app 4.0.1）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；项目 ureward_member_app
- 命令 / 输入：项目启动链路（`lib/main.dart` → `lib/app/bootstrap.dart`）
  ```dart
  // lib/main.dart
  Future<void> main() => bootstrap();

  // lib/app/bootstrap.dart:38
  await app.start();     // 没有 try/catch；main 也没有 runZonedGuarded / ErrorWidget.builder

  // lib/app/w/w_plugins.dart:149-157（启动期插件，顺序即注册顺序）
  [LogPlugin(), EnvPlugin(), AppServicePlugin(), PbePlugin(), SplashPlugin(), ToastPlugin()]
  ```
  任一插件 `onInit` 抛错（`.env` 资源缺失、`Application.init()` 内部失败、PBE 通道不可用等），或某个插件卡住不返回（网络/原生通道）。
- 期望：
  1. 插件可以有**超时**（例如默认 10s），超时按失败处理并报出插件名，而不是无限期卡住启动；
  2. 插件可以有**非关键**标记（`critical: false`）：失败只记日志、继续启动；
  3. 启动失败时能渲染一个**兜底页面**（可配置 `startupErrorBuilder`），至少显示「哪个插件失败 + 重试」，而不是白屏/停在闪屏。
- 实际：三者都没有。
  - `WAppPlugin` 只有 `onInit`，没有 timeout / critical；
  - `WAppOptions`（`packages/app_getx/lib/src/options.dart`）没有 `startupErrorBuilder` / `onStartupError`；
  - 某个插件抛错会让 `app.start()` 抛出，而 `bootstrap` 没有 catch、`main` 也没有全局错误兜底（项目里 grep 不到 `runZonedGuarded` / `FlutterError.onError` / `ErrorWidget.builder`）→ **`runApp` 不会执行，用户看到白屏**；因为 `SplashPlugin` 在清单第 5 位，前面任一插件失败时它还没执行，原生闪屏也不会被 preserve，视觉上就是「打开 App 一片空白」。
  - 卡住的情况更糟：没有超时，界面上什么都不会出现，只能看日志/抓堆栈。
  - 项目已经在绕：`PbePlugin` 的注释特意写「建立通道、后台拉 deviceId、**不阻塞首帧**」（`lib/app/w/w_plugins.dart:105-107`），本质是在没有 `critical: false` 的情况下手工规避。
- 影响（我因此做错了什么 / 多花了什么）：启动期失败（尤其 `.env`/存储/原生通道）在真机上表现为「白屏/闪一下就没」，没有任何可操作提示；测试同学只能截图给开发，开发再去 `flutter run` 捞日志。没有超时意味着一个挂住的插件会让 App 永远起不来，而且 QA 无法区分「慢」和「卡死」。
- 建议：
  1. `WAppPlugin` 增加 `Duration get timeout => const Duration(seconds: 10);` 与 `bool get critical => true;`；`WAppPluginRunner` 对每个 `onInit` 施加超时，超时/失败时：
     - `critical: true` → 中断启动并抛出带插件名的错误；
     - `critical: false` → 记日志、继续下一个插件；
  2. `WAppOptions` 增加 `startupErrorBuilder`（或 `onStartupError`），`WApp.start()` 捕获启动异常后 `runApp` 一个兜底页（显示失败插件名 + 重试按钮 + 日志入口）；
  3. 与「启动可观测性」那条配合：失败插件名、耗时、超时都进日志/`WAppStartupReport`；
  4. README 补「启动失败排查」一节（超时默认值、critical 语义、兜底页怎么配）。
- 复现数据：
  - `packages/app/lib/src/plugins/app_plugin.dart:22-75`（`onInit` 无 timeout/critical）；`packages/app_getx/lib/src/plugins/app_plugin_runner.dart:60-61`（`await plugin.onInit()` 无超时）；
  - `packages/app_getx/lib/src/options.dart`（`WAppOptions` 无 `startupErrorBuilder`）；
  - 本项目：`lib/app/bootstrap.dart:38`（裸 `await app.start()`）、`lib/main.dart`（`Future<void> main() => bootstrap()`，无全局错误处理）；`lib/app/w/w_plugins.dart:149-157`（SplashPlugin 排第 5 位）。
  - 观察：`.env` 缺失/端口不可达这类启动期失败，真机表现是白屏，`flutter run` 日志里能看到异常，但界面上没有任何提示。
- 关联 issue：#407
- 状态变更：2026-11-25 已确认 → #407

### [已确认] app_getx: 缺测试宿主：49 个测试文件各自手搭 ScreenUtilInit + MaterialApp，外壳装配没有统一入口

- 包/版本：w_tools_app_getx 3.1.0 / w_tools_app 4.0.1 / w_tools_cli 2.9.7（本地检出，均为最新）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；项目 ureward_member_app（`test/` 下 49 个 widget 测试文件）
- 命令 / 输入：
  ```bash
  # 现状：49 个测试文件各自手搭脚手架
  grep -rl ScreenUtilInit test | wc -l    # → 49
  ```
  每个文件都是同一段样板（以 `test/home/home_banner_state_test.dart:38-50` 为例）：
  ```dart
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),     // 运行时 appWrapper 用的是 Size(375, 0)
      builder: (_, __) => MaterialApp(home: HomeView()),
    ),
  );
  ```
- 期望：有一个「测试宿主」把与运行时一致的外壳装配起来，测试只写业务：
  ```dart
  await pumpWApp(tester, child: const HomeView());
  // 内部：ScreenUtilInit(designSize) + Theme(extensions: WTextStyles) + WFormTheme
  //       + WLanguageScope + WAppScope
  ```
  形态可以二选一：
  1. 独立包/入口（`w_tools_test` 或 `w_tools_app_getx/testing.dart`，仅 dev_dependency 用，**不要**让 `flutter_test` 进运行包）；
  2. 或退一步：`w_tools_cli init` 生成 `test/support/pump_app.dart` starter（项目只填 `appWrapper` / `builder` / `designSize`）。
- 实际：没有这个入口。项目里 49 处复制粘贴，且已经出现**不漂移就是不统一**的情况：
  - 运行时 `appWrapper` 用 `ScreenUtilInit(designSize: Size(375, 0))`（`lib/app/w/w_plugins.dart:17`），测试普遍写 `Size(375, 812)`（`test/home/home_banner_state_test.dart:41`）；
  - 主题扩展 / `WFormTheme` / `WLanguageScope` 要不要装，靠每个人记得；漏一处就是「测试里字段高度不对 / 表单图标不显示」这类假失败。
- 影响（我因此做错了什么 / 多花了什么）：每加一个测试文件先抄 10 行样板；样板出问题要改 49 个文件；新同事写测试时先踩一遍「忘了 WFormTheme/ScreenUtil」的坑。今天改 OTP 测试时也顺手复制了同一段样板。
- 建议：
  1. 优先做「模板 starter」：`init` 生成 `test/support/pump_app.dart`（低风险、不引入新包、不把测试依赖带进运行时）；
  2. 若希望跨项目统一，做独立 `w_tools_test`（dev_dependency）提供 `WAppTestHost` / `pumpWApp`，参数为 `designSize`、`appWrapper`、`builder`、`theme`、`child`；`w_tools_app_getx` 只暴露 `WAppScope`/`WLanguageScope` 需要的部分；
  3. 顺带（可选）：`WAppTheme` 在 4.0.0 删掉了 `copyWith`，测试里想只改一个主题字段就得整份重写；可以加一个标注「测试用」的 `WAppTheme.forTest(...)` / `copyWith`，避免为了测试用例复制整段配置。
- 复现数据：
  - `grep -rl ScreenUtilInit test | wc -l` → **49**；
  - 样板示例：`test/home/home_banner_state_test.dart:38-50`；运行时 wrapper：`lib/app/w/w_plugins.dart:14-24`（`designSize: Size(375, 0)`）；
  - 主题装配现状（每个测试要么自己拼、要么不拼）：`lib/app/w/w_plugins.dart:30-37` 的 `buildAppBuilder`（`Theme(copyWith(extensions: [buildAppTextStyles()]))` + `WFormTheme`）；
  - 相关库位置：`packages/app_getx/lib/src/app.dart:251-270`（appWrapper / WAppScope / WLanguageScope 的装配点）。
- 关联 issue：#407
- 状态变更：2026-11-25 已确认 → #407

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
