# 迁移索引

按包与版本排列；升级前先读对应大版本条目。

> **最低环境**：Flutter 子包（core / async / ui / form / api / app / toast / map / qr）与根包
> 统一要求 Dart `^3.10.0`、Flutter `>=3.38.0`（与 CI 唯一验证的最低版本一致）。
> 纯 Dart 工具包（figma / device / e2e）仍为 Dart `>=3.6.0`；`cli` 为 `^3.10.0`。

## core

- [2.1](core-2.1.md)：token 键名移入 `WToken`
- [2.2](core-2.2.md)：`WValidator` 走 `WRegExp`；旧正则 / 清洗 / 密码哈希弃用
- [2.3](core-2.3.md)：`WDebounce` / `WThrottle`；`WCountdown.remaining`
- [2.4](core-2.4.md)：`setObject` 对称、节流解锁、倒计时监听、平台多参 API 弃用

## ui

- [4.0](ui-4.0.md)：按钮默认样式跟随主题
- [4.1](ui-4.1.md)：图片加载器内部化、缓存策略弃用
- [4.2](ui-4.2.md)：`WImageLoadConfig` 更名、错误 `kind`
- [4.3](ui-4.3.md)：图片预设构造弃用、默认作用域收 `WImageLoadConfig`
- [4.4](ui-4.4.md)：`WHexColor`、布局糖弃用、String 扩展合并
- [4.5](ui-4.5.md)：`WScreen.of(context)`、图片装饰 / 哈希修复
- [4.6](ui-4.6.md)：`WActionRow` / `WSelectableRow`
- [4.7](ui-4.7.md)：四个组件的 config 可选

## form

- [3.0](form-3.0.md)：默认边框主题派生、错误默认可见
- [3.1](form-3.1.md)：`WFormIcons`
- [3.2](form-3.2.md)：`Config.build` / `*Core` 内部化

## async

- [2.0](async-2.0.md)：执行核收敛（`WAsyncOptions` / `WAsyncLoading` / 方法改名）
- [2.1](async-2.1.md)：`WAsyncTheme`

## toast

- [1.2](toast-1.2.md)：`WToastStyle` 拆分
- [1.3](toast-1.3.md)：`WToastTheme` / `runWithLoading`

## api / app / map / qr

- [api 2.0](api-2.0.md)：日志片段、注册表配置冲突报错
- [api 2.1](api-2.1.md)：401 重试不再隐式注册 Dio
- [app 1.1](app-1.1.md)：`WBottomSheet` 透传、路由修复
- [app 1.2](app-1.2.md)：`WAppOptions` / `WLocaleConfig` / `WRouteStack`
- [map 1.3.1](map-1.3.1.md)：Marker 复用、控制器清理
- [qr 1.1](qr-1.1.md)：`onScanned` 可选、扫描间隔 400ms
