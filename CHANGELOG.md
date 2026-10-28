## 3.0.0

- 依赖：`w_tools_ui` 提升到 `^2.0.0`。
- `w_tools_ui 2.0.0` 为破坏性版本：移除旧进度 API、`cacheEnabled`、`fitCenter`，
  `WImageConfig.size` 改为 `dimensions` / `square`。详见 `packages/ui/CHANGELOG.md`。

## 2.0.1

- 修复发布物：2.0.0 的 pubspec 带上了仓库的 `workspace:` 字段（指向 `packages/core` 等），
  消费方 `dart pub deps` 会去 pub 缓存里找这些不存在的目录并以退出码 66 失败。
  现在发布改由 `scripts/publish_package.sh` 在暂存副本里执行，发布物不再包含
  `workspace:` / `resolution: workspace`；CI 的发布预演也走同一脚本。
  脚本默认指向 `https://pub.dev`，不受本地 `PUB_HOSTED_URL` 镜像影响
  （需要其它 host 时设 `PUBLISH_HOSTED_URL`）。
- 修复：根包 `WConfig.assetImagePath` / `WConfig.setup.assetImagePath` 此前转发到
  `w_tools_core` 的 `WConfig.assetImagePath`，但该字段从未被任何代码读取，真正生效的是
  `w_tools_ui` 的 `WAssets.imagePath` —— 于是设置 `WConfig.assetImagePath` 后
  `'logo.png'.assetImagePath` 不会变化。现在兼容层直接代理 `WAssets.imagePath`，
  两个入口等价。
- 依赖：`w_tools_ui: ^1.1.0`、`w_tools_map: ^1.2.0`、`w_tools_core: ^1.0.1`、`w_tools_form: ^1.0.1`；
  这样新装聚合包的用户不会停在旧子包上（已有 lockfile 的项目仍需 `pub upgrade` 才会升级）。
  其中 form 1.0.1 修复了 1.0.0 在 Flutter 3.38+ 的编译失败。
- 文档：根 README 不再硬编码各包「当前版本」，改为以各包 pubspec / pub.dev 为准；
  新增 `docs/releasing.md` 与 `scripts/release_check.sh`，把版本与发布约束变成可执行检查。

## 2.0.0

> 根包 2.0.0 是聚合版的首个 Major：8 个子包各自以 `1.0.0` 独立发布，本节记录随聚合版带入根包的变更与迁移要求。

### w_tools（根包）
- **Breaking**: 根包由「单体工具库」改为「8 个子包的聚合包」：依赖 `w_tools_core` / `w_tools_app` / `w_tools_form` / `w_tools_ui` / `w_tools_api` / `w_tools_toast` / `w_tools_map` / `w_tools_qr`（`^1.0.0`），通过 `package:w_tools/w.dart` 统一导出；实现代码移至各子包，根包只保留 `WConfig` 聚合配置兼容层
- 根包不再直接依赖 `get` / `dio` / `flutter_screenutil` 等第三方库（改由各子包承担）；需要 `WApp` 启动器时 `get` 仍随 `w_tools_app` 传递引入

### w_tools_app
- **Breaking**: `WApp.run()` 在未调用 `init()` 时抛 `StateError`（此前会静默继续，
  导致 .env 未加载、业务服务未就绪等难以定位的启动时序问题）。迁移方式：改用
  `await app.start(...)`，或保证 `run()` 之前已 `await app.init()`
- 新增 `WApp.start()`：一站式启动入口（等价于 `await init()` + `run()`），
  避免调用方遗漏 `init()`
- 新增 `WAppPlugin.dependsOn`：声明插件初始化依赖，`init()` 按依赖分层执行
  （同层并行、跨层串行）；依赖了未注册的插件名或存在循环依赖时抛 `StateError`
- `WApp.init()` 改为幂等：重复调用只执行一次插件 `onInit`，避免与 `start()` 混用时重复初始化
- 修正 `WAppPlugin` 的生命周期文档注释：实际顺序为「ensureInitialized → 系统设置 →
  插件 onInit → customTasks → onLazyInit → runApp」，原注释把系统设置与 onInit 写反了
- 补充 `WApp` 生命周期与插件依赖分层的单元测试（9 个用例）
- 新增 `WApp.systemUiOverlayStyle`：可配置状态栏 / 导航栏样式，默认沿用原硬编码样式，置 `null` 表示不干预
- **Breaking**: `WGet` 重命名为 `WRoute`（文件 `get.dart` → `route.dart`），类名与「路由操作」职责对齐，并与 `WRouteObserver` 形成命名配对
- **Breaking**: `WRoute.removeRouteUntil` 重命名为 `WRoute.removeRoutesAfter`：语义为「移除指定路由之上的路由（保留其本身）」，且无匹配时不再清空全部，改为不执行任何操作
- **Breaking**: `WRoute.routes` 由可变列表改为只读快照；路由记录改由 `WRoute.addRoute` / `WRoute.removeRoute` / `WRoute.clearRoutes` 维护
- **Breaking**: `WRoute` 方法改名：`removeRouteIfExistByName` → `removeRouteIfExists`（修正语法）、`until` → `popUntilRoute`、`bottomSheet` → `showBottomSheet`
- **Breaking**: `WGetXRouterObserver` → `WRouteObserver`（去掉类名中的 "GetX"；该类本身并不依赖 GetX）
- **Breaking**: `WLanguage.getCurrentLanguageName()` / `getCurrentLocale()` 改为 getter：`currentLanguageName` / `currentLocale`
- **Breaking**: `WRoute.showBottomSheet` 拆出为独立工具类 `WBottomSheet.show()`，`WRoute` 回归纯路由工具
- **Breaking**: `WAppPlugin.wrapBuilder()` 重命名为 `builderWrapper`（改为 getter；与 `wrapApp()` 区分：前者提供 builder 包裹，后者包裹整个 app）
- `WApp` 配置从「私有字段 + setter/getter」改为**公开字段**（读取/赋值用法不变）；另新增只读 getter `plugins` / `isInitialized`
- `WApp.run()` 参数校验异常由 `Exception` 改为 `StateError`；移除未知路由静默回落首页的 `onGenerateRoute`
- **Breaking**: `WStateConfig` 重命名为 `WAppConfig`（文件 `state_config.dart` → `app_config.dart`），与子包 `w_tools_app` 对齐，统一 `W<子包>Config` 家族
- `WLanguage.listenLanguageChange` 返回 `StreamSubscription<String>`，支持调用方取消订阅以避免内存泄漏
- `WLanguage.supportedLanguages` 改为实时读取 `WAppConfig`，运行期新增语言立即可用
- 消除语言状态的「双真相源」：`WLanguage.changeLanguage` 现在会同步写回 `WAppConfig.currentLanguage`（唯一真源），`WLanguage.currentLanguage` 也改为直接读取它
- `WAppConfig.supportedLanguages` 改为「只读 getter（不可变快照）+ 拷贝式 setter」，禁止就地修改、避免外部 map 与内部状态别名
- `WAppPlugin` 由 `abstract class` 改为 `abstract mixin class`：插件可同时继承其他基类（`class X extends Base with WAppPlugin`）；`extends` / `implements` 用法保持兼容
- 修复 `WRouteObserver` 未处理 `didReplace` / `didRemove` 导致的路由记录漂移：`Navigator.pushReplacement`（或 `removeRoute`）之后 `WRoute.routes` 会残留旧路由 / 缺失新路由，进而使 `removeRoutesAfter` / `removeRouteIfExists` 定位错误
- 修复 `WRoute.popUntilRoute` 在目标路由不存在时会**弹空整个路由栈**（`Get.until` 委托 `Navigator.popUntil`，条件永不满足即持续 pop）；现改为先行校验、不存在则不动作，与 `removeRoutesAfter` 语义一致

### w_tools_core
- 修复 `WEncrypt.base64Decode` 对非 ASCII 内容（中文、emoji）解码乱码的问题：改用 `utf8.decode` 替换 `String.fromCharCodes`
- `WEncrypt.aesEncrypt` 未显式传入 IV 时改用 `IV.fromSecureRandom(16)` 生成安全随机 IV，不再依赖 `IV.fromLength` 的版本相关语义（该方法在 `encrypt` 5.0.1 为全零、5.0.3 起才改为安全随机；当前解析版本 5.0.3 已安全，本次为显式加固）
- 新增测试：默认 IV 长度为 16 字节、非全零，且两次加密的 IV 不同
- 修复 `WAsync.runWithRetry` 最终失败时 `onError` 被调用两次的问题（内部先上报、`_executeWithLoading` 再上报）
- `WAsync.runAllWithConcurrency` 增加 `concurrency >= 1` 校验并抛出 `ArgumentError`，避免并发数小于 1 时批次大小为 0 导致死循环
- 修复 `WAsyncConfig` 并发执行时加载状态提前结束的问题：`onLoadingStart` / `onLoadingEnd` 改为按活动操作数合并（0→1 触发开始、1→0 触发结束），共享同一配置的并发操作不再提前隐藏 loading
- **Breaking**: `WAsync.waitWithConcurrency` / `WAsyncConfig.waitWithConcurrency` 更名为 `runAllWithConcurrency`，并改为接收 `Iterable<Future<T> Function()>` 任务工厂，仅在并发槽位可用时调用，从而真正限制同时执行的任务数（此前传入的 Future 已全部启动，只限制了等待批次）
- `WCancelToken.addListener` 在 token 已取消时会立即以取消原因回调；`cancel()` 改为遍历回调副本，允许回调内部增删监听
- `WAsync` 的 `onLoadingStart` / `onLoadingEnd` / `onError` 回调若自身抛异常会被忽略，不再破坏「不向调用方抛出」的约定
- `WAsync.runWithRetry` 在重试等待期间响应取消，不再等待完整 `retryDelay`
- `WAsync.runWithRetry` 仅对 `task` 抛出的业务异常（`Exception`）重试；`onSuccess` 抛出的异常不再触发重试，避免重复执行有副作用的请求
- `WAsync.runWithRetry` / `WAsyncConfig.runWithRetry` 新增可选参数 `retryIf`，可按异常类型过滤重试范围；不传时保持「重试所有 `Exception`」的行为
- `WAsync` 在操作开始前已取消时直接返回 null，不再触发 `onLoadingStart` / `onLoadingEnd`（避免 loading 闪烁）
- `WAsync.runWithTimeout` / `any` 文档补充：超时或被淘汰的 Future 不会被取消，仍会继续执行；`any` 空集合返回 null
- **Breaking**: `WAsync` 不再把编程错误（`Error`，如 `TypeError` / `StateError`）当作业务异常：`Error` 会原样向上抛出且不触发 `onError`，`runWithRetry` 也不再重试 `Error`（此前会被静默吞掉并重试，掩盖真实缺陷）；`Exception` 的处理行为不变
- `WAsync.wait` / `WAsync.any` 在等待期间响应取消：`cancel()` 后立即返回 null，不再等到全部 / 首个 Future 完成；已启动的 Future 仍会继续执行
- **Breaking**: `WAsync.sequence` / `WAsyncConfig.sequence` 的 `tasks` 参数由 `List` 放宽为 `Iterable`（`List` 仍可直接传入）；`WAsync` 增加私有构造以禁止实例化（与 core 其它纯静态工具类一致）
- `WAsync.runWithRetry` 增加 `retryCount >= 0` / `retryDelay >= 0` 校验，`WAsync.runWithTimeout` 增加 `timeout >= 0` 校验，非法值以失败的 Future 抛出 `ArgumentError`
- `WAsync.any` 空集合直接返回 null，不再触发一次无意义的 loading 开始 / 结束回调
- 测试补充：`fallbackOnError` 优先级、`copyWith`、`retryCount = 0`、参数校验、`sequence` 遇错停止、`runAllWithConcurrency` 取消后不再启动新任务、`any` 空集合不触发 loading
- 修复正数类正则接受 0 的问题：`positiveNumber` / `positiveInteger` / `positiveDecimal` 现在排除 0，与 `WValidator.isPositive` / `isValidPositiveInteger` / `isValidPositiveDecimal` 语义一致
- `WValidator.isNumeric` / `isPositive` / `isNonNegative` 现在拒绝 `NaN` / `Infinity`，只接受有限数字
- 修正 `WHash.hashPassword` 文档：实现为加盐单轮 SHA-256（非 HMAC-SHA256），并注明不适用于高安全密码存储，高安全场景请使用 bcrypt / Argon2
- 修复邮箱正则未以 `$` 结尾导致的「前缀匹配」问题（如 `a@example.com<script>` 此前可通过）；字符集收敛为 `[a-zA-Z0-9._%+-]`，与 `WValidator.isValidEmail` 一致
- 修复日期校验：`WValidator.isValidDate` / `isValidDateTime` 现在会校验真实日期范围（`2023-02-30`、`2023-13-01`、`2023-00-10` 不再通过；闰年 `2024-02-29` 正常通过）
- **Breaking**: `WStorage` 读取方法（`getString` / `getInt` / `getBool` / `getDouble` / `getStringList` / `getObject` / `containsKey` / `allKeys`）在未初始化时抛出 `StateError`（此前静默返回默认值，导致「未初始化」被误判为「没有数据」）；`allKeys()` 返回类型由 `Set<String>?` 改为 `Set<String>`
- **Breaking**: `WToken` 移除独立的静态内存缓存，`getToken` / `getRefreshToken` 直接读取 `WStorage`（SharedPreferences 本身已有内存缓存）；因此 `WStorage.clear()` 后不再返回残留 token
- `WToken.saveToken` 在未传过期时间时会清除旧的过期时间，避免新 token 沿用旧的过期状态
- `WLogger.setLevel` / `WLogger.turnOff` 复用既有 `PrettyPrinter`，不再重置方法栈、行宽、时间格式等输出配置；`Level` 类型改为从 `w_tools_core` 直接导出，调用方无需再单独依赖 `logger` 包
- 测试补充：`onError` 单次上报、并发数校验、真实日期、邮箱整串匹配、token 与存储同步、`Level` 导出
- **Breaking**: 移除 `WSecret` 聚合层（`WHash` / `WEncrypt` 已覆盖其全部能力），请直接使用这两个类
- **Breaking**: `WFuture` 更名为 `WAsync`，`WFutureConfig` 更名为 `WAsyncConfig`；同时移除空实现的 `WAsync.cleanup()`
- **Breaking**: 移除 `WRegExpStringExtension`（与 `WRegExp` 静态方法 1:1 重复），统一使用 `WRegExp` 的静态方法或 `WValidator`
- `WAsyncConfig` 新增 `any()`，与 `WAsync.any` 对齐
- **Breaking**: 移除 `WCancelToken.onceCancel`：其实现与 `addListener` 完全相同；`cancel()` 触发后会清空全部回调，所有回调本就只执行一次
- **Breaking**: `WUx.debounce` / `WUx.throttle` 返回 `WCancellableAction`（仍可直接调用），支持 `cancel()` 取消尚未触发的回调；`smoothScrollToTop` / `smoothScrollToBottom` 在 controller 未挂载时直接返回
- **Breaking**: `WCountdown` 命名与行为调整：`isRun` → `isRunning`、`countdown` → `totalSeconds`（只读 getter，由 `start` 决定）、`remaining()` → `formatRemaining()`（`remainingSeconds` 不变）；`start(second <= 0)` 立即完成并回调 `callback(0)` / `onComplete(0)`；`pause()` 取消内部定时器、`resume()` 重新开始计时，暂停期间不再每秒空转
- `WRegExp.extractBirthdayFromIdCard` / `formatDate` 增加真实日期校验；银行卡 Luhn 校验请使用 `WValidator.isValidBankCard`
- `WMapExtension.sortedByKeys` 对非 `Comparable` 键回退到字符串排序，避免运行期类型转换失败；`merge` 注明原地修改、不可变 Map 会抛 `UnsupportedError`
- `WPlatformType` 新增 `fuchsia`，`TargetPlatform.fuchsia` 不再落到 `unknown`
- 纯静态工具类（`WHash` / `WEncrypt` / `WValidator` / `WPlatform` / `WStorage` / `WLogger` / `WRegExp` / `WRegExpPattern` / `WRegExpPreset`）禁止实例化
- `WStorage.getObject` 注明仅支持 `jsonDecode` 可直接得到的类型
- 测试补充：`WAsyncConfig.any`、`debounce/throttle` 取消、`start(0)` 立即完成、非法日期提取/格式化、`fuchsia` 枚举
- **Breaking**: `WRegExp` 收敛为「正则模式 + 匹配 / 提取 / 格式化」：移除全部 `validateXxx`（校验统一使用 `WValidator`），`getXxxMatch` 更名为 `firstXxxMatch`
- `WValidator` 新增 `isValidChineseName` / `isValidPositiveInteger` / `isValidDecimal` / `isValidPositiveDecimal` / `isValidPostalCode` / `isValidMacAddress`；原 `validateNumber` / `validateInteger` / `validatePositiveNumber` 分别由 `isNumeric` / `isInteger` / `isPositive` 承接，`validatePassword` / `validateBankCard` 由 `isValidPassword` / `isValidBankCard`（规则更严格）承接
- **Breaking**: 其他命名统一：`WUX` → `WUx`、`WRegExpStr` → `WRegExpPattern`、`WRegExpCategory` → `WRegExpPreset`（`other` → `misc`）、`WHash.bytesMD5` → `bytesMd5`、`WEncrypt.generateIV` → `generateIv`、`WValidator.isValidIp` → `isValidIpv4`、`WRegExp.ipV4` → `ipv4`、`WAsync.one` / `oneWithRetry` / `oneWithTimeout` / `series` → `run` / `runWithRetry` / `runWithTimeout` / `sequence`、`WStorage.getKeys` → `allKeys`、`WCountdownRemainingType.s` / `ms` → `seconds` / `minutesSeconds`
- **Breaking**: 回调与工具命名统一：`WAsyncConfig.loadingCallback` / `loadingCompleteCallback` / `errorHandler` → `onLoadingStart` / `onLoadingEnd` / `fallbackOnError`；`WCancelToken.addCancelCallback` / `removeCancelCallback` / `dispose` → `addListener` / `removeListener` / `clearListeners`；`WValidator.isNotEmpty` → `isNotBlank`，`preventSqlInjection` / `preventXss` → `escapeSql` / `stripHtml`；`WLogger.measurePerformance` → `measureSync`；`WPlatform.executePlatformAction` → `runForPlatform`；移除不可达的 `WPlatformType.unknown`
- `WCancelToken` 的取消原因与回调参数类型由 `dynamic` 收紧为 `Object?`（源码兼容）；`WAsync` 各执行方法的 `func` 参数名统一为 `task`（位置参数，调用方式不变）
- **Breaking**: 内部文件 `src/utils/async.dart` 更名为 `async_task.dart`，避免与 `dart:async` 同名带来的阅读混淆；`WAsync` 等公开 API 仍由 `w_tools_core.dart` 导出，仅影响直接 import `src/utils/async.dart` 的代码

### w_tools_api
- **Breaking**: 移除 `WCookieInterceptor`（原实现仅覆盖简单同域场景：无法处理 cookie 删除、`value` 含 `=` 会丢失、忽略 `Path`/`Domain`/`Expires` 等属性）。需要 Cookie 管理请使用社区包 `dio_cookie_manager`
- **Breaking**: 移除 `HttpConfig`，配置直接收敛到 Dio 的 `BaseOptions`（`WApiConfig.httpConfig` → `WApiConfig.baseOptions`；`DioRegistry.forBaseUrl(config:)` → `options:`）。`DioRegistry` 会复制传入的 `BaseOptions` 并注入 `baseUrl`，避免实例间共享可变配置；原 `securityHeaders` 一并移除（安全响应头应由服务端下发，客户端无法施加，且 Web 端会触发 CORS 预检）
- **Breaking**: `WTokenInterceptor` 三个回调改名以体现真实语义：`onRequestOptions` → `configureRequest`、`onResponseOptions` → `configureResponse`、`onErrorOptions` → `observeError`（前两者可修改请求/响应，后者仅观测）
- **Breaking**: 移除未使用的公开 typedef `LibLogPrint`（仅被私有方法使用，参数类型改为内联 `void Function(String)`）
- **Breaking**: `DioRegistry.forBaseUrl` 将 `interceptors` 与 `applyInterceptors` 合并为单个 `interceptors`（原两参数最终被拼接为同一列表，无功能差异；挂载顺序由调用方决定）
- **Breaking**: `DioUtil` 重命名为 `DioRegistry`（文件 `clients/dio_util.dart` → `clients/dio_registry.dart`），更贴合其「按 `baseUrl` 登记/检索 Dio 实例」的职责
- **Breaking**: `WTokenInterceptor.onAuthError` 重命名为 `tokenRefresher`，与 `tokenGetter` / `tokenClearer` 构成齐整命名家族
- **Breaking**: `WApiConfig` 的日志回调 `logDHandler` / `logEHandler` 展开为 `logDebugHandler` / `logErrorHandler`（去掉晦涩缩写）
- `WTokenInterceptor.observeError` 不再与 401 刷新互斥：错误观测回调与 token 刷新可同时生效（此前传入该回调会静默禁用自动刷新）
- `WTokenInterceptor` 并发 401 共享同一次刷新（single-flight），避免重复调用 `tokenRefresher`
- `WTokenInterceptor` 捕获 `tokenRefresher` 抛出的异常，请求以原错误结束，不再逃逸出拦截器链
- 修复 `WLogInterceptor` 打印响应体可能导致请求失败的问题：此前用 `response.toString()` + 手动 `jsonDecode`，遇到 JSON 数组（如 `["a","b"]` → `[a, b]`）会抛 `FormatException` 使成功请求变为失败；现改为直接安全格式化 `response.data`
- 修复 `WTokenInterceptor` 401 重试对 `FormData` 请求失效的问题：重放前自动 `clone()`，避免 dio `FormData.finalize()` 二次调用抛 `StateError`；`Stream` 请求体无法重放时放弃重试并记录日志

### w_tools_ui
- 修复 `WImage` 的 Base64 分支错误不可达：`!snapshot.hasData` 判断先于 `snapshot.hasError`，导致解码失败时始终返回占位图，`errorWidget` 与失败状态回调永不触发
- 修复 `WImageConfig.fitCenter()` 误设为 `BoxFit.none`（与 `fitNone()` 重复）的问题，改为 `BoxFit.contain`
- 修复 `WRowButtonsController` 构造参数 `animationDuration` 在构造函数末尾被无条件覆盖、导致外部传值失效的问题
- 修复 `WRowButtons` 的 `overScroll` 先放宽边界又被二次 `clamp` 收回、始终无效的问题
- 修复 `WButtonConfig` 静态缓存返回共享可变实例、调用方链式修改会污染后续使用者的共享状态问题：`getCachedConfig` 现返回副本；新增 `WButtonConfig.copy()`
- 修复 `WTabBar` 硬编码 `NeverScrollableScrollPhysics` 与 `isScrollable` 配置矛盾、导致 `isScrollable: true` 仍无法横向滚动的问题
- 修复 `GlobalKey.rect()` 返回局部坐标（`paintBounds`）的问题，改为返回全局坐标系下的边界矩形，与 `offset()` 语义一致
- 修正 `HexColor.fromHex` 文档：原称支持 `#RRGGBBAA`，实际按 `AARRGGBB`（alpha 在前）解析，与 `Color(0xAARRGGBB)` / `toHex` 一致
- 全包文档注释统一为 Dart 内联引用风格（`[x]`），去除 Javadoc 风格的 `@param` / `@return` / `@throws` / `@description`（约 438 处），并移除 setter 上错误的「`@return` 配置实例，用于链式调用」
- 修正失实/过时注释：`WImage` 条件导入说明、`WImageConfigFileIO` → `WImageConfigIO`、`WKeepAliveWrapper` 生命周期回调语义、`WImageCacheManager` 内存警告监听说明、`WAppBar` 标题优先级、`WListView` 背景色默认值与特性描述、`WStep.build` 误称的「缓存计算结果」
- **Breaking**: 移除顶层便捷常量 `h` / `w` / `s`（它们经 barrel 全局导出，极易与使用者代码中的同名变量冲突）。请改用 `WSizeBox.height` / `WSizeBox.width` / `WSizeBox.size`
- **Breaking**: 4 个「依赖 ui 组件」的扩展统一改为 `WUi*Extension` 命名：`WFormStringExtension` → `WUiStringExtension`、`WFormWidgetExtension` → `WUiWidgetExtension`、`WFormStrutStyleExtension` → `WUiStrutStyleExtension`、`WFormTextStyleExtension` → `WUiTextStyleExtension`（原 `WForm` 前缀易被误解为 `w_tools_form` 子包）
- **Breaking**: `WNotificationListener` → `WNotificationListenerBuilder`（该类并非 Widget，需 `.build()` 才产出 `NotificationListener`）；其便捷扩展 `WNotificationListenerExtension` → `WNotificationListenerBuilderExtension`，getter `notificationListener` → `notificationListenerBuilder`
- **Breaking**: 私有化内部 State 类型：`WListViewState` → `_WListViewState`、`WNetworkImageWithRetryState` → `_WNetworkImageWithRetryState`（后者的 `currentRetryCount` 一并私有化），与包内其它 State 的可见性约定保持一致
- 内部结构调整（不影响 barrel 使用者）：`extensions/` 只保留扩展方法，纯工具类 `WPadding`、`WSizeBox` 与 `WRow` / `WColumn` 便捷工厂移至 `utils/`；`extensions/image_extension.dart` 重命名为 `extensions/image.dart`
- **Breaking**: `WTextConfig` / `WRichTextConfig` 的 `weight(int?)` 重命名为 `fontWeightByNumber(int?)`，消除与 `fontWeight(FontWeight?)` 的撞名（原 `weight` 的形参名恰好也叫 `fontWeight`，极易误用）
- **Breaking**: 移除 `WTextConfig` / `WRichTextConfig` 的 `family` 别名 setter（与 `fontFamily` 完全重复）
- **Breaking**: `WButtonConfig.buildTextButton()` 重命名为 `buildText()`
- **Breaking**: 移除 `WImageConfig.buildImage()`（与 `build()` 参数、返回和实现完全等价）
- **Breaking**: `WScaffoldConfig.build()` 返回类型由 `Widget` 收敛为 `WScaffold`（与其它 Config 的 `build()` 约定一致）
- **Breaking**: `WImageGlobalConfig.setGlobalConfig()` 重命名为 `configure()`（原名称中 "Global" 重复出现两次）
- **Breaking**: 移除 `WNavController.setIndex()`（与 `currentIndex` setter 完全重复）
- **Breaking**: `WKeepAliveWrapper.onKeepAlive` 重命名为 `onDeactivated`（实际在组件被移出 widget 树时触发，原名与触发时机不符）
- **Breaking**: 移除 `WNavBar.vsync` 参数（该字段从未被使用；`TickerProvider` 由调用方创建 `WNavController` 时提供），并去掉 `_WNavBarState` 上无用的 `TickerProviderStateMixin`
- 修复 `WKeepAliveWrapper` 运行期把 `keepAlive` 由 `true` 改为 `false` 时不生效的问题：`didUpdateWidget` 中改为调用 `updateKeepAlive()` 通知 `AutomaticKeepAliveClientMixin` 重新计算保活状态（此前该覆写为空实现）
- 修复 `WNavBar` 在卸载时释放外部传入的 `WNavController` 的问题：组件现在只移除监听，controller 生命周期归还调用方；同时支持运行期替换 controller，并在异步 `onItemTap` 返回后判断 `mounted`
- 修复 `WListView` 把外层 `widget.key` 传给内部滚动组件的问题：调用方传入 `GlobalKey` 时不再产生重复 key 崩溃
- 修复 `WImage` 在 `build` 中反复创建 Future（本地资源读取 / Base64 解码 / 文件存在检查）导致的重复 IO、重复解码与状态回调：`WImage` 改为 StatefulWidget 缓存 Future，加载状态按变化去重；文件图片分支改为内部状态组件
- 修复 `WNetworkImageWithRetry` 在 errorWidget 多次构建时重复调度重试、以及 `imageUrl` / 重试参数变化后本地重试计数与状态不复位的问题
- 修复 `WImageCacheManager` 清理逻辑：此前单一维度（数量或内存）超限时会清空整个缓存；现按最近访问时间精确清理至上限，超过单张内存上限的图片不再入缓存
- `WListView`：带头部 / 尾部时 padding 与 itemExtent 生效；重叠偏移导致 `itemExtent` 非正时钳制为 1px；精确缓存路径补充 `AutomaticKeepAlive` 祖先，保活不再失效；支持运行期替换 controller
- `WRowButtons`：居中滚动改用视口相对坐标（`RenderAbstractViewport`），列表不在屏幕原点时不再偏移；支持运行期替换 controller 与动态挂载 `onScroll`
- `WRichText` 未显式配置 `textScaler` 时跟随系统字体缩放（此前固定 `noScaling`）
- `WNavController.animateTo` 现在会应用传入的 `curve`（此前始终使用构造时的 `easeInOut`）
- `WText` 未配置字体相关样式时不再设置强制 strut，避免继承到的大字号被默认 strut 裁切
- `WNotificationListenerBuilder`：`onNotification` 与 `onNotificationPercentage` 现在可同时生效；不可滚动（`maxScrollExtent == 0`）时百分比回调为 0，不再产生 `NaN`
- `WGradientCircularProgressIndicator` 新增 `radius` / `strokeWidth` 断言，并钳制 `asin` 入参，避免非法参数产生 `NaN` 变换
- Web 平台的文件图片分支现在会使用自定义 `errorWidget`（此前始终返回默认错误占位）
- `WImageGlobalConfig` 正式接入：默认占位符 / 错误占位符会被 `WImage` 读取，`maxCacheSize` / `maxCacheMemory` 会同步到 `WImageCacheManager`
- `WImageConfig` 的 `placeholder` / `errorWidget` / `borderRadius` / `border` / `boxShadow` / `margin` / `padding` setter 支持传 `null` 清除；`border` 类型放宽为 `BoxBorder?`
- `WAppBar` 默认返回图标改为 `Icons.arrow_back`（此前未配置时为不可见的空按钮），并补充返回按钮语义；移除空的 `initState`
- `WButton` 补充 `button` / `enabled` 语义、鼠标光标，并支持 Enter / Space 键盘激活
- `WRowButtons` 的选项补充 `button` / `selected` / `enabled` 语义
- `WTabBarConfig` 新增 `copy()` / `copyWith()`
- 修复 `num.toThousand` / `num.toCurrency` 对科学计数法（如 `1e+21`、`1.5e-7`）无法正确分组的问题：先展开为普通十进制再添加分隔符；`NaN` / `Infinity` 原样返回

### w_tools_form
- 修复 `WFormDatePicker`（原 `FormBuilderDatePicker`）选中日期后公开的 `onChanged` 永不触发的问题：改用 `didChange`（`setValue` 不会回调 `widget.onChanged`）
- 修复 `WFormDatePicker` 在 `enabled: false` 时仍可弹出选择器的问题
- 修复 `WFormDatePicker` 初始值超出 `[firstDate, lastDate]` 区间时触发框架 assert 崩溃的问题（现先 clamp 再传入）
- 修复 `WFormDatePicker` 对无法解析的存量值抛 `FormatException` 的问题（改为安全解析，失败按无初始值处理），并统一显示与解析所用 locale（去掉硬编码 `en_US`）
- 修复 `WFormMultiDropdown` 在非 `String` 泛型下的运行时崩溃：移除形同虚设的泛型参数，值类型统一为 `String`
- 修复 `WFormMultiDropdown` 禁用项把「已选中」覆盖为禁用样式、且已选中的禁用项仍可点击的问题（显示上选中优先，点击上禁用优先）
- 修复 `WFormData.onChange` 仅对 `String` 记录输入状态、导致 `isAllEntered` 对数字/日期/集合等字段恒为 `false` 的问题
- `WFormValidator.validate()` 支持配置校验范围与提示策略：新增 `WFormValidatorConfig.continueOnError`（默认 `false` 即短路校验，遇首个失败项返回；置 `true` 改为全量校验，遍历全部校验项并为所有失败项设置边框错误）、`notifyAllErrors`（默认 `false` 时 `customErrorCallback` 只对首个失败项触发，置 `true` 则每个失败项都触发）；`autofocus` 仅作用于第一个失败项
- 新增 `WFormValidator.errors`：只读的 `{字段名: 错误文本}` 集合，每次校验后刷新，便于汇总展示全部错误（短路模式只含短路前的失败项）
- 修复短路校验提前返回、或中途关闭 `showBorderError` 时后续字段残留上一次边框错误的问题：现在校验开始时会清除本次参与校验字段的旧边框错误
- 修复校验通过时对已无错误字段重复 `setState` 造成的无意义重建：`WFormBorderState.setError` 在状态无变化时直接返回，并将原先两次 `setState` 合并为一次
- 修复 `WFormBorder` 在 `isTransparentBackground: true` 时连错误装饰一起关掉的问题：装饰判断改为「错误态优先于透明背景」，校验失败的红框不再因背景透明而丢失
- 修复 `WFormBorderWithData` 在 `enableFocusBorder` 由 `true` 改为 `false` 后边框卡在聚焦装饰的问题：关闭后不再向 `WFormBorder` 传递聚焦态，并在 `didUpdateWidget` 中复位
- 修复 `WFormBorder` 的 `hintTextList` 在运行期变更后不生效的问题：非错误态下父级传入新的提示文本时，会在 `didUpdateWidget` 中同步更新展示
- 修复直接使用 `WFormBorder`（未包在 `WFormBorderWithData` 中）时不继承 `WFormBuilder.formBorderConfig` 的问题：配置解析下沉到 `WFormBorder` 自身，显式 `config` 优先，否则读取祖先 builder 的配置；继承配置的变更通过 `didChangeDependencies` 响应
- 新增 `WFormReadOnlyScope`：`WFormBorderWithData` 通过 InheritedWidget 下发只读状态，`withFormBorder(readOnly: true)` 现在可穿透 `Padding` / `Center` / 自定义组件等任意包装，并覆盖 `WFormMultiDropdown` / `WFormCheckbox` / `WFormRadioGroup` / `WFormButton`（此前只影响 `WFormTextField` / `WFormDropdown`）
- 修复 `withFormBorder` 通过重建 widget 树传递只读导致的属性丢失：`Container` 的 `width` / `height` / `transform` / `transformAlignment` / `clipBehavior` 不再被丢弃；同时删除整个 `_processWidgetTree`（约 145 行），Row 子树不再被重建
- `WFormBorder` 改为按**内容快照**判断配置是否变化：配置被原地修改（替换某个装饰或构建器）后，只要组件随后发生重建即可生效（此前仅比较实例身份，原地修改永远不会生效）
- 补充配置变更语义文档：`WFormBorderConfig` 按引用被捕获，立即生效需替换实例（`copyWith`）；`copyWith` 的 null 表示「保持不变」，清空字段请使用 setter（`cfg.copy()..errorDecoration = null`）
- **Breaking**: 移除未使用的 `WFormBorder.tag` 与 `WFormBorderConfig.configForTagCallback`：该标签配置机制从未通过 `withFormBorder` / `WFormBorderWithData` 暴露，全仓库无调用方
- `WFormBorderDecoration.border` 类型由 `Border?` 放宽为 `BoxBorder?`，支持 `BorderDirectional`（RTL 场景）
- `WFormBorderState` 的装饰缓存合并为单一缓存键记录：修正「透明态装饰为 null」时缓存永不命中、每次 build 都重算的问题
- 边框组件的参数校验异常类型调整：`withFormBorder` 的 name 为空改为 `ArgumentError`，未找到 `WFormBuilder` 改为 `StateError`
- 补充 `withFormBorder` / `WFormBorderWithData.name` 的语义文档：注册键需全局唯一；单字段场景应与内部字段名一致，复合容器场景作为分组名
- **Breaking**: `formBorderConfig` 从 `WFormData` 迁移到 `WFormBuilder`：`WFormData({formBorderConfig})` → `WFormBuilder(formData: ..., formBorderConfig: ...)`，边框配置与 `autovalidateMode` 等同属 UI 层配置，归位到 builder。迁移后 `_WFormDataInherited.updateShouldNotify` 会比较边框配置，配合 `WFormBorderState.didUpdateWidget` 重新解析，运行期修改 `formBorderConfig` 可实时生效（此前挂在 `WFormData` 上因实例身份比较，修改永远不会传播）
- **Breaking**: 移除边框内置默认主题（不再提供默认装饰与默认文案构建器）：`WFormBorderConfig` 的所有装饰与文案构建器默认均为 null，未配置的状态不渲染任何装饰、未配置的文案构建器不渲染提示/错误文本。此前「不传配置也能得到白底 / 灰边 / 红框」的隐式默认不再存在，请通过 `WFormBuilder.formBorderConfig` 或 `WFormBorder(config: ...)` 显式配置
- `WFormBorderConfig` 构造器不再内置默认值（字段默认 null）；`hintBuilder` / `errorBuilder` setter 参数放宽为可空，对应字段去掉 `late`，消除空配置下的 `LateInitializationError` 隐患
- 新增 text_field 的 action 插件化管道：`WFormTextFieldScope` + 只读接口 `WFormTextFieldData`（暴露 `value` / `hasText` / `readOnly` / `isPasswordVisible` / `valueListenable` / `clear()` / `togglePasswordVisibility()`），用户自定义 action 与预置 action 走完全相同的公开接口
- 新增预置 action：`WFormTextFieldPasswordToggle`（密码可见性切换）、`WFormTextFieldClearButton`（清空按钮，支持 `onCleared` 回调与 `icon` 覆盖；点击热区与图标渲染尺寸一致，不额外包裹尺寸约束）
- 新增 `WFormBorderLayout` 布局策略：边框与消息的组装方式可替换。内置 `WFormBorderLayout.column`（边框在上、消息在下，可配置间距与对齐），并支持 `WFormBorderLayout.builder(...)` 函数式实现或继承基类自定义；布局输入通过 `WFormBorderLayoutData` 暴露子组件、消息、错误/只读态与圆角
- `WFormBorder` 默认布局新增 4px 消息间距并显式左对齐（此前消息紧贴边框）；内部 `Container` 改为 `DecoratedBox`，减少无谓的中间层
- `WFormBorderConfig` 新增 `layout` 字段（setter / `copyWith` 同步），运行期替换布局同样通过内容快照生效
- `WFormTextFieldData` 新增 `obscureText` getter，供自定义 action 判断当前是否为密码模式
- 新增 `WFormDefaults.clearButtonIcon`：清空按钮的全局默认图标
- **Breaking**: 密码可见性图标不再占用 `InputDecoration.suffixIcon`：改由 `actions` 中的 `WFormTextFieldPasswordToggle` 提供；移除 `WFormTextFieldConfig.obscureTextIcon` / `obscureTextVisibleIcon` setter，图标统一由 `WFormDefaults.obscureTextIcon` / `obscureTextVisibleIcon` 配置
- 移除 `actions` 遍历中多余的一层 `Container(height, alignment)`（`Row` 默认垂直居中、外层容器已设高度）：涉及 `WFormTextField` / `WFormButton` / `WFormDropdown` / `WFormMultiDropdown`
- 修复 `WDividerInputFormatter` 在 `first >= rear` 时多插分隔符（`first == rear` 会产生前导分隔符）的问题
- **Breaking**: `FormBuilderDatePicker` 重命名为 `WFormDatePicker`
- **Breaking**: `WFormMultiDropdown<T>` 改为非泛型 `WFormMultiDropdown`（`items` 为 `Map<String, String>`、`initialValue` 为 `Set<String>?`、`onChanged` 为 `ValueChanged<Set<String>>`）
- **Breaking**: `CustomPopupRoute` 重命名为 `WFormPopupRoute`；顶层函数 `showPopup(...)` 改为 `WFormPopup.show(...)`
- **Breaking**: `WFormDefaults.obscureTextIconOn` 重命名为 `obscureTextVisibleIcon`（含 `WFormTextFieldConfig` 与根包 `WConfig` 中的同名成员）
- **Breaking**: `WFormCheckboxConfig.disableIcon` 重命名为 `disabledIcon`（语法化，与 `selectedIcon` / `unselectedIcon` 命名体系对齐）
- **Breaking**: `WFormCheckboxConfig.spacing` / `WFormRadioGroupConfig.spacing` 重命名为 `iconSpacing`（明确为"图标与文本之间的间距"，与 `iconYOffset` 构成 `icon*` 命名族）
- 修复 `WFormCustomValidator.custom(...)` 无法对空值做校验的问题：`BaseValidator` 在 `checkNullOrEmpty: false` 时会对空值直接放行，自定义函数收不到 `null`、因而无法实现「必填」等规则；现覆写 `validate`，把原始值（含 `null`）完整交给自定义函数处理
- **Breaking**: `WCustomValidator` 重命名为 `WFormCustomValidator`，与包内「公开 API 统一 `WForm` 前缀」的约定对齐
- **Breaking**: 校验器三个类去掉冗余复数：`WFormValidators` → `WFormValidator`、`WFormValidatorsItem` → `WFormValidatorItem`、`WFormValidatorsConfig` → `WFormValidatorConfig`
- **Breaking**: `WFormValidatorItem.autoFocus` 重命名为 `autofocus`，对齐 Flutter SDK 的 `autofocus` 命名
- **Breaking**: `WFormValidatorConfig.customErrorHandler` 重命名为 `customErrorCallback`，与 `itemValidationCallback` 的后缀统一
- 内部文件重命名（不影响 barrel 使用者）：`validators.dart` → `validator.dart`（承载 `WFormValidator` 家族），自定义校验器扩展移至 `custom_validator.dart`
- 修复 `Row.withFormBorder()`（`WFormRowBorderExtension`）的重建缺陷：`Stack` 的 `clipBehavior` 不再被硬编码为 `Clip.hardEdge`、内部子组件的 `key` 不再丢失、`readOnly: false` 时不再把内部 `WFormDropdown` 的 `enabled: false` 强制改回 `true`、`Container` 不再用 `constraints` 的最大值覆写宽高、`WFormDropdown<String>` 的类型实参不再被擦除为 `dynamic`
- **Breaking**: `RowBorderedExtension` 重命名为 `WFormRowBorderExtension`，与包内「公开扩展统一 `WForm` 前缀」的约定对齐
- **Breaking**: 删除 `WFormData.isShowErrorStyle` / `formShowErrorStyle`（只写不读的半成品机制），以及 `WFormMultiDropdownConfig.contentPadding` / `popUpLayerTitleStyle` / `popUpLayerTitlePadding`（配置齐全但从未渲染）
- **Breaking**: 删除 `WFormMultiDropdownConfig.buildBordered()` 中从未被使用的 `hintText` 参数（提示文案请使用 `hintTextList`）
- `WFormButtonConfig` / `WFormCheckboxConfig` / `WFormRadioGroupConfig` / `WFormValidatorConfig` 补齐 `copy()` / `copyWith()`
- `WFormTextFieldConfig.buildBordered` / `WFormDropdownConfig.buildBordered` 不再改写共享 Config（改为在副本上操作），避免污染后续 `build()`
- `WFormTextField` 补充 `didUpdateWidget`：父级更换 `focusNode` 时同步更新并正确释放自建节点（避免泄漏）
- 全包文档注释统一为 Dart 内联风格（去除 Javadoc 风格的 `@param` / `@return`），并修正失实/复制粘贴注释（`WFormDatePicker` 类文档原整段复制自 `DropdownButton`）
- 梳理 `w_tools_form` 注释：删除与字段文档重复的构造器参数清单、复述代码的行内注释，setter 统一为「设置 xxx」表述，并修正 `WFormDropdown.hint` / `hintText` 等失实说明
- 新增 `WFormBuilder.requireOf(BuildContext)`：缺少 `WFormBuilder` 祖先时抛 `StateError`；`WFormDropdown` / `WFormMultiDropdown` / `WFormTextField` / `WFormBorderWithData` 统一复用，并移除无效的 `visitAncestorElements` 兜底与 `dynamic` 类型（未找到 builder 的异常类型由 `Exception` 统一为 `StateError`）
- `WFormMultiDropdown` 的默认图标改为读取 `WFormDefaults`：复选框使用 `checkboxUnselectedIcon` / `checkboxSelectedIcon`（与 `WFormCheckbox` 一致），下拉箭头使用 `dropdownIcon`（仍保留 `iconSize` / 图标颜色配置）
- 修复 `WFormRadioGroup` 点击选项时重复调用 `setValue` 与 `didChange` 的问题（只调用 `didChange`），并让 `StrutStyle` 补上 `fontWeight`，避免文本度量不一致
- `WFormRadioGroup` 选项改为明确的单列 `Column` 布局（原 `Wrap` + `Expanded` 实际只会排成单列），并为每个选项补充 `Semantics`：`checked` / `inMutuallyExclusiveGroup` / `enabled`，读屏可识别单选状态
- `WFormDropdownConfig.buildBordered` / `WFormMultiDropdownConfig.buildBordered` 新增 `readOnly` 参数：为 true 时内层控件不可交互、外层使用只读装饰（原 `enabled: false` 行为保持不变）
- 修复 `WFormTextField` 在外层只读作用域（如 `withFormBorder(readOnly: true)`）下 `WFormTextFieldData.readOnly` 仍为 false 的问题：清空按钮不再显示、`clear()` 在只读时不执行；`WFormTextFieldScope.updateShouldNotify` 现在同时比较只读状态，作用域切换后 action 会正确刷新
- `WFormTextFieldPasswordToggle` 仅在密码模式（`obscureText: true`）下显示，避免普通文本框出现无效的眼睛图标
- 修复 `WFormDatePicker` 点击「取消」时清空已有日期值的问题（取消与主动清空现在区分开）
- 修复 `WFormCheckbox` 在字段值为 null 时点击无响应的问题（现在按 `false` 处理并正常切换）
- `WFormCheckbox` / `WFormRadioGroup` / `WFormDatePicker` 变更时同步调用 `WFormData.onChange`：`formEntered` 输入状态与边框错误清理现在覆盖所有字段类型（此前仅 text / dropdown / multi / button 接入）
- `WFormCheckbox` / `WFormRadioGroup` / `WFormMultiDropdown` 新增 widget 级 `enabled` 参数（null 时读取配置），与 `WFormDropdown` 对齐；三者的 `Config.build()` 也支持传入 `enabled`。`WFormMultiDropdownConfig.buildBordered` 同步新增 `enabled` 覆盖参数
- **Breaking**: `WFormDatePicker` 新增 `WFormDatePickerConfig`：原构造器上的 `decoration` / `icon` / `iconSize` / `iconDisabledColor` / `iconEnabledColor` / `style` 迁移到配置类；字段值由 locale 相关的 `DateFormat.yMEd()` 文本改为 ISO `yyyy-MM-dd`，显示格式通过 `displayFormat`（默认 `yMMMMd`）与当前 locale 决定；新增容器能力与 `buildBordered`
- `WFormCheckboxConfig` / `WFormRadioGroupConfig` 新增容器能力：`height` / `width` / `leading` / `actions` / `containerDecoration` / `containerMargin` / `containerPadding`，并新增 `buildBordered`；**Breaking**: `WFormRadioGroupConfig.padding` 重命名为 `containerPadding`
- `WFormButtonConfig` 新增 `buildBordered`
- 可访问性补充：`WFormCheckbox` 增加 `checked` / `enabled` 语义；`WFormMultiDropdown` / `WFormDatePicker` 增加按钮与启用状态语义；日期图标颜色文档明确为“仅作用于默认图标”
- `WFormTextField` 的 `WFormData` 改为在 `didChangeDependencies` 中跟随 `WFormBuilder` 更新，避免替换 `formData` 实例后仍写入旧对象；清空改为写入 `null`（与初始值语义一致）；`StrutStyle` 补 `fontWeight` / `forceStrutHeight`
- `WFormButton` 的 `didChange` 回调不再先 `setValue` 再 `didChange`，避免重复通知表单
- `WFormMultiDropdown` / `WFormDatePicker` 的 `InputDecorator` 补 `isEmpty`，传入带 `labelText` 的 `InputDecoration` 时浮动标签行为正确；补充值/选项匹配关系的文档（dropdown 值必须存在于 `items`，multi 的未知值忽略显示但保留在值中）
- 修复 `WFormPopup` 在极小视口或锚点越界时可能产生负数约束、触发 `BoxConstraints` 断言的问题：上下可用空间与宽度统一钳制为不小于 0
- `WFormPopup` 的展开动画改用 `SizeTransition`，不再二次约束子组件高度，避免非滚动内容在 `heightFactor` 较小时溢出；同时删除内部的 `_RenderHeightFactorBox` / `_HeightFactorBox`（约 80 行）
- 移除 `WFormPopup` 定位对 `kToolbarHeight` 的硬编码假设：上方可用空间只扣除安全区，适配无 AppBar / 自定义 AppBar 的页面
- `WFormPopup.show` 改为返回 `Future<T?>`，新增 `WFormPopup.hide(context, [result])` 支持关闭时回传结果；新增 `anchorContext`（精确指定锚点）与 `rootNavigator` 参数
- `WFormPopup` 键盘适配：底部可用空间合并 `MediaQuery.viewInsets.bottom`，键盘弹起时弹层会自动选择更合适的显示方向
- `WFormPopup` 增加重复打开保护：同一 `Navigator` 已有弹层时忽略后续 `show`；锚点尚未完成布局时抛 `StateError`，替代此前的空断言
- `WFormPopup.show` / `WFormPopupRoute` 新增 `width`（默认与锚点同宽）、`backgroundColor`、`borderRadius`、`settings`，弹层外观与路由观测能力可配置；文档补充「位置仅在打开时计算，锚点滚动后不自动跟随」
- 修复 `WFormMultiDropdown` 弹层选项在外部值回填 / 重置后选中态不更新的问题：`_WFormMultiDropdownItemState.didUpdateWidget` 中按 `status` 重新同步本地选中态
- **Breaking**: `WFormMultiDropdown` 的字段值由逗号分隔的 `String` 改为 `Set<String>`：`initialValue` / `onChanged` / `build` / `buildBordered` 同步调整；`disabledKeys` 由逗号字符串改为 `Set<String>`。此前键或禁用项包含逗号时会解析错乱，现已消除该限制
- `WFormMultiDropdownConfig` 新增 `hintText`，`WFormMultiDropdown` 新增 `hintText` / `width` 参数：未选择时的占位文本可配置（默认仍为 `ALL`），`width` 参数优先于 `config.width`
- **Breaking**: `WFormMultiDropdownConfig` 的复选框图标配置改名，与下拉箭头 `icon` 区分：`unselectedIcon` / `selectedIcon` / `disabledIcon` → `checkboxUnselectedIcon` / `checkboxSelectedIcon` / `checkboxDisabledIcon`
- **Breaking**: `WFormRadioGroup` 的构建器参数改名：`itemBuilder` → `titleBuilder`、`itemChildBuilder` → `itemExtraBuilder`，明确「标题」与「选项下方附加内容」的职责
- `WFormDropdownConfig` 新增 `enabled`；`WFormDropdown.enabled`、`WFormDropdownConfig.build` / `buildBordered` 的 `enabled` 参数改为可空，null 时读取配置值（与 `WFormMultiDropdown` / `WFormRadioGroup` 的配置形态对齐）
- **Breaking**: `WFormConfig` 重命名为 `WFormDefaults`（文件 `form_config.dart` → `form_defaults.dart`），明确其职责是「可替换的全局默认值」，避免与各组件自身的 `WForm*Config` 混淆
- **Breaking**: `WTextInputFormatter` 重命名为 `WInputFormatters`（文件 `input_formatter.dart` → `input_formatters.dart`），与类中收纳多个格式化器的职责一致
- 内部目录重组（不影响 barrel 使用者）：`components/inputs/` 按职责拆分为 `fields/`（输入字段）、`border/`（边框与布局策略）、`validation/`（校验器）；`data.dart` → `form_data.dart`；`utils/popup.dart` 移至 `components/popup.dart`
- `WFormButton` 点击后同步调用 `WFormData.onChange`：`formEntered` 输入状态与边框错误清理现在覆盖按钮字段
- `WFormButton` 交互重构：点击区域改用 `Material` + `InkWell`（水波纹反馈、键盘焦点、鼠标光标），禁用态内容半透明；并补充 `button` / `enabled` 语义
- `WFormButtonConfig` 的可选项 setter 参数放宽为可空（`null` 表示清空），与其它字段配置对齐；`buildBordered` 改为经公开 setter 清空内层装饰
- `WFormButtonConfig` 新增 `width`；`WFormButton` 新增 `validator` / `focusNode`，`build` / `buildBordered` 同步透传
- 修复 `WFormDatePicker` 未继承外层 `WFormReadOnlyScope` 的问题：`withFormBorder(readOnly: true)` 等场景下不再可点击弹出选择器，`Semantics.enabled` 与默认图标颜色同步为禁用态
- 修复 `WFormBorderConfig.copyWith()` / `copy()` 丢失自定义 `layout` 的问题：副本现在保留原布局，并支持通过 `copyWith(layout: ...)` 覆盖
- **Breaking**: `WInputFormatters.phone()` 返回类型由 `List` 改为 `List<TextInputFormatter>`，可直接赋给 `inputFormatters`，无需手动 `cast`
- 修复 `WFormCheckbox` / `WFormRadioGroup` / `WFormDatePicker` / `WFormButton` 在表单 `reset()` 后 `formEntered` 不同步的问题：输入状态统一在 `didChange` 中维护，交互与重置走同一条路径；同时 `WFormData.onChange` 将布尔值 `false` 视为未输入（此前 `false != null` 会被误判为已输入）
- 统一 `WFormDropdown` / `WFormMultiDropdown` / `WFormTextField` 的 `buildBordered` name 校验：空名称改抛 `ArgumentError`（此前抛通用 `Exception`）
- 配置 setter 可空性补齐：`WFormRadioGroupConfig.lineSpacing`、`WFormMultiDropdownConfig.disabledKeys` / `iconSize`、`WFormDatePickerConfig.decoration` / `iconSize` 现在均可传 `null` 清空或恢复默认
- 修复输入格式化器在删除字符时光标错误右移的问题：仅在文本长度增加（新增字符）时调整光标；`WDividerInputFormatter` 的多字符分隔符改用 `startsWith` 判断
- `WFormMultiDropdown` 弹层选项补充 `checked` / `enabled` 语义；自定义 `icon` 现在也会套用 `IconTheme`，`iconSize` / `iconEnabledColor` / `iconDisabledColor` 对自定义图标生效
- `WFormCheckbox` / `WFormRadioGroup` / `WFormDatePicker` / `WFormMultiDropdown` 的可点击区域补充鼠标光标（启用为 click、禁用为 basic）
- `WFormPopup.hide` 新增 `rootNavigator` 参数；未指定 `width` 时内容撑满锚点宽度，与文档描述一致；补充重复 `show` 的返回值说明
- `WFormData.isAllEntered` 忽略已卸载字段残留在 `formEntered` 中的陈旧记录，避免字段移除后恒为 false
- `WFormValidator.errors` 改为返回只读快照，后续校验不再修改已持有的结果
- 配置能力补齐：`WFormTextFieldConfig` 新增 `width`；`WFormButtonConfig.build` 新增 `enabled` 覆盖；`WFormDropdown` / `WFormMultiDropdown` / `WFormTextField` 新增 `validator` 透传
- `WFormDropdown` 的选项文本 `StrutStyle` 改为按 `style` 构造字体信息，避免大字号被裁切
- `WFormBorderDecoration.copyWith` / `withBorder` 的边框参数放宽为 `BoxBorder?`，支持 `BorderDirectional`
- `WFormBorderWithData` 的焦点回调补充 `mounted` 判断，避免销毁阶段触发 `setState`
- `WFormCheckbox` / `WFormRadioGroup` 新增 `validator` 透传（widget 构造器与 `Config.build` / `buildBordered`），至此全部字段组件均支持字段级校验器
- 新增 `WFormValidatorItem.field(name)`：校验项可引用字段自身声明的 `validator`。`WFormValidator.validate()` 直接执行该 validator（不写入字段 `errorText`，避免与 `InputDecoration` 双通道），并把错误统一写入 `errors`、边框错误与既有回调，短路 / 全量 / 跳过 / 自动聚焦语义与自定义校验项一致；字段未注册或未声明 validator 时视为通过
- `WFormValidatorItem.validatorBuilder` 改为可空（`WFormValidatorItem.field` 模式下为 null），现有自定义校验项用法不受影响
- 统一错误通道：`WFormValidator` 不再写入字段 `errorText`，错误文案只由 `WFormBorder` 展示，避免 `InputDecoration` 与边框双通道重复；直接调用 `formKey.currentState.validate()` 时仍保留原生字段错误展示（仅 text / dropdown 渲染文案）

### w_tools_qr
- 依赖升级：`qr_code_scanner_plus` 由 2.1.1 升至 2.1.2，修复 iOS 在 resume 期间退出扫码页导致的崩溃
- 暂不升级 2.2.0+：其要求 Flutter ≥3.44 / iOS ≥13 / AGP 9，属于平台级 Breaking 变更，待下游工程基线确认后再评估（pubspec 已限制为 `>=2.1.2 <2.2.0`）
- 修复默认配置下 `onScanned` 永不触发的问题：此前用「边框颜色是否变化」判断是否已扫码，而 `borderColor` 与 `checkedBorderColor` 默认同为红色，首次扫描会直接暂停相机且不回调。现改用独立的已扫码状态判断
- 新增 `WQrView.scanOnce`（默认 true）：为 false 时持续回调 `onScanned`，且不暂停相机
- 新增 `WQrViewState.restartScan()`：重置边框与已扫码状态并恢复相机，支持再次扫码；`WQrView` 的 State 类型由私有改为公开，可通过 `GlobalKey<WQrViewState>` 调用
- **Breaking**: `WQrView.onQRViewCreated` 的回调参数由 `QRViewController` 改为新增的 `WQrController`。`WQrController.scannedDataStream` 为广播流，可与 `onScanned` 同时监听（原插件的单订阅流在调用方自行监听时会抛 `Bad state`）
- 新增 `WQrView.cameraFacing` / `formatsAllowed` / `overlayMargin` / `onError` 参数，补齐插件常用的相机与条码格式配置
- 应用生命周期：进入后台自动暂停相机，回到前台恢复；单次扫描已完成时不会自动恢复
- 连续扫描模式新增 `scanInterval`（默认 `Duration.zero`）：按条码内容与时间窗去重，避免同一码高频回调
- `cameraFacing` / `formatsAllowed` 运行期变化会重建平台视图并重置扫描状态（此前只在创建时生效）
- 修复在 `onScanned` 内调用 `restartScan` 时 `pauseCamera` 晚于 `resumeCamera`、导致相机仍处于暂停的问题：现在先暂停再回调
- 相机操作与扫描流的异步异常不再成为未处理异常：统一通过 `onError` 上报，未提供时交给 `FlutterError.reportError`
- `WQrViewOverlayShape` 构造函数改为 `const`，默认扫描框样式可编译期复用
- **Breaking**: `WQrView.checkedBorderColor` 默认值由红色改为绿色，扫码成功后默认能看到边框反馈
- 新增 `WQrView.showOverlay`（默认 true）：为 false 时全屏扫描，不绘制扫描框
- `onQRViewCreated` 回调自身抛出的异常现在通过 `onError` 上报；Widget 销毁后的错误回调会被丢弃
- 源文件按职责拆分为 `qr_view.dart` / `qr_controller.dart` / `qr_overlay_shape.dart`，公开 API 不变
- 补充控制器生命周期说明：平台视图重建后旧控制器失效；`resumeCamera` 不重置 `scanOnce` 锁定，重新扫码需调用 `WQrViewState.restartScan`
- barrel 文件转出 `Barcode` / `BarcodeFormat` / `CameraException` / `CameraFacing` / `SystemFeatures`，调用方无需额外依赖 `qr_code_scanner_plus`
- 补充扫码流程、连续扫描、`restartScan` 时序、生命周期暂停/恢复、视图重建、`scanInterval` 去重、扫描框显示开关、回调异常隔离、广播流多监听、相机错误上报与无权限回调的测试

### w_tools_toast
- `WToastConfig.duration` 默认值由 `800ms` 调整为 `2s`，与文档描述一致
- `WToastConfig.backgroundColor` / `onClose` 现在会透传到成功 / 错误 / 警告 / 加载 / 自定义提示（此前配置无效）
- `toastBuilder` 通过新增的 `showCustom()` 生效；`showSuccess` / `showError` / `showWarning` / `showLoading` 在未设置对应 builder 时使用默认样式（文本 / 转圈 + 文本），不再抛 `ArgumentError`
- 新增 `WToastConfig.onError`：BotToast 初始化失败等异常可通过该回调观测（此前被静默吞掉）
- 明确加载提示为全局唯一（跨 `WToastConfig` 实例共享），`showLoading` 会先关闭上一个 loading
- 新增 `WToast.showText()` 与 `WToastConfig.showText()`：直接使用 BotToast 文本提示，未指定的样式参数沿用 BotToast 默认值；`WToastConfig.showText()` 会把 `backgroundColor` 作为气泡底色
- 新增 `WToast.hideAll()` 与 `WToastConfig.hideAll()`：一次性清理文本 / 加载 / 自定义全部提示（`WToastConfig.hideAll()` 同时重置全局加载状态）
- 新增 `WToastConfig.copy()` / `copyWith()`：与 `ui` / `form` 的 Config 约定保持一致，参数为 null 表示沿用原值
- `WToast.showCustomDialog()` 现在会捕获 `toastBuilder` 构建阶段抛出的异常并交给 `onError`（此前只捕获 BotToast 调用阶段的异常）
- 统一注释风格：`toast.dart` 的 Javadoc `@param` / `@return` 改为 Dart 文档注释，并补充 `onClose` 延迟 1 毫秒回调的原因说明
- 测试新增 `copy` / `copyWith`、文本提示渲染 / 对齐 / 点击关闭 / 自动关闭 / 气泡底色、`showSuccess` 渲染与对齐等用例

### 构建
- 各 pubspec 的 SDK 下界改为「逐包真实下界」：`form` / 根包为 `^3.10.0` + `flutter >=3.38.0`（由 `flutter_form_builder` / `form_builder_validators` 决定）；`ui` 为 `^3.6.0` + `flutter >=3.27.0`；其余 6 个子包为 `^3.6.0` + `flutter >=3.27.0`（受 `resolution: workspace` 的 `sdk >=^3.6.0` 要求约束，Dart 3.6 对应 Flutter 3.27）
- `WListView` 用 `cacheExtent` 替代 `ScrollCacheExtent`，`w_tools_ui` 的最低 Flutter 版本从 3.44 降至 3.27
- 根包 `dev_dependencies` 新增 `bot_toast`，供 toast 的 widget 测试使用
- 8 个子包完成 pub.dev 发布准备：各自新增 README / CHANGELOG / LICENSE，补充 `homepage` / `repository` / `issue_tracker` / `topics`，并移除 `publish_to: none`；根包仍保持私有聚合

### 文档
- README 新增「依赖与子包说明」：明确 `w_tools_app` 强依赖 GetX 且不可替换，
  仅需组件/工具的项目请按需导入子包（避免被拖入 GetX）
- README「快速开始」改用 `start()`，并补充「生命周期与插件」章节与自定义插件示例
- README「安装」区分「发布前接入（path / Git）」与「发布后从 pub.dev 安装」；8 个子包可独立发布，根包不发布
- `WAppPlugin` 文档补充 `builderWrapper` / `wrapApp` 的**插入位置图**与选择规则，并说明与 `WApp.builder` / `WApp.appWrapper` 字段的等价关系

## 1.0.8

- **Breaking**: `WRowButtonsController.initialIndex` 从 `int`（默认 0）改为 `int?`（默认 null），支持无预选状态
- **Breaking**: `WRowButtonsController.index` 返回类型从 `int` 改为 `int?`
- **Breaking**: `WRowButtonsController.selectedIndexNotifier` 类型从 `ValueNotifier<int>` 改为 `ValueNotifier<int?>`
- 新增 `WRowButtonsController.deselect()` 方法，可将选中状态重置为 null
- 补充 `WRowButtonsController` 及 `WRowButtons` 的单元测试和 Widget 测试

## 1.0.7

- 优化多个组件和工具类的代码质量
- 更新依赖版本
- 修复已知问题

## 1.0.6

- 修改了 WConfig 类，将 token 相关的键名从 const 改为私有变量 + 公共 getter 的形式
- 为 WConfig 类添加了 set 方法，用于设置 token 相关的键名，并且在已经赋值的情况下抛出异常
- 在 WConfigSetup 类中添加了对应的 setter 方法，以便通过链式调用设置这些键名
- 整理了 widget.dart 文件中的 withContainer 方法，修复了缩进并添加了文档注释
- 移除了 widget.dart 文件中不必要的导入
- 检查了 WListViewConfig 类的 copyWith 方法，确保所有属性都被正确复制

## 1.0.4

- 重构 WToastConfig 类，移除默认实现，使其更加灵活
- 将构建器中的 String 类型参数改为 Object? 类型，支持传递任意类型对象
- 移除 WToastConfig 中的静态方法，改为实例方法
- 优化加载状态管理，每个实例管理自己的加载状态
- 更新相关文档和示例

## 1.0.3

- 优化 WToastConfig 类，使其更加配置驱动
- 移除 WToastConfig 中的默认实现，让用户完全自定义 UI
- 更新相关文档和示例

## 1.0.2

- 优化了多个组件的配置类，添加了 copy 和 copyWith 方法
- 增强了 WFormMultiDropdown 组件，添加了更多自定义选项
- 优化了 WRichText 组件的性能
- 修复了多个组件中的小问题
- 更新了文档

## 1.0.1

- 修复了部分组件的文档注释
- 优化了部分组件的性能
- 更新了 README.md

## 1.0.0

- 初始版本发布
- 包含完整的组件库、工具类和扩展功能
- 支持配置驱动的开发模式
- 提供丰富的 UI 组件和实用工具