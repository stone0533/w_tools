# App 模块文档

## 概述

App 模块（`w_tools_app` 子包）提供了一套一站式的应用启动方案，核心类 `WApp` 封装了 `GetMaterialApp` 的配置、插件系统、语言切换、路由管理和底部弹窗。

该子包**强依赖 GetX**（`get` 包），不可替换。`WApp` 本质是对 `GetMaterialApp` 的增强包装：保留 GetX 全部能力的同时，补充了插件生命周期管理、语言 API 和路由栈操作。

## 模块结构

```
app/
├── w_tools_app.dart                          # 统一导出文件
└── src/
    ├── app.dart                              # WApp 启动器
    ├── plugins/
    │   └── app_plugin.dart                   # WAppPlugin 插件接口
    └── utils/
        ├── app_config.dart                   # WAppConfig 语言配置
        ├── bottom_sheet.dart                 # WBottomSheet
        ├── language.dart                     # WLanguage
        ├── route.dart                        # WRoute 路由管理
        └── router_observer.dart              # WRouteObserver
```

---

## 1. WApp - 启动器

### 功能说明

`WApp` 是整个子包的入口，负责三件事：

1. **应用配置**：封装 `GetMaterialApp` 的常用参数（标题、路由、主题、国际化等）。
2. **插件生命周期**：维护插件注册表，按 `dependsOn` 声明构建分层依赖图，分层初始化。
3. **启动流程**：提供 `init`、`run`、`start` 三个入口，幂等且带非空校验。

### 配置字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | `String` | — | **必填**，应用标题 |
| `initialRoute` | `String` | — | **必填**，初始路由 |
| `getPages` | `List<GetPage<dynamic>>` | — | **必填**，GetX 路由表 |
| `orientations` | `List<DeviceOrientation>` | `[portraitUp]` | 支持的屏幕方向，默认仅竖屏 |
| `systemUiOverlayStyle` | `SystemUiOverlayStyle?` | null | 系统 UI 样式 |
| `builder` | `TransitionBuilder?` | null | 业务侧 builder（位于插件 wrapper 之后） |
| `navigatorObservers` | `List<NavigatorObserver>?` | null | 额外的 navigator observers |
| `defaultTransition` | `Transition?` | null | GetX 默认转场动画 |
| `theme` | `ThemeData?` | null | 主题数据 |
| `translations` | `Translations?` | null | GetX 国际化翻译表 |
| `locale` | `Locale?` | null | 当前语言 |
| `fallbackLocale` | `Locale?` | null | 兜底语言 |
| `appWrapper` | `Widget Function(Widget)?` | null | 最外层包裹器（在所有插件 wrapApp 之外） |

### 插件管理方法

| 方法 | 说明 |
|------|------|
| `addPlugin(WAppPlugin plugin)` | 注册单个插件 |
| `addPlugins(Iterable<WAppPlugin> plugins)` | 批量注册插件 |
| `removePlugin(String name)` | 按名称移除插件 |
| `clearPlugins()` | 清空所有已注册插件 |

### 生命周期方法

| 方法 | 幂等 | 说明 |
|------|------|------|
| `init({void Function()? onLazyInit, Future<void> Function()? customTasks})` | ✅ | 初始化阶段：`WidgetsFlutterBinding.ensureInitialized` → 系统设置 → 插件分层初始化 → `customTasks` 并行 → `onLazyInit` 首帧后回调 |
| `run({...})` | ❌ | 启动应用。**必须先 `init`**；会校验 `title`、`initialRoute`、`getPages` 非空 |
| `start({...})` | ❌ | 一站式启动：`start = init + run`，参数合并 |

### 包裹顺序（由内向外）

```
GetMaterialApp
  → WApp.builder
    → WApp.appWrapper
      → 各插件 wrapApp（后注册者在最外层）
```

builder 链（由内向外）：

```
插件 builderWrapper[0] → 插件 builderWrapper[1] → ... → WApp.builder
```

### 插件初始化流程

`init` 内部对已注册插件构建依赖分层图后按层执行：

- 同层插件**并行**初始化（`Future.wait`）。
- 跨层**串行**（上一层全部完成后下一层才开始）。
- 以下情况会抛 `StateError`：
  - 插件 `name` 重复；
  - `dependsOn` 中声明的依赖未被注册；
  - 存在循环依赖。

### 使用示例

```dart
void main() {
  WApp.addPlugin(AuthPlugin());
  WApp.start(
    title: 'My App',
    initialRoute: Routes.home,
    getPages: Routes.pages,
    theme: AppTheme.light,
    translations: AppTranslations(),
    locale: const Locale('zh', 'CN'),
    fallbackLocale: const Locale('en', 'US'),
    onLazyInit: () async {
      // 首帧后执行的轻量任务
      await WToast.init();
    },
    customTasks: () async {
      // 必须在 run 前完成的初始化（并行）
      await Future.wait([
        WApi.setup(),
        WStorage.init(),
      ]);
    },
  );
}
```

---

## 2. WAppPlugin - 插件接口

### 功能说明

`WAppPlugin` 是一个 `mixin class`，业务/功能方可以通过混入该接口实现自己的插件，并注册到 `WApp`。

插件体系让诸如认证、推送、埋点、主题切换等横切关注点无需侵入 `main.dart`，并支持依赖声明和生命周期钩子。

### 必填字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | `String` | 插件唯一名称（重复注册时 `WApp.init` 抛 `StateError`） |

### 依赖声明

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `dependsOn` | `List<String>` | `[]` | 依赖的其他插件 `name` 列表；`WApp.init` 按此分层执行初始化 |

> 依赖是**声明式**的，而非注册顺序。即使 A 在 B 之前注册，只要 B 在 `dependsOn` 中声明了 A，A 会先初始化。

### 钩子方法（全部可选实现）

| 钩子 | 返回类型 | 说明 |
|------|----------|------|
| `onInit()` | `Future<void>` / `void` | 初始化阶段被调用，可返回 Future 参与分层编排 |
| `builderWrapper` | `TransitionBuilder?` | 对 `MaterialApp.builder` 的再次包裹；**后注册的插件在 builder 链更外层** |
| `wrapApp` | `Widget Function(Widget)?` | 对根 Widget 的包裹（如注入 Provider、全局主题等）；**后注册者最外** |
| `navigatorObservers` | `List<NavigatorObserver>?` | 额外的 `NavigatorObserver`，会与 `WApp.navigatorObservers` 合并 |

### 使用示例

```dart
mixin class AuthPlugin implements WAppPlugin {
  @override
  String get name => 'auth';

  @override
  void Function(Widget)? get wrapApp =>
      (child) => AuthProvider(child: child);

  @override
  Future<void> onInit() async {
    await AuthService.initialize();
  }
}

// 另一个插件依赖 auth
mixin class PushPlugin implements WAppPlugin {
  @override
  String get name => 'push';

  @override
  List<String> get dependsOn => ['auth']; // 等 auth 初始化完再 init 自己
}
```

---

## 3. WAppConfig - 应用配置

### 功能说明

维护支持的语言列表和当前语言。为 `WLanguage` 提供语言元数据。

### 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `supportedLanguages` | `Map<String, String>` | 键为语言代码（如 `'zh_CN'`），值为语言展示名（如 `'简体中文'`）；**整体赋值** |
| `currentLanguage` | `String` | 当前语言代码 |

### 使用示例

```dart
WAppConfig.supportedLanguages = {
  'zh_CN': '简体中文',
  'en_US': 'English',
};
WAppConfig.currentLanguage = 'zh_CN';
```

---

## 4. WLanguage - 语言管理

### 功能说明

提供语言切换、变更监听和当前 Locale 查询。底层使用 GetX 的状态响应式能力（`RxString`）。

### 公开成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `changeLanguage(String languageCode)` | 方法 | 切换语言 |
| `listenLanguageChange(void Function(String) callback)` | 方法 | 注册语言变更监听（返回可调用对象用于取消） |
| `languageStream` | `RxString` | 当前语言的响应式流 |
| `currentLocale` | `Locale?` | 将当前 `languageCode` 转为 `Locale`（需代码形如 `zh_CN` 下划线分隔） |
| `currentLanguageName` | `String?` | 当前语言在 `WAppConfig.supportedLanguages` 中的展示名 |

### 使用示例

```dart
// 切换
WLanguage.changeLanguage('en_US');

// 监听（返回 dispose 函数）
final dispose = WLanguage.listenLanguageChange((code) {
  debugPrint('语言已切换为 $code');
});

// 在 State.dispose 中记得调用
dispose();
```

---

## 5. WRoute - 路由栈管理

### 功能说明

维护**根 Navigator** 的路由栈（由 `WRouteObserver` 记录），并提供几种常用的栈操作。仅覆盖根路由；嵌套 Navigator 需要自行管理。

### 只读成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `routes` | `List<Route>` | 当前根 Navigator 的路由栈（**只读**） |

### 操作方法

| 方法 | 说明 |
|------|------|
| `removeRouteIfExists(PageRoute page)` | 栈中存在该路由则移除（`Navigator.removeRoute`） |
| `removeRoutesAfter(PageRoute page)` | 移除该路由**上方**的所有路由（直到 `page` 为止，但保留 `page`） |
| `popUntilRoute(PageRoute page)` | 反复 `pop` 直到栈顶为 `page` |

> `addRoute` / `removeRoute` 是**内部方法**，由 `WRouteObserver` 在 `didPush` / `didPop` / `didRemove` / `didReplace` 中自动调用。

### 使用示例

```dart
// 假设我们要在栈中间的某个路由上「截断」后续路由
final middleRoute = WRoute.routes.firstWhere((r) => r.settings.name == '/profile');
WRoute.removeRoutesAfter(middleRoute as PageRoute);
```

---

## 6. WRouteObserver - 路由观察者

### 功能说明

实现 `NavigatorObserver`，自动把根 Navigator 的路由变化同步到 `WRoute.routes`。**通常不需要手动实例化**——`WApp` 会自动将其加入 `GetMaterialApp.navigatorObservers`。

### 观察的事件

| 方法 | 行为 |
|------|------|
| `didPush(route, previousRoute)` | 追加到 `WRoute.routes` |
| `didPop(route, previousRoute)` | 从 `WRoute.routes` 移除 |
| `didReplace(newRoute, oldRoute)` | 替换 `WRoute.routes` 中的对应条目 |
| `didRemove(route, previousRoute)` | 从 `WRoute.routes` 移除 |

---

## 7. WBottomSheet - 底部弹窗

### 功能说明

基于 `Get.bottomSheet` 的便捷封装。特点：

- 自建遮罩点击区（点击遮罩可关闭）。
- 始终 `isScrollControlled: true`，内容区支持 `ListView` / `SingleChildScrollView` 等滚动控件。
- 依赖 GetX。

### 使用示例

```dart
await WBottomSheet.show(
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
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  // 1. 语言配置
  WAppConfig.supportedLanguages = {
    'zh_CN': '简体中文',
    'en_US': 'English',
  };

  // 2. 注册插件（可选）
  WApp.addPlugin(AuthPlugin());
  WApp.addPlugin(PushPlugin());

  // 3. 一站式启动
  WApp.start(
    title: 'My App',
    initialRoute: '/home',
    getPages: [
      GetPage(name: '/home', page: () => const HomePage()),
      GetPage(name: '/profile', page: () => const ProfilePage()),
    ],
    orientations: [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    systemUiOverlayStyle: SystemUiOverlayStyle.dark,
    theme: AppTheme.light,
    translations: AppTranslations(),
    locale: const Locale('zh', 'CN'),
    fallbackLocale: const Locale('en', 'US'),
    builder: (context, child) {
      // 业务侧额外包裹（比如全局 Loading）
      return GlobalLoading(child: child ?? const SizedBox.shrink());
    },
    onLazyInit: () async {
      // 首帧渲染后执行（不阻塞启动）
      await WBottomSheet.show(
        const Text('欢迎使用！'),
      );
    },
    customTasks: () async {
      // 启动前必须完成的任务（并行）
      await Future.wait([
        AuthService.restoreSession(),
        Analytics.init(),
      ]);
    },
  );
}
```

---

## 注意事项

- **强依赖 GetX**：整个子包（包括 `WBottomSheet`）基于 `get` 包实现，无法替换为其他状态管理/路由方案。
- **`init` 必须在 `run` 之前调用**：直接调用 `run` 而未先 `init` 会触发断言失败。`start` 方法会自动处理这个顺序。
- **插件依赖是声明式的**：`WAppPlugin.dependsOn` 决定初始化顺序，而非 `addPlugin` 的调用顺序。
- **`run` 会校验非空参数**：`title`、`initialRoute`、`getPages` 任一为空会在运行时抛出错误。
- **路由栈仅覆盖根 Navigator**：嵌套 Navigator 的路由变化不会进入 `WRoute.routes`。
- **`WLanguage.currentLocale` 解析约定**：语言代码必须形如 `zh_CN`（下划线分隔），否则 `currentLocale` 会返回 null。
- **`WAppConfig.supportedLanguages` 是整体赋值**：使用 `=` 覆盖，不提供 `.add` 增量 API。
- **`WAppPlugin.onInit` 可返回 Future**：若返回 `Future<void>`，`WApp.init` 会等待它完成再进入下一层。
