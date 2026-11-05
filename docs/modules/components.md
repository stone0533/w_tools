# 组件目录（先查这里，没有再动手）

> CLI 内置同一份目录：`dart run w_tools_cli:w_tools list <关键词>` / `:explain <组件名>`。

> **§1~§9 的表格由 `catalog/components.yaml` 生成**（`dart run tool/gen_catalog.dart`），手改会被覆盖；要改组件说明请改 YAML。
>
> 用法：**按用途找**。找到就用，找不到再看文末「待补」清单 —— 待补的东西应该先进消费方的
> `lib/app/design_system/`，出现第二个用例后再上移进包（见 [`docs/conventions.md`](../conventions.md)）。

## 1. 页面骨架与导航

<!-- catalog:1:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WScaffold` | ui | 页面壳：默认 WAppBar、body、底部导航/FAB、安全区 | 任意顶部叠放用页面层 Container/Stack |
| `WAppBar` | ui | 标准顶部导航栏（leading/title/actions/bottom） | 任意叠放/覆盖布局在页面层用 Container/Stack |
| `WNavBar` / `WNavController` | ui | 底部 tab 栏；controller 需 vsync 并由页面 State dispose | 不要自己写 `BottomNavigationBar` |
| `WTabBar` | ui | 顶部 tab；依赖 TabController / DefaultTabController | 需要下划线跟随的复杂交互时先看它够不够 |
| `WStep` / `WStepFlow` | ui | 步骤条（注册流程等） | 背景/高度用外层 Container；多步骤注意横向空间 |
<!-- catalog:1:end -->

## 2. 文本与图标

<!-- catalog:2:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WText` / `WTextVariant` / `WTextStyles` | ui | 语义文字样式、overrides、maxLines、textScaler | 不要再用 `WTextConfig`；已移除，使用 `WTextStyles` |
| `WImage` | ui | 网络图/资源图（缓存、重试、占位） | 不要裸用 `Image.network` |
| `WImageSource` | ui | WImage 的来源：network / asset / file / base64 / provider / parse | 不要用已删除的 WImage.network / asset / file / data |
<!-- catalog:2:end -->

> **图标 + 文字排成一行**（垂直居中）：目前没有组件，见文末「待补」——
> 不要用 `Row + Icon + Text`，中文字形在行盒里偏下，图标会看着偏高 1.5~2.5px。

## 3. 按钮与操作

<!-- catalog:3:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WButton` | ui | 真正的按钮（label/icon + style/size/loading） | 任意 child 点击用 `WPressable` |
| `WPressable` | ui | 任意 child 的点击 + 基础效果（无 button 语义） | 需要 button 语义时用 `WButton` |
| `WActionRow` / `WSelectableRow` | ui | 横向滚动按钮行：`WActionRow` 无选中、`WSelectableRow` 单选高亮 | 旧的 `WRowButtons` 已在 5.0 删除；纯静态排列直接用 `Row` |
| `WBadge` | ui | 角标数字 | — |
<!-- catalog:3:end -->

## 4. 布局与容器

<!-- catalog:4:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WClipRRect` | ui | 裁剪 | — |
| `WScreen` | ui | 屏幕 / 字体适配（w/h/sp）、状态栏 / 底部安全区 | 不要重复用 MediaQuery 手写全局适配 |
| `WAssets` | ui | 图片资源前缀唯一开关 | 不要硬编码 `assets/images/` |
<!-- catalog:4:end -->

## 5. 表单

<!-- catalog:5:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WForm` | form | 页面表单容器：主题 / Scope / 只读 / 默认字段样式 / 默认校验 | 不要手写 `WFormTheme + WFormScope + WFormReadOnlyScope` |
| `WFormController` | form | 表单数据 / 字段值 / 校验入口 | 多个 WForm 不要共用一个 controller |
| `WFormTextField` | form | 直接文本 / 密码字段（label / message / validator） | 不要默认写 `WFormTextFieldConfig().build(...)` |
| `WFormDropdown` | form | 直接下拉字段（items / 初始值 / icon / contentPadding） | 多选用 `WFormMultiDropdown`；自定义弹层用 `WFormPopup` |
| `WFormMultiDropdown` | form | 直接多选字段（items / disabledKeys / 选项样式） | 单选用 `WFormDropdown` |
| `WFormDatePicker` | form | 直接日期字段（displayFormat / firstDate / lastDate） | 时间选择不在本组件范围；自定义弹层用 `WFormPopup` |
| `WFormCheckbox` | form | 直接复选字段（title 必填，默认 bordered: false） | 多选用 `WFormMultiDropdown` |
| `WFormRadioGroup` | form | 直接单选字段（items / titleBuilder / lineSpacing） | 多选用 `WFormMultiDropdown` |
| `WFormButton` | form | 直接自定义字段按钮（选择、弹层触发） | 普通业务按钮用 `WButton`；底层 `*Core` 已内部化，不要直接使用 |
| `WFormFieldStyle` | form | 页面级字段默认高度 / 内边距 / 文字 / hint 样式 | 字段级差异用直接字段参数；单字段样式用 `WFormFieldStyleScope` 包裹 |
| `WFormValidatorSettings` | form | 校验行为：边框错误、短路 / 全量、回调 | — |
| `WFormBorder` | form | 低层边框 / 错误展示；普通页面由 `WForm` 统一提供 | 普通字段不要手写 `WFormBorder` |
| `WFormBorderConfig` | form | 不可变边框配置：默认 / 聚焦 / 错误 / 只读装饰与 hint/error 样式 | 普通字段不要手写 `WFormBorder`；配置通过 `WForm(borderConfig: ...)` 下发 |
| `WFormBorderDecoration` | form | 边框装饰值对象：border / color / borderRadius / boxShadow / gradient | 不要用 `Container(decoration:)` 代替 `WFormBorder` |
| `WFormIcons` | form | 表单图标集合（下拉 / 勾选 / 单选 / 密码 / 清空） | `WFormDefaults` 已删除；单字段 icon 参数优先于它 |
| `WFormFieldStyleScope` | form | 单个字段覆盖 `WForm.fieldStyle`（高度 / 内边距 / 文字 / hint） | 整页样式直接传 `WForm.fieldStyle`，不要逐字段包一层 |
| `WFormValidator` | form | 统一校验入口：短路 / 全量、边框错误、错误汇总 | 不要同时用 `formKey.validate()`，会形成两套错误通道 |
| `WFormValidatorItem` | form | 单个校验项：自定义规则或复用字段自身 validator | 字段自带 validator 已够用时不要重复声明规则 |
| `WFormTextFieldAction` / `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton` | form | 文本字段插槽 action：自定义按钮 / 密码可见切换 / 清空 | 不要自己用 `InheritedWidget` 读输入状态；用 `WFormTextFieldScope.of` |
<!-- catalog:5:end -->

## 6. 弹层

<!-- catalog:6:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WBottomSheet` | app_getx | 底部面板外壳 | — |
| `WFormPopup` | form | **锚定式**下拉弹层（贴在输入框下方） | ⚠️ 它不是居中对话框，别拿来做「确认弹窗」 |
<!-- catalog:6:end -->

## 7. 状态与反馈

<!-- catalog:7:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WAsyncView` / `WAsyncErrorView` / `WAsyncErrorBanner` | async | 普通页面异步四态视图、默认重试页与刷新错误条 | 滚动页面用 `WAsyncStateBuilder`；纯状态逻辑用 `WAsyncState` / `WAsyncController` |
| `WAsyncStateBuilder` | async | 滚动页面 / `SmartRefresher` / 自定义状态布局 | 普通页面优先用 `WAsyncView`；旧 `WAsyncBuilder` 已删除 |
| `WAsyncController` | async | 单区块异步状态、load / retry / 旧请求丢弃 | 分页用 `WAsyncPagedController`；纯执行用 `WAsync` |
| `WAsyncPagedController` | async | 分页列表：首屏、刷新、追加、hasMore（recipe: docs/recipes/paged-list.md） | 普通单请求用 `WAsyncController` |
| `WAsyncStateSliver` | async | CustomScrollView 的四态 sliver、failed+旧数据 | 非滚动页面用 `WAsyncView` |
| `WAsyncTheme` | async | App 根部统一默认 loading / empty / error（普通 + sliver） | 不要用它包装单个页面；单个 WAsyncView 的显式 builder 优先 |
| `WAsyncThemeViews` | async | 自建滚动壳复用 WAsyncTheme 的默认四态视图 | 普通页面直接用 WAsyncView，不要重复搭状态分支 |
| `WToast` | toast | 轻提示 | — |
| `WToastStyle` | toast | Toast 的时长 / 对齐 / 背景 / 动画等样式 | 不要为单条 toast 重复造主题；全局用 WToastTheme |
| `WGradientCircularProgressIndicator` | ui | 加载指示 | — |
| `WListView` / `WListViewSliver` | ui | 列表（独立滚动 / SmartRefresher sliver） | — |
| `WKeepAliveWrapper` | ui | 列表项保活 | 不要用它做滚动回调；只负责 keepAlive |
| `WNotificationListenerBuilder` | ui | 监听滚动通知 / 百分比 | 百分比只处理 depth 0 的 ScrollUpdateNotification |
<!-- catalog:7:end -->

## 8. 能力（非 UI）

<!-- catalog:8:start -->
| 能力 | 子包 | 说明 | **不要用在哪** |
| --- | --- | --- | --- |
| `WApp` | app_getx | GetX 启动器 | — |
| `WAppOptions` | app_getx | WApp 的标题 / 主题 / GetX 路由 / 语言 / 包装器配置 | 不要手写 runApp；入口用 WApp.options(...).start() |
| `WAppPlugin` | app | 插件分层初始化 | — |
| `WAsyncState` | async | 四态快照与 `when` | 不要手写 `ValueNotifier<WAsyncState>` |
| `WAsyncResult` | async | `WAsync.tryRun` 的成功 / 失败 / 取消结果 | 需要失败抛异常时用 `WAsync.run` |
| `WAsync` / `WAsyncOptions` / `WAsyncActivity` / `WCancelToken` | async | 无 UI 异步执行（tryRun/run）、取消与活动计数 | — |
| `WCountdown` | core | 倒计时 | — |
| `WStorage` | core | 本地类型读写 | 读取前必须 `init`；明文存储 |
| `WToken` | core | token 存取 | 明文存储；高敏感场景用 Keychain / Keystore |
| `WEncrypt` / `WHash` | core | 加密、摘要 | AES-CBC 不提供完整性 |
| `WLogger` / `WValidator` / `WRegExp` | core | 日志、校验、正则 | — |
| `WDebounce` / `WThrottle` | core | 防抖 / 节流（`WUx` 的同名方法已弃用） | 不要每次 build 新建实例；页面 dispose 时 cancel |
| `WPlatform` | core | 平台判断 | 不要用 Platform.isXxx 绕过统一判断 |
| `DioRegistry` | api | 按 baseUrl 创建并复用 Dio | 不要直接 `Dio()`；同一 baseUrl 只配置一次 |
| `WTokenInterceptor` | api | Token 注入 / 401 刷新 / 重试（recipe: docs/recipes/login-refresh.md） | 不要在拦截器里存 token |
| `WLogInterceptor` | api | 请求 / 响应 / 错误日志 | 不做业务错误处理；敏感头默认脱敏 |
| `WApiConfig` | api | 请求配置与日志注入 | — |
| `WLanguage` | app_getx | 语言切换 / `languageStream` | 不要直接改 `WAppConfig.currentLanguage` 后期待通知 |
| `WAppConfig` | app_getx | 语言列表与当前语言真源 | 非响应式；切换用 `WLanguage` |
| `WRouteObserver` | app_getx | 维护 `WRouteStack` 路由栈 | 不要重复添加；WApp 已自动追加 |
| `WQrView` | qr | 二维码 / 条形码扫描 | 不要直接用 `QRView`；单次扫码后用 `restartScan` |
| `WQrController` | qr | 相机控制与广播扫描流 | 不要用它重置 scanOnce |
| `WQrViewOverlayShape` | qr | 扫描框样式 | 尺寸必须大于 0 |
| `WMap` / `WMapZone` | map_google | Google Maps 地图与数据区域 | 不要直接用 `GoogleMap`；需要 API Key |
| `WMapController` | map_google | 业务侧选中 / 关闭 marker | 未挂载时无效果 |
| `WMapItemMapper` | map | 生成模型取地图字段 | 不要在 build 内重复创建 |
| `WRouteStack` | app_getx | 路由栈操作（`WRouteStack.defaultStack` / `app.routeStack`） | — |
<!-- catalog:8:end -->

## 9. 扩展

<!-- catalog:9:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WNumExtension` | ui | 数字格式化 / 间距 / 圆角 / BorderSide 糖 | 不要重复手写 toStringAsFixed / SizedBox / EdgeInsets |
| `WStringExtension` | ui | String 转数字 / 去空格 / hex 颜色 / 资源路径 | 图片组件转换用 `WStringExtension` 的路径方法 |
| `WBoxDecorationExtension` | ui | BoxDecoration 组合（颜色 / 边框 / 圆角 / 阴影） | 不要每次重写完整 BoxDecoration |
| `WWidgetExtension` | ui | Widget 间距 / 安全空间 / 装饰 / IntrinsicHeight | 需要 button 语义用 `WButton` |
| `WUiWidgetExtension` | ui | `toPressable`（任意 child 点击，无 button 语义） | 需要 button 语义用 `WButton` |
| `WHexColor` | ui | 十六进制颜色解析 / 输出 | 不要手写 Color(int.parse(...)) |
<!-- catalog:9:end -->

## 10. 待补（有重复用例，尚未进包）

| 组件 | 现状 | 计划去向 |
| --- | --- | --- |
| **居中弹窗壳**（311 宽 / r20 / 57 高 `#F8F8F5` 头部 / 按钮排布） | 各项目手写，样式已开始漂移 | `w_tools_ui` |
| **图标 + 文字一行**（`WidgetSpan` + 光学补偿） | 各项目手写 `Row`，对齐普遍偏 1.5~2.5px | `w_tools_ui` |
| **品牌 logo 方块**（48 底 / 40 图 / r10 / `#EAEAEA` 边） | 至少 3 处重复 | `w_tools_ui` |
| **虚线分隔**（`#CFCFCF` dash[2,2] 等） | 各项目自己画 | `w_tools_ui` |
| **空态**（80 圆 + 图标 + 文案） | 各项目各写一份 | `w_tools_ui` |
| **语义颜色 token**（`#3F3F3F`/`#545454`/`#EAEAEA`/`#409C35`…） | 全项目硬编码 | `w_tools_core` |

## 11. 版本

版本以各包 `pubspec.yaml` 与 pub.dev 为准，**不要在这里硬编码**（历史上这张表已经漂移过）。
聚合包 `w_tools` 只做 re-export，消费方不要依赖它（理由见
[ADR-0002](../adr/0002-consumers-depend-on-subpackages.md)）。
