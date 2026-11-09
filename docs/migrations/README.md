# 迁移索引

按包与版本排列；升级前先读对应大版本条目。

> **最低环境**：Flutter 子包（core / async / ui / form / api / app / toast / map / qr）与根包
> 统一要求 Dart `^3.10.0`、Flutter `>=3.38.0`（与 CI 唯一验证的最低版本一致）。
> 纯 Dart 工具包（figma / device / e2e）仍为 Dart `>=3.6.0`；`cli` 为 `^3.10.0`。

## core

- [2.1](core-2.1.md)：token 键名移入 `WToken`
- [2.2](core-2.2.md)：`WValidator` 走 `WRegExp`；旧正则 / 清洗 / 密码哈希弃用
- [2.3](core-2.3.md)：`WDebounce` / `WThrottle`；`WCountdown.remaining`
- [3.0](core-3.0.md)：删除 WConfig / 旧正则 / WUx 防抖节流 / 密码哈希 / 平台分发 / 字符串清洗
- [2.4](core-2.4.md)：`setObject` 对称、节流解锁、倒计时监听、平台多参 API 弃用

## ui

- [4.0](ui-4.0.md)：按钮默认样式跟随主题
- [4.1](ui-4.1.md)：图片加载器内部化、缓存策略弃用
- [4.2](ui-4.2.md)：`WImageLoadConfig` 更名、错误 `kind`
- [4.3](ui-4.3.md)：图片预设构造弃用、默认作用域收 `WImageLoadConfig`
- [4.4](ui-4.4.md)：`WHexColor`、布局糖弃用、String 扩展合并
- [4.5](ui-4.5.md)：`WScreen.of(context)`、图片装饰 / 哈希修复
- [4.6](ui-4.6.md)：`WActionRow` / `WSelectableRow`
- [5.0](ui-5.0.md)：删除 WRowButtons / 图片预设 / 错误子类 / 布局糖等
- [4.7](ui-4.7.md)：四个组件的 config 可选
- [6.0](ui-6.0.md)：`WImage` 单入口，删除旧构造器与 String 图片扩展
- [7.0](ui-7.0.md)：`WImageLoadConfig` → `WImageLoadOptions`、`WImageDefaultsScope` → `WImageTheme`、删除 `WImageStyle.merge` / `WImage.type` / `WImage.data`
- [8.0](ui-8.0.md)：删除 Config 过渡入口 / `WButtonMetrics` / Builder；角标自有类型；按钮 motion / semantics 参数化

## form

- [3.0](form-3.0.md)：默认边框主题派生、错误默认可见
- [3.1](form-3.1.md)：`WFormIcons`
- [3.2](form-3.2.md)
- [4.0](form-4.0.md)：删除 `WFormDefaults` / Builder / Row 扩展：`Config.build` / `*Core` 内部化
- [5.0](form-5.0.md)：移除 8 个公开可变字段 Config，改直接字段参数 / `WFormFieldStyle`
- [5.1](form-5.1.md)：多选未配置 `hintText` 时不再显示 `ALL`
- [6.0](form-6.0.md)：移除单项图标参数，内部类型不再导出，`WFormFieldButton<T>`

## async

- [2.0](async-2.0.md)：执行核收敛（`WAsyncOptions` / `WAsyncLoading` / 方法改名）
- [3.0](async-3.0.md)：删除 `WAsyncViewDefaults` / `WAsyncSliverDefaults`
- [2.1](async-2.1.md)：`WAsyncTheme`
- [4.0](async-4.0.md)：`WAsyncStateSliver.state` 改为 `ValueListenable`
- [4.1](async-4.1.md)：取消立即返回、`options.onError` 覆盖 `Error`、`WAsyncThemeViews` / `withToken` / `runValue`
- [5.0](async-5.0.md)：不再用 null 表示失败 / 取消，改 `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`
- [6.0](async-6.0.md)：Controller 改 `onError`、`onError` 去 nullable、error builder retry 可空

## toast

- [1.2](toast-1.2.md)：`WToastStyle` 拆分
- [1.3](toast-1.3.md)：`WToastTheme` / `runWithLoading`
- [2.0](toast-2.0.md)：删除 `WToastConfig`

## api / app / map / qr

- [api 2.0](api-2.0.md)：日志片段、注册表配置冲突报错
- [map_google 2.0](map_google-2.0.md)：`WMapConfig` → `WMapOptions`
- [api 2.1](api-2.1.md)：401 重试不再隐式注册 Dio
- [api 5.0](api-5.0.md)：删除日志旧 bool 参数
- [app 1.1](app-1.1.md)：`WBottomSheet` 透传、路由修复
- [app 1.2](app-1.2.md)：`WAppOptions` / `WLocaleConfig` / `WRouteStack`
- [app 2.0](app-2.0.md)：删除字段版 `WApp` 与静态 `WRoute`
- [app 3.0](app-3.0.md)：拆成 `w_tools_app`（插件契约）+ `w_tools_app_getx`（GetX 启动器）
- [app 3.1](app-3.1.md)：GetX-free 内核类型（`WAppPluginRunner` / `WLanguage` / `WLocaleConfig` / `WAppTheme`）
- [app_getx 2.0](app_getx-2.0.md)：实例化语言/路由栈，删除 `WAppConfig` / `defaultStack`
- [map 1.3.1](map-1.3.1.md)：Marker 复用、控制器清理
- [map 2.0](map-2.0.md)：删除 `onDataUpdated`
- [map 3.0](map-3.0.md)：拆成 `w_tools_map`（模型）+ `w_tools_map_google`（实现）
- [qr 1.1](qr-1.1.md)：`onScanned` 可选、扫描间隔 400ms
- [qr 2.0](qr-2.0.md)：`WQrController` 归调用方、`WQrOverlayStyle`、`WQrScanResult`、删除 `WQrViewState`
