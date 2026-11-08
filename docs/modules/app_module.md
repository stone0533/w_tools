# App 模块文档

## 概述

App 模块由 `w_tools_app`（GetX-free 应用内核）+ `w_tools_app_getx`（GetX 实现）组成：
`WAppPlugin` / `WAppPluginRunner` / `WLanguage` / `WLocaleConfig` / `WAppTheme` 在
`w_tools_app`；`WApp` / `WAppOptions` / 路由 / 底部弹窗在 `w_tools_app_getx`。
本文同时说明两层。

`w_tools_app` **不依赖 GetX**；`w_tools_app_getx` 强依赖 GetX（`get` 包），
提供 `WApp` / `WAppOptions` / 路由 / 底部弹窗，并复用 `w_tools_app` 的插件编排、
语言状态与外观配置。`WApp` 本质是对 `GetMaterialApp` 的增强包装。

## 快速判断
- 启动 → `WApp.options(WAppOptions(...)).start()`（2.0+）
- 插件顺序 → `WAppPlugin.dependsOn`
- 全局默认视图 → `WAppOptions.appWrapper`；`WAppPlugin` 是消费方自建插件的扩展点，子包不自带插件
- 强依赖 GetX
- 可运行示例：[packages/app_getx/example](../../packages/app_getx/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```text
packages/app/                         # 应用内核（GetX 无关）
└── lib/src/
    ├── plugins/
    │   ├── app_plugin.dart           # WAppPlugin
    │   └── app_plugin_runner.dart    # WAppPluginRunner
    ├── language/
    │   ├── language.dart             # WLanguage
    │   └── locale_config.dart        # WLocaleConfig
    └── theme/
        └── app_theme.dart            # WAppTheme

packages/app_getx/                    # GetX 实现层
└── lib/
    ├── w_tools_app_getx.dart          # 统一导出 + re-export app 类型
    └── src/
        ├── app.dart                  # WApp 启动器
        ├── options.dart              # WAppOptions
        ├── routing/
        │   ├── route_stack.dart      # WRouteStack
        │   └── route_observer.dart   # WRouteObserver
        └── sheet/
            └── bottom_sheet.dart     # WBottomSheet
```

---

## 1. WApp - 启动器

### 功能说明

`WApp` 是 GetX 启动器的入口，负责三件事：

1. **应用配置**：封装 `GetMaterialApp` 的常用参数（标题、路由、外观、国际化等）。
2. **插件生命周期**：委托 `WAppPluginRunner` 维护插件注册表与分层初始化。
3. **启动流程**：提供 `init`、`run`、`start` 三个入口，幂等且带非空校验。

`WLanguage` / `WLocaleConfig` / `WAppTheme` 定义在 `w_tools_app`；
`WApp` 只负责 GetX 适配（`GetMaterialApp`、`Get.locale`）。

### 配置方式

```dart
final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    // 或者：initialRoute: '/', getPages: [...]
  ),
);
await app.start();
```

优先级：`start()` 参数 > `WAppOptions` > 默认值。
必须提供 `home`，或同时提供 `initialRoute` + `getPages`；配置错误在构造时抛
`ArgumentError`。

### WAppOptions 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | `String` | — | **必填**，应用标题 |
| `home` | `Widget?` | null | 根页面；与 `initialRoute` + `getPages` 二选一 |
| `initialRoute` | `String?` | null | 初始路由；`home` 为 null 时必填 |
| `getPages` | `List<GetPage<dynamic>>?` | null | GetX 路由表；`home` 为 null 时必填 |
| `routes` | `Map<String, WidgetBuilder>?` | null | 普通命名路由 |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | null | 自定义 Navigator key |
| `theme` | `WAppTheme?` | null | 应用外观（亮/暗主题、模式、系统栏） |
| `translations` | `Translations?` | null | GetX 国际化翻译表 |
| `locale` | `Locale?` | null | 当前语言 |
| `fallbackLocale` | `Locale?` | null | 兜底语言 |
| `supportedLocales` | `List<Locale>?` | null | 显式覆盖；默认由 `localeConfig` 派生 |
| `localizationsDelegates` | `Iterable<LocalizationsDelegate<dynamic>>?` | null | 默认使用 `GlobalMaterialLocalizations.delegates` |
| `builder` | `TransitionBuilder?` | null | GetMaterialApp.builder；位于插件 builderWrapper 链之后（更外层） |
| `navigatorObservers` | `List<NavigatorObserver>?` | null | 额外的 navigator observers |
| `defaultTransition` | `Transition?` | null | GetX 默认转场动画 |
| `orientations` | `List<DeviceOrientation>` | `[portraitUp]` | 支持的屏幕方向 |
| `shouldApplyOrientations` | `bool` | `false` | 是否启动时应用 `orientations` |
| `appWrapper` | `Widget Function(Widget)?` | null | 包裹 GetMaterialApp；位于插件 wrapApp 之内 |
| `localeConfig` | `WLocaleConfig?` | null | 支持语言 / 首次语言 / 回退语言 |
| `plugins` | `List<WAppPlugin>` | `[]` | 启动插件 |
| `routeStack` | `WRouteStack?` | null | 自定义路由栈；默认新建 |
| `unknownRoute` | `GetPage<dynamic>?` | null | GetX 未知路由 |

`WAppOptions` 是不可变值对象：构造时会拷贝 list / map，并实现 `==` / `hashCode`。

### WAppTheme 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `light` | `ThemeData?` | null | 亮色主题 |
| `dark` | `ThemeData?` | null | 暗色主题 |
| `mode` | `ThemeMode` | `ThemeMode.system` | 主题模式 |
| `systemUiOverlayStyle` | `SystemUiOverlayStyle?` | null | 系统 UI 样式；`null` 不干预 |

`WAppTheme` 是应用外观值对象，实现 `==` / `hashCode` / `copyWith`；不要和 `WAsyncTheme`（Widget）混用。

### 插件管理方法

| 方法 | 说明 |
|------|------|
| `addPlugin(WAppPlugin plugin)` | 注册单个插件（init 前） |
| `addPlugins(Iterable<WAppPlugin> plugins)` | 批量注册（init 前） |
| `removePlugin(String name)` | 按名称移除（init 前） |
| `clearPlugins()` | 清空所有插件（init 前） |

`init` 之后再修改插件会抛 `StateError`，避免“插件没跑 onInit 却参与了 wrapper”的静默错误。

### 生命周期方法

| 方法 | 幂等 | 说明 |
|------|------|------|
| `init({VoidCallback? onLazyInit, List<Future<void>>? customTasks})` | ✅ | `ensureInitialized` → 系统设置 → 插件分层初始化 → `customTasks` 并行 → `onLazyInit` 首帧后回调 |
| `run({...})` | ❌ | 启动应用；必须先 `init`，且只能调用一次 |
| `start({...})` | ❌ | 一站式启动：`init` + `run`；只能调用一次 |

### 包裹顺序（由外向内）

```text
插件 wrapApp（后注册者更外）
  → WAppOptions.appWrapper
    → GetMaterialApp
      → WApp.builder（MaterialApp 内部）
```

builder 链（由内向外）：

```text
插件 builderWrapper[0] → 插件 builderWrapper[1] → ... → WApp.builder
```

### 插件初始化流程

- 同层插件**并行**初始化（`Future.wait`）。
- 跨层**串行**。
- 插件 `name` 重复、`dependsOn` 引用未注册插件、存在循环依赖时抛 `StateError`。

### `builderWrapper` 与 `.sp`

如果 `ThemeData.extensions` 里的 `WTextStyles` 使用 `flutter_screenutil` 的 `.sp`，
必须放在 `builderWrapper`（或 `ScreenUtilInit.builder`）中构建：

```dart
class TextStylesPlugin with WAppPlugin {
  @override
  String get name => 'text-styles';

  @override
  TransitionBuilder get builderWrapper => (context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [buildAppTextStyles()],
      ),
      child: child ?? const SizedBox.shrink(),
    );
  };
}
```

不要在 `main` / 顶层 `final` 中构造：

```dart
// 错：ScreenUtil 尚未 configure
final appTheme = AppTheme.data;
```

`wrapApp` 在 MaterialApp 外，没有 Theme；需要 Theme/`.sp` 的排版扩展用
`builderWrapper`。`WAsyncTheme` 这类只存 builder、不立即计算 `.sp`
的配置仍可放在 `wrapApp`。

### 使用示例

```dart
Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'My App',
      home: const HomePage(),
      theme: WAppTheme(
        light: AppTheme.light,
        dark: AppTheme.dark,
        mode: ThemeMode.system,
      ),
      translations: AppTranslations(),
      localeConfig: WLocaleConfig(
        supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
        initialLanguage: 'zh_CN',
        fallbackLanguage: 'en_US',
      ),
      plugins: [AuthPlugin()],
    ),
  );

  await app.start(
    onLazyInit: () {
      // 首帧后执行的轻量任务
    },
    customTasks: [
      // 必须在 run 前完成的任务（并行执行）
      WApi.setup(),
      WStorage.init(),
    ],
  );
}
```

---

## 2. WAppPlugin - 插件接口

### 功能说明

`WAppPlugin` 是一个 `mixin class`，业务/功能方可以通过混入该接口实现自己的插件，并注册到 `WApp`。

插件体系让认证、推送、埋点、主题切换等横切关注点无需侵入 `main.dart`，并支持依赖声明和生命周期钩子。

### 必填字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | `String` | 插件唯一名称（重复注册时 `WApp.init` 抛 `StateError`） |

### 依赖声明

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `dependsOn` | `List<String>` | `[]` | 依赖的其他插件 `name` 列表；`WApp.init` 按此分层执行初始化 |

> 依赖是**声明式**的，而非注册顺序。即使 A 在 B 之前注册，只要 B 在 `dependsOn` 中声明了 A，A 会先初始化。

### 钩子方法

| 钩子 | 返回类型 | 说明 |
|------|----------|------|
| `onInit()` | `Future<void>` | 初始化阶段被调用，参与分层编排 |
| `builderWrapper` | `TransitionBuilder?` | 对 `MaterialApp.builder` 的再次包裹；**后注册的插件在 builder 链更外层** |
| `wrapApp` | `Widget Function(Widget)` | 对根 Widget 的包裹；**后注册者最外**。位于 MaterialApp 之外，没有 Theme/MediaQuery |
| `navigatorObservers` | `List<NavigatorObserver>?` | 额外的 `NavigatorObserver`，会与 `WAppOptions.navigatorObservers` 合并 |

### 使用示例

```dart
class AuthPlugin with WAppPlugin {
  @override
  String get name => 'auth';

  @override
  Widget wrapApp(Widget child) => AuthProvider(child: child);

  @override
  Future<void> onInit() async {
    await AuthService.initialize();
  }
}

class PushPlugin with WAppPlugin {
  @override
  String get name => 'push';

  @override
  List<String> get dependsOn => ['auth'];
}
```

### WAppPluginRunner（w_tools_app）

`WAppPluginRunner` 是 GetX-free 的插件注册表与分层初始化器；`WApp` 内部委托它，
非 GetX 应用壳也可以直接使用：

```dart
final runner = WAppPluginRunner([EnvPlugin(), ServicePlugin()]);
await runner.init();
```

- 同层并行、跨层串行；
- `name` 重复 / 依赖未注册 / 循环依赖抛 `StateError`；
- `init` 之后不可增删插件。

---

## 3. WLanguage - 语言管理

### 功能说明

`WLanguage` 定义在 `w_tools_app`，每个 `WApp` 持有一个实例（`app.language`）。它负责：

- 支持语言列表；
- 当前语言（唯一可写入口 `changeLanguage`）；
- 只读变化流 / 值监听；
- 语言码 ↔ `Locale` 解析。

没有全局单例，也没有第二份可写的 `currentLanguage`。

### 公开成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `supportedLanguages` | `Map<String, String>` | 只读支持列表 |
| `currentLanguage` | `String` | 当前语言码 |
| `currentLanguageName` | `String` | 当前语言展示名；未收录时回退为语言码 |
| `currentLocale` | `Locale` | 当前语言对应 Locale（支持 `en` / `zh_CN` / `zh_Hant_TW`） |
| `languageChanges` | `Stream<String>` | 只读变化流 |
| `languageListenable` | `ValueListenable<String>` | 只读值监听，可用于 `ValueListenableBuilder` |
| `changeLanguage(String)` | `bool` | 切换语言；未收录返回 false。只触发 GetMaterialApp 重建，不整树 reassemble |
| `listenLanguageChange(...)` | `StreamSubscription<String>` | 监听语言变化，可取消 |
| `hasExplicitSelection` | `bool` | 是否已显式选择语言 |

### 使用示例

```dart
// 切换
app.language.changeLanguage('en_US');

// 监听
final subscription = app.language.listenLanguageChange((code) {
  debugPrint('语言已切换为 $code');
});
await subscription.cancel();

// 只读值监听
ValueListenableBuilder<String>(
  valueListenable: app.language.languageListenable,
  builder: (context, code, _) => Text(app.language.currentLanguageName),
);
```

---

## 4. WRouteStack - 路由栈管理

### 功能说明

维护**根 Navigator** 的路由栈（由 `WRouteObserver` 记录），通过 `app.routeStack` 访问。
每个 `WApp` 拥有自己的栈；没有全局 `defaultStack`。仅覆盖根路由；嵌套 Navigator 需要自行管理。

### 只读成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `routes` | `UnmodifiableListView<Route>` | 当前根 Navigator 的路由栈（只读视图，O(1)） |

### 操作方法

| 方法 | 返回 | 说明 |
|------|------|------|
| `removeRouteIfExists(String page)` | `bool` | 栈中存在该路由名则移除 |
| `removeRoutesAfter(String page)` | `int` | 移除该路由名**上方**的所有路由（保留 `page`），返回数量 |
| `popUntilRoute(String page)` | `bool` | 反复 `pop` 直到栈顶为 `page`；目标不存在返回 false 且不动作 |

> `addRoute` / `removeRoute` / `clearRoutes` 是 `@internal`，由 `WRouteObserver` 自动调用。

### 使用示例

```dart
app.routeStack.removeRoutesAfter('/profile');
app.routeStack.popUntilRoute('/profile');
```

---

## 5. WRouteObserver - 路由观察者

### 功能说明

实现 `NavigatorObserver`，把根 Navigator 的路由变化同步到指定的 `WRouteStack`。
`WApp` 会自动为 `app.routeStack` 追加一个 observer；如果调用方已经提供了同栈的
`WRouteObserver`，不会重复追加。

默认只记录页面路由；`PopupRoute`（底部弹窗 / 对话框）不进入路由栈，需要时传
`recordPopups: true`。

### 观察的事件

| 方法 | 行为 |
|------|------|
| `didPush(route, previousRoute)` | 追加到 `WRouteStack.routes`（PopupRoute 默认跳过） |
| `didPop(route, previousRoute)` | 从 `WRouteStack.routes` 移除 |
| `didReplace(newRoute, oldRoute)` | 移除旧路由、记录新路由 |
| `didRemove(route, previousRoute)` | 从 `WRouteStack.routes` 移除 |

---

## 6. WBottomSheet - 底部弹窗

### 功能说明

基于 `Get.bottomSheet` 的便捷封装。特点：

- 遮罩点击由 Get 的 barrier 负责（`isDismissible: false` 时不可点遮罩关闭）。
- 内容按自身高度布局，不会被强制撑满全屏；`isScrollControlled` 默认 true。
- 返回 `Get.back(result:)` 的结果（`Future<T?>`）。

### 使用示例

```dart
final result = await WBottomSheet.show<String>(
  Container(
    height: 300,
    child: const Center(child: Text('这是底部弹窗内容')),
  ),
);
```

---

## 完整配置示例

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'My App',
      home: const HomePage(),
      theme: WAppTheme(
        light: AppTheme.light,
        dark: AppTheme.dark,
        mode: ThemeMode.system,
      ),
      translations: AppTranslations(),
      localeConfig: WLocaleConfig(
        supportedLanguages: {
          'zh_CN': '简体中文',
          'en_US': 'English',
        },
        initialLanguage: 'zh_CN',
        fallbackLanguage: 'en_US',
      ),
      plugins: [AuthPlugin(), PushPlugin()],
    ),
  );

  await app.start(
    builder: (context, child) {
      return GlobalLoading(child: child ?? const SizedBox.shrink());
    },
    onLazyInit: () {
      WBottomSheet.show(const Text('欢迎使用！'));
    },
    customTasks: [
      AuthService.restoreSession(),
      Analytics.init(),
    ],
  );
}
```

---

## 注意事项

- **强依赖 GetX**：整个子包（包括 `WBottomSheet`）基于 `get` 包实现。
- **`init` 必须在 `run` 之前调用**；`start` 会自动处理顺序。
- **插件依赖是声明式的**：`WAppPlugin.dependsOn` 决定初始化顺序，而非 `addPlugin` 的调用顺序。
- **`start` / `run` 只能调用一次**，重复调用抛 `StateError`。
- **`home` 与 `initialRoute` + `getPages` 二选一**；`WAppOptions` 构造时校验。
- **路由栈仅覆盖根 Navigator**：嵌套 Navigator 的路由变化不会进入 `app.routeStack.routes`。
- **`WLanguage.currentLocale` 解析约定**：语言码用下划线或连字符分隔，支持脚本码（`zh_Hant_TW`）。
- **语言列表是实例状态**：`app.language` 与 `WAppOptions.localeConfig` 二选一即可；
  `WAppConfig` 已删除，不再有全局静态语言配置。
- **应用外观**：`theme` / `darkTheme` / `themeMode` / `systemUiOverlayStyle` 统一放 `WAppTheme`；
- **Flutter 本地化**：默认使用 `GlobalMaterialLocalizations.delegates`；
  需要自定义时传 `WAppOptions.localizationsDelegates`。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
