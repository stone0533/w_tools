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
| `WAppBarStyle` | ui | WAppBar 的背景 / 渐变 / 前景色 / 标题样式 / 高度 | backgroundColor 与 gradient 只能选一个 |
| `WNavBar` / `WNavController` | ui | 底部 tab 栏；controller 需 vsync 并由页面 State dispose | 不要自己写 `BottomNavigationBar` |
| `WNavBarStyle` | ui | WNavBar 的外层装饰 / padding；新代码优先 | 选中态与切换动画由 `WNavController` 管，不要放进 style |
| `WTabBar` | ui | 顶部 tab；依赖 TabController / DefaultTabController | 需要下划线跟随的复杂交互时先看它够不够 |
| `WTabBarStyle` | ui | 指示器 / 分割线 / 对齐 / overlay / 标签样式；新代码优先 | WTabBar 不自带 controller，不要在这里塞状态 |
| `WStep` / `WStepFlow` | ui | 步骤条（注册流程等） | 背景/高度用外层 Container；多步骤注意横向空间 |
| `WStepStyle` | ui | 步骤条颜色 / 尺寸 / 间距 / 标签样式 | 不要靠改 WStep 内部布局实现视觉；优先用 itemBuilder |
| `WStepColors` | ui | WStepStyle.resolve 返回的 completed / current / upcoming 颜色 | 不要自己按 Brightness 推颜色；让 WStepStyle.resolve 解析主题 |
| `WApp` | app_getx | GetX 启动器 | — |
| `WAppOptions` | app_getx | WApp 的标题 / 路由 / 外观 / 语言 / 包装器配置 | 不要手写 runApp；入口用 WApp.options(...).start() |
| `WAppTheme` | app | 应用外观：亮/暗主题、主题模式、系统栏 | 不要用 WAsyncTheme；它是 Widget，本类型是配置 |
| `WAsyncResult` | async | `WAsync.tryRun` 的成功 / 失败 / 取消结果 | 需要失败抛异常时用 `WAsync.run` |
| `WAsync` | async | 无 UI 异步执行（tryRun / run / 组合器） | 页面四态用 `WAsyncController` + `WAsyncView`；不要用已删除的 `runValue` / `WAsyncLoading` |
| `WAsyncOptions` | async | WAsync 的执行选项：并发活动计数与失败兜底回调 | Controller 不接 WAsyncOptions，只接 onError；不要用 activity 合并多个独立区块 |
| `WAsyncActivity` | async | 同一批并发任务共享的加载计数：0→1 / 1→0 各回调一次 | 不是加载视图；不要拿它合并多个独立区块 |
| `WCancelToken` | async | 协作式取消：传给 WAsync / withToken loader | 取消后不可复用；新请求要新建 token |
| `WStepState` | ui | 步骤项状态（completed / current / upcoming） | 不要自己拼状态字符串；按 enum 分支 |
| `WStepItemBuilder` / `WStepSeparatorBuilder` / `WStepSemanticLabelBuilder` | ui | WStep 的三类 builder：步骤项 / 分割线 / 语义标签 | 不要在 builder 里返回 Expanded；外层已经包了 Expanded |
| `WFormScope` | form | 表单 InheritedWidget 管道（WForm 内部组合） | — |
| `WAsyncSuccess` | async | tryRun 成功结果 | — |
| `WAsyncFailure` | async | tryRun 失败结果（error / stackTrace / isProgrammingError） | — |
| `WAsyncCancelled` | async | tryRun 取消结果（reason） | — |
| `WCancellationException` | async | run 被取消时抛出的异常（reason） | — |
| `WLocaleConfig` | app | 语言支持列表、首次启动语言与回退语言（WAppOptions.localeConfig） | — |
<!-- catalog:1:end -->

## 2. 文本与图标

<!-- catalog:2:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WText` / `WTextVariant` / `WTextStyles` | ui | 语义文字样式、overrides、maxLines、textScaler | 不要再用已移除的 `WTextConfig`，改用 `WTextStyles` |
| `WImage` | ui | 网络图/资源图（缓存、占位；重试需显式设置 retryCount） | 不要裸用 `Image.network` |
| `WImageSource` | ui | WImage 的来源：network / asset / file / base64 / provider / parse | 不要用已删除的 WImage.network / asset / file / data |
| `WImageStyle` | ui | 图片视觉：尺寸 / fit / 圆角 / 边框 / 阴影 / aspectRatio / 语义 | 占位/错误 UI 用 `WImageSlots`，加载/重试用 `WImageLoadOptions`，不要混在 style 里 |
| `WImageLoadOptions` | ui | 图片加载行为：解码尺寸 / 重试 / gapless | 视觉样式用 `WImageStyle` |
| `WImageController` | ui | 手动重试与加载状态（retry / state） | 一个 controller 只能绑定一张 WImage |
| `WAppPlugin` | app | 插件分层初始化 | — |
| `WAppPluginRunner` | app | GetX-free 的插件注册表与 dependsOn 分层初始化 | 不要绕过 WApp.init 直接调用；WApp 内部会委托它 |
| `WAsyncState` | async | 四态快照与 `when` | 不要手写 `ValueNotifier<WAsyncState>` |
| `WImageTheme` | ui | App 级图片占位 / 错误 / 进度默认配置 | 不要按单图传参；单图默认值用 WImageSlots，主题只做 App 级兜底 |
| `WImageSlots` | ui | 单图 / App 级图片占位 / 错误 / 进度 / 重试 UI | 不要把重试次数、解码尺寸等行为配置塞进 WImageSlots |
| `WImageErrorKind` | ui | 图片错误分类（WImageError.kind） | 不要用字符串比较错误；按 kind 分支 |
| `WImageError` | ui | 图片加载错误（data / kind / cause / message） | 不要自己构造来 mock 失败；用 WImageSource 触发真实错误 |
| `WImageProgress` | ui | 图片加载进度（downloadedBytes / totalBytes / fraction / isComplete） | 不要把 downloadedBytes 当总大小；总大小未知时看 fraction == null |
| `WImageType` | ui | 图片来源类型（asset / network / file / base64 / provider） | 不要用它决定业务 UI；按 WImageSource 子类型或 error.kind 判断 |
| `WImageLoadStatus` | ui | 图片加载状态（idle / loading / completed / failed） | 不要当业务状态机；只表示图片加载阶段 |
| `WImageLoadSnapshot` | ui | 图片加载快照（status / progress / attempt / error / retryScheduled） | 不要缓存后当实时状态；监听 WImageController.state |
| `WImageStyleExtension` | ui | WImageStyle 链式糖：square / rounded | 不要用它做条件样式；复杂组合直接构造 WImageStyle |
| `WThemeDataExtension` | ui | ThemeData.withWTextStyles：同时写 TextTheme 与 WTextStyles | 不要只装 TextTheme 不装扩展；会丢 price / number / badge 语义 |
| `WNetworkImageSource` | ui | WImageSource 的网络实现（通常用 WImageSource.network） | 不要复用可变 headers 后再改；source 是值对象 |
| `WAssetImageSource` | ui | WImageSource 的资源实现（通常用 WImageSource.asset） | 不要在已带 WAssets 前缀的路径上再传 prefix: true；会重复前缀 |
| `WFileImageSource` | ui | WImageSource 的本地文件实现（通常用 WImageSource.file） | 不要在 Web 上用；Web 上 WImageSource.resolve 抛 UnsupportedError |
| `WBase64ImageSource` | ui | WImageSource 的 Base64 实现（通常用 WImageSource.base64） | 不要传超大 Base64 做主线程解码；优先网络 / 资源图 |
| `WProviderImageSource` | ui | WImageSource 的 ImageProvider 实现（通常用 WImageSource.provider） | 不要用它绕开 WImage 的错误与语义处理；只在已有 provider 时用 |
| `WImageErrorView` | ui | 内置图片错误视图（error / onRetry / retryLabel / compact） | 不要当页面级错误组件；只用于图片占位 |
| `WImageFrame` | ui | 把 WImageStyle 的圆角 / 边框 / 阴影应用到任意 child | 不要单独当卡片用；图片装饰走 WImageStyle |
| `WAsyncStatus` | async | 四态枚举：loading / ready / empty / failed | — |
<!-- catalog:2:end -->

> **图标 + 文字排成一行**（垂直居中）：目前没有组件，见文末「待补」——
> 不要用 `Row + Icon + Text`，中文字形在行盒里偏下，图标会看着偏高 1.5~2.5px。

## 3. 按钮与操作

<!-- catalog:3:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WButtonStyle` | ui | 按钮视觉：颜色 / 边框 / 圆角 / 内边距 / 尺寸 / 动效 / 语义 | 按钮宽度由父布局决定，`WButtonStyle` 不含 width |
| `WButton` | ui | 真正的按钮（label/icon + style/size/loading） | 任意 child 点击用 `WPressable` |
| `WPressable` | ui | 任意 child 的点击 + 基础效果（无 button 语义） | 需要 button 语义 / 键盘焦点 / 最小点击区域时用 `WButton` |
| `WButtonStyles` | ui | 按 ColorScheme 派生的四种语义样式（primary / secondary / text / danger） | 不要硬编码颜色；页面统一样式用项目 AppButtons 注册表 |
| `WButtonStyleSet` | ui | WButtonStyles.of 返回的四种语义样式集合 | 不要自己 new 这组样式；用 WButtonStyles.of(context) |
| `WActionRow` / `WSelectableRow` | ui | 横向滚动按钮行：`WActionRow` 无选中、`WSelectableRow` 单选高亮 | 旧的 `WRowButtons` 已在 5.0 删除；纯静态排列直接用 `Row` |
| `WBadge` | ui | 角标数字 | 不要用于状态点或长文案；状态点用原生 Container，多字提示用 WText |
| `WBadgeStyle` | ui | 角标视觉：背景 / 前景 / 文字 / padding / 圆角 / 边框 | 不要在这里放位置；位置用 WBadgePosition |
| `WBadgePosition` | ui | 角标位置：topEnd / center | 不要用它做外部布局；它只控制角标相对 child 的位置 |
| `WFormIcons` | form | 表单图标统一入口（下拉 / 勾选 / 单选 / 密码 / 清空）；WForm 会继承外层 WFormTheme 的图标 | `WFormDefaults` 已删除；`WForm` / `WFormTheme` 已不再接受单项 `xxxIcon` 参数，统一用 `icons:` |
| `WAsyncController` | async | 单区块异步状态、load / retry / 旧请求丢弃 | 分页用 `WAsyncPagedController`；纯执行用 `WAsync` |
| `WAsyncPagedController` | async | 分页列表：首屏、刷新、追加、hasMore（recipe: docs/recipes/paged-list.md） | 普通单请求用 `WAsyncController` |
| `WLanguage` | app | 实例级语言状态 / 切换 / 只读变化流 | 不要自己保存 currentLanguage；用 app.language |
| `WButtonSize` | ui | 按钮尺寸值对象（minWidth/minHeight/padding/fontSize/iconSize/gap） | 不要用它控制宽度；宽度由父布局决定 |
| `WButtonMotion` | ui | 按钮按压动效（opacity / scale / none） | 不要每个按钮自定义一套；默认动效已够，品牌统一放 AppButtons |
| `WButtonSemantics` | ui | 按钮无障碍语义（label / hint） | 不要用它替代 Semantics 组件；它只供 WButton 的朗读文案 |
| `WPressEffect` | ui | WPressable 按压效果（opacity / scale / none） | 不要用它做 loading；只做按压反馈 |
| `WButtonContentBuilder` | ui | WButton.contentBuilder 的类型：拿到最终样式自己排版 | 不要在 builder 里重新读 Theme 派生样式；直接用传入的 resolved style |
| `WButtonResolvedStyle` | ui | contentBuilder 拿到的最终样式（states / 背景 / 文字样式等） | 不要缓存后跨帧使用；它只对当前 WidgetState 有效 |
| `WFormThemeData` | form | 表单主题数据（icons / borderStyle + effective* 图标 getter）；`WFormThemeData.of(context)` 读取 | — |
| `WFormTheme` | form | 主题 InheritedWidget：App 级图标 / 边框统一放外层，WForm 会继承 | — |
| `WAsyncPageLoader` | async | 分页 loader 的类型：(page) => Future<List<T>> | — |
| `WAsyncTokenLoader` | async | 可感知取消的 loader 类型：(token) => Future<T> | — |
| `WAsyncTokenPageLoader` | async | 可感知取消的分页 loader 类型：(page, token) => Future<List<T>> | — |
<!-- catalog:3:end -->

## 4. 布局与容器

<!-- catalog:4:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WClipRRect` | ui | 裁剪 | 不要用它替代图片圆角；图片圆角用 WImageStyle.borderRadius |
| `WScreen` | ui | 屏幕 / 字体适配（w/h/sp）、状态栏 / 底部安全区 | 不要重复用 MediaQuery 手写全局适配 |
| `WAssets` | ui | 图片资源前缀唯一开关 | 不要硬编码 `assets/images/` |
| `WFormBorder` | form | 低层边框 / 错误展示；普通页面由 `WForm` 统一提供 | 普通字段不要手写 `WFormBorder` |
| `WFormBorderStyle` | form | 不可变边框配置：默认 / 聚焦 / 错误 / 只读装饰与 hint/error 样式 | 普通字段不要手写 `WFormBorder`；配置通过 `WForm(borderStyle: ...)` 下发 |
| `WFormBorderDecoration` | form | 边框装饰值对象：border / color / borderRadius / boxShadow / gradient | 不要用 `Container(decoration:)` 代替 `WFormBorder` |
| `WAsyncView` | async | 普通页面异步四态视图、默认重试页与刷新错误条 | 滚动页面用 `WAsyncStateBuilder`；纯状态逻辑用 `WAsyncState` / `WAsyncController` |
| `WAsyncStateBuilder` | async | 滚动页面 / `SmartRefresher` / 自定义状态布局 | 普通页面优先用 `WAsyncView`；旧 `WAsyncBuilder` 已删除 |
| `WAsyncStateSliver` | async | CustomScrollView 的四态 sliver、failed+旧数据 | 非滚动页面用 `WAsyncView` |
| `WRouteStack` | app_getx | 路由栈操作（`app.routeStack`） | — |
| `WScreenData` | ui | WScreen.of(context) 返回的尺寸 / 安全区快照 | 不要在 build 外缓存；它跟随最近的 MediaQuery |
| `WFormReadOnlyScope` | form | 只读作用域：由 WForm / 字段自动注入，穿透任意包装 | — |
| `WFormBorderLayout` / `WFormBorderLayoutData` | form | 边框与消息的布局策略：一个函数 typedef（默认 columnBorderLayout） | — |
| `WFormFieldShell` | form | 字段外框装配（内置字段自动使用；自定义字段可参考 form_module.md §4.3） | — |
| `WFormBorderDecorationExtension` | form | 边框装饰值对象的链式扩展（withUniformBorder / withColor 等） | — |
| `WAsyncErrorView` / `WAsyncErrorBanner` | async | 默认整块错误视图 / 保留旧数据时的错误条 | — |
| `WAsyncRetryErrorHandler` | async | onRetryError 回调的类型 | — |
<!-- catalog:4:end -->

## 5. 表单

<!-- catalog:5:start -->
| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WForm` | form | 页面表单容器：主题 / Scope / 只读 / 默认字段样式 / 默认校验 | 普通页面不要手写 `WFormTheme + WFormScope + WFormReadOnlyScope` 三层嵌套；App 级图标 / 边框才用外层 `WFormTheme` |
| `WFormController` | form | 表单数据 / 字段值 / 校验入口 | 两个 WForm 不能同时挂载同一个 controller（会显示重复挂载提示） |
| `WFormTextField` | form | 直接文本 / 密码字段（label / message / validator） | 不要默认写 `WFormTextFieldConfig().build(...)` |
| `WFormDropdown` | form | 直接下拉字段（items / 初始值 / icon / contentPadding） | 多选用 `WFormMultiDropdown`；自定义弹层用 `WFormPopup` |
| `WFormMultiDropdown` | form | 直接多选字段（items / disabledKeys / 选项样式） | 单选用 `WFormDropdown` |
| `WFormDatePicker` | form | 直接日期字段（displayFormat / firstDate / lastDate） | 时间选择不在本组件范围；自定义弹层用 `WFormPopup` |
| `WFormCheckbox` | form | 直接复选字段（title 必填，默认 bordered: false） | 多选用 `WFormMultiDropdown` |
| `WFormRadioGroup` | form | 直接单选字段（items / titleBuilder / lineSpacing） | 多选用 `WFormMultiDropdown` |
| `WFormButton` | form | 直接自定义字段按钮（选择、弹层触发） | 普通业务按钮用 `WButton`；底层 `*Core` 已内部化，不要直接使用 |
| `WFormFieldButton` | form | 泛型字段值选择器：enum / int 等非 String 值 | String 值优先用 `WFormButton`；普通业务按钮用 `WButton` |
| `WFormFieldStyle` | form | 页面级字段默认高度 / 内边距 / 文字 / hint 样式 | 字段级差异用直接字段参数；单字段样式用 `WFormFieldStyleScope` 包裹 |
| `WFormFieldStyleScope` | form | 单个字段覆盖 `WForm.fieldStyle`（高度 / 内边距 / 文字 / hint） | 整页样式直接传 `WForm.fieldStyle`，不要逐字段包一层 |
| `WFormTextFieldAction` / `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton` | form | 文本字段插槽 action：自定义按钮 / 密码可见切换 / 清空 | 不要自己用 `InheritedWidget` 读输入状态；用 `WFormTextFieldScope.of` |
| `WAsyncTheme` | async | App 根部统一默认 loading / empty / error（普通 + sliver） | 不要用它包装单个页面；单个 WAsyncView 的显式 builder 优先 |
| `WAsyncThemeViews` | async | 自建滚动壳复用 WAsyncTheme 的默认四态视图 | 普通页面直接用 WAsyncView，不要重复搭状态分支 |
| `WRouteObserver` | app_getx | 维护 `WRouteStack` 路由栈 | 不要重复添加；WApp 已自动追加 |
| `WFormTextFieldData` | form | 文本字段插槽可读的数据（isPasswordVisible / readOnly 等） | — |
| `WFormTextFieldScope` | form | 文本字段插槽的 InheritedWidget 入口（actions / suffix 用） | — |
| `WAsyncStrings` | async | 全局默认文案：empty / errorTitle / retry | — |
| `WAsyncErrorWidgetBuilder` | async | error / errorBanner builder 的类型 | — |
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
| `WFormValidatorSettings` | form | 校验行为：边框错误、短路 / 全量、回调 | — |
| `WFormValidator` | form | 统一校验入口：短路 / 全量、边框错误、错误汇总 | 不要同时用 `formKey.validate()`，会形成两套错误通道 |
| `WFormValidatorItem` | form | 单个校验项：自定义规则或复用字段自身 validator | 字段自带 validator 已够用时不要重复声明规则 |
| `WToast` | toast | 轻提示 | — |
| `WToastStyle` | toast | Toast 的时长 / 对齐 / 背景 / 动画等样式 | 不要为单条 toast 重复造主题；全局用 WToastTheme |
| `WGradientCircularProgressIndicator` | ui | 加载指示 | 不要用于不确定进度；需要无障碍 value 语义时传 value |
| `WListView` / `WListViewSliver` | ui | 列表（独立滚动 / SmartRefresher sliver） | 不要把 WListViewSliver 直接放进非 sliver 子树 |
| `WKeepAliveWrapper` | ui | 列表项保活 | 不要用它做滚动回调；只负责 keepAlive |
| `WNotificationListener` | ui | 声明式监听滚动通知 / 百分比；新代码优先 | 百分比只处理 depth 0 的 ScrollUpdateNotification |
| `WFormCustomValidator` | form | 把自定义校验函数包成 FormFieldValidator | — |
<!-- catalog:7:end -->

## 8. 能力（非 UI）

<!-- catalog:8:start -->
| 能力 | 子包 | 说明 | **不要用在哪** |
| --- | --- | --- | --- |
| `WCountdown` | core | 倒计时 | — |
| `WStorage` | core | 本地类型读写 | 读取前必须 `init`；明文存储 |
| `WToken` | core | token 存取 | 明文存储；高敏感场景用 Keychain / Keystore |
| `WEncrypt` / `WHash` | core | 加密、摘要 | AES-CBC 不提供完整性 |
| `WLogger` / `WValidator` / `WRegExp` | core | 日志、校验、正则 | — |
| `WDebounce` / `WThrottle` | core | 防抖 / 节流（`WUx` 的同名方法已弃用） | 不要每次 build 新建实例；页面 dispose 时 cancel |
| `WPlatform` | core | 平台判断 | 不要用 Platform.isXxx 绕过统一判断 |
| `DioRegistry` | api | 按 baseUrl 创建并复用 Dio | 不要直接 `Dio()`；同一 baseUrl 只配置一次 |
| `WTokenInterceptor` | api | Token 注入 / 401 刷新 / 重试（可运行示例：packages/api/example） | 不要在拦截器里存 token |
| `WLogInterceptor` | api | 请求 / 响应 / 错误日志 | 不做业务错误处理；敏感头默认脱敏 |
| `WLogPart` | api | WLogInterceptor 的日志片段选择 | 不要单独使用；作为 `parts` 的枚举值 |
| `WApiConfig` | api | 请求配置与日志注入 | — |
| `WQrView` | qr | 二维码 / 条形码扫描 | 不要直接用 `QRView`；重扫不要 Key 状态，用 `WQrController.restart` |
| `WQrController` | qr | 相机控制、广播扫描流与重扫 | 不要用它重置 UI 状态：单次锁定与成功色由 `WQrView` 管理 |
| `WQrOverlayStyle` | qr | 扫描框颜色 / 是否显示 / 外边距与尺寸 | 不要为了改边框颜色去动 `WQrView` 的其它参数 |
| `WQrScanResult` | qr | onScanned 的扫码结果（code / format / rawBytes / timestamp） | 不要把它当原始 Barcode：需要原始对象请监听 `WQrController.scannedDataStream` |
| `WMap` / `WMapZone` | map_google | Google Maps 地图与数据区域 | 不要直接用 `GoogleMap`；需要 API Key |
| `WMapController` | map_google | 业务侧选中 / 关闭 marker | 未挂载时无效果 |
| `WMapItemMapper` | map | 生成模型取地图字段 | 不要在 build 内重复创建 |
| `WFormInputFormatters` | form | 常用输入格式化器工厂（电话号码等） | — |
| `WCardNumberInputFormatter` | form | 每 4 位插入空格的卡号格式化器 | — |
| `WDividerInputFormatter` | form | 通用分隔符输入格式化器（first / rear / pattern） | — |
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
| `WColorExtension` | ui | 十六进制颜色解析 / 输出 | 不要手写 Color(int.parse(...)) |
| `WGradients` | ui | 预设渐变（vertical / horizontal / diagonal / radial） | 不要写死品牌色；它只提供方向，颜色由调用方传 |
| `WShadows` | ui | 预设阴影（none / card / elevated / floating） | 不要用于深色模式文字阴影；它只是中性预设 |
| `WTextStyleExtension` | ui | TextStyle 快捷修改（bold / withColor / withSize） | 不要用它替代 WTextStyles 做全局字体；只做一次性覆盖 |
| `WGlobalKeyExtension` | ui | GlobalKey 位置 / 边界（offset / rect） | 不要用它替代 controller / 状态传递；只做读取位置 |
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
