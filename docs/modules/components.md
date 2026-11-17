# 组件目录（先查这里，没有再动手）

> CLI 内置同一份目录：`dart run w_tools_cli:w_tools list <关键词>` / `:explain <组件名>`。

> **§1~§9 的表格由 `catalog/components.yaml` 生成**（`dart run tool/gen_catalog.dart`），手改会被覆盖；要改组件说明请改 YAML。
>
> 用法：**按用途找**。找到就用，找不到再看文末「待补」清单 —— 待补的东西应该先进消费方的
> `lib/app/design_system/`，出现第二个用例后再上移进包（见 [`docs/conventions.md`](../conventions.md)）。

## 1. 页面骨架与导航

<!-- catalog:1:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WScaffold` | ui | core | 页面壳：默认 WAppBar、body、抽屉 / 底部面板 / 底部导航 / FAB、安全区 | 任意顶部叠放用页面层 Container/Stack |
| `WAppBar` | ui | core | 标准顶部导航栏（leading/title/actions/bottom、leadingWidth/actionsPadding/shadow） | 任意叠放/覆盖布局在页面层用 Container/Stack |
| `WAppBarStyle` | ui | core | WAppBar 的背景 / 渐变 / 前景色 / 标题样式 / 高度 / leadingWidth / actionsPadding / 阴影 | backgroundColor 与 gradient 只能选一个 |
| `WNavBar` / `WNavController` | ui | core | 底部 tab 栏；controller 只维护 currentIndex，由页面 State dispose | 不要自己写 `BottomNavigationBar` |
| `WNavDestination` | ui | core | WNavBar 默认项的图标 / 选中图标 / 文案 | 需要完全自定义项时用 `WNavBar.itemBuilder` |
| `WStep` | ui | core | 步骤条（注册流程等） | 背景/高度用外层 Container；多步骤注意横向空间 |
| `WStepStyle` | ui | core | 步骤条颜色 / 尺寸 / 间距 / 标签样式 | 不要靠改 WStep 内部布局实现视觉；优先用 itemBuilder |
| `WStepColors` | ui | core | WStepStyle.resolve 返回的 completed / current / upcoming 颜色 | 不要自己按 Brightness 推颜色；让 WStepStyle.resolve 解析主题 |
| `WApp` | app_getx | core | GetX 启动器 | 不要用于非 GetX 项目；也不要重复 start / run，语言与路由栈是实例状态 |
| `WAppOptions` | app_getx | core | WApp 的标题 / 路由 / 外观 / 语言 / 包装器配置 | 不要手写 runApp；入口用 WApp.options(...).start() |
| `WAppTheme` | app | core | 应用外观：亮/暗主题、主题模式、系统栏 | 不要用 WAsyncTheme；它是 Widget，本类型是配置 |
| `WAsyncResult` | async | core | `WAsync.tryRun` 的成功 / 失败 / 取消结果 | 需要失败抛异常时用 `WAsync.run` |
| `WAsyncHooks` | async | core | WAsync 执行入口的默认生命周期回调：onStart / onError / onFinally | 不要在这里放 loading / toast 实现；项目在 composition root 配置一次 |
| `WAsync` | async | core | 无 UI 异步执行（tryRun / run / retry / timeout / settle） | 页面四态用 `WAsyncController` + `WAsyncView`；并发组合用 Future.wait / package:async |
| `WCancelToken` | async | core | 协作式取消：传给 WAsync 或 Controller 的 loader | 取消后不可复用；新请求要新建 token |
| `WStepState` | ui | core | 步骤项状态（completed / current / upcoming） | 不要自己拼状态字符串；按 enum 分支 |
| `WStepItemBuilder` / `WStepSeparatorBuilder` / `WStepSemanticLabelBuilder` | ui | core | WStep 的三类 builder：步骤项 / 分割线 / 语义标签 | 不要在 builder 里返回 Expanded；外层已经包了 Expanded |
| `WAsyncSuccess` | async | core | tryRun 成功结果 | 不要直接构造；它是 tryRun 的结果，不代表业务成功 |
| `WAsyncFailure` | async | core | tryRun 失败结果（error / stackTrace / isProgrammingError） | 不要吞掉 stackTrace；不要把编程错误当业务失败重试 |
| `WAsyncCancelled` | async | core | tryRun 取消结果（reason） | 不要把取消当失败展示；已取消请求不要自动重试 |
| `WCancellationException` | async | core | run 被取消时抛出的异常（reason） | 不要用它捕获所有异常；捕获后要保留 reason |
| `WLocaleConfig` | app | core | 语言支持列表、启动语言与回退语言（WAppOptions.localeConfig） | 不要放未在 supportedLanguages 里的语言；不要在运行时改 |
<!-- catalog:1:end -->

## 2. 文本与图标

<!-- catalog:2:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WText` / `WTextVariant` / `WTextStyles` | ui | core | 语义文字样式、overrides、maxLines、textScaler | 不要再用已移除的 `WTextConfig`，改用 `WTextStyles` |
| `WIconText` | ui | core | 图标 + 文字一行（垂直居中 / 光学补偿），替代 Row + Icon + Text | 纯图标 / 需要按钮语义用 `WButton(icon: ...)`；复杂多行内容用 `WButton(content: ...)` |
| `WImage` | ui | core | 网络图/资源图（缓存、占位；自动重试用 retryCount） | 不要裸用 `Image.network` |
| `WImageSource` | ui | core | WImage 的来源：network / asset / file / base64 / provider | 不要用已删除的 WImage.network / asset / file / data，也不要用 WImageSource.parse |
| `WImageStyle` | ui | core | 图片视觉：尺寸 / fit / 圆角 / 边框 / 阴影 / aspectRatio / 语义 | 占位/错误 UI 用 `WImageSlots`，加载/重试用 `WImageLoadOptions`，不要混在 style 里 |
| `WImageLoadOptions` | ui | core | 图片加载行为：解码尺寸 / 重试 / gapless | 视觉样式用 `WImageStyle` |
| `WAppPlugin` | app | core | 插件分层初始化 | 不要用插件包裹应用；需要 Theme / MediaQuery 的中间件放 WAppOptions.builder |
| `WAppPluginRunner` | app | core | GetX-free 的插件注册表与 dependsOn 分层初始化 | 不要绕过 WApp.init 直接调用；WApp 内部会委托它 |
| `WAsyncState` | async | core | 四态快照与 `when` | 不要手写 `ValueNotifier<WAsyncState>` |
| `WImageTheme` | ui | core | App 级图片占位 / 错误 / 进度默认配置 | 不要按单图传参；单图默认值用 WImageSlots，主题只做 App 级兜底 |
| `WImageSlots` | ui | core | 单图 / App 级图片占位 / 错误 UI（两槽） | 不要把重试次数、解码尺寸等行为配置塞进 WImageSlots |
| `WImageErrorKind` | ui | core | 图片错误分类（WImageError.kind） | 不要用字符串比较错误；按 kind 分支 |
| `WImageError` | ui | core | 图片加载错误（data / kind / cause / message / localizedMessage） | 不要自己构造来 mock 失败；用 WImageSource 触发真实错误 |
| `WImageProgress` | ui | core | 图片加载进度（downloadedBytes / totalBytes / fraction / isComplete） | 不要把 downloadedBytes 当总大小；总大小未知时看 fraction == null |
| `WImageType` | ui | core | 图片来源类型（asset / network / file / base64 / provider） | 不要用它决定业务 UI；按 WImageSource 子类型或 error.kind 判断 |
| `WImageLoadStatus` | ui | core | 图片加载状态（idle / loading / completed / failed） | 不要当业务状态机；只表示图片加载阶段 |
| `WImageStyleExtension` | ui | core | WImageStyle 链式糖：square / rounded | 不要用它做条件样式；复杂组合直接构造 WImageStyle |
| `WThemeDataExtension` | ui | core | ThemeData.withWTextStyles：同时写 TextTheme 与 WTextStyles | 不要只装 TextTheme 不装扩展；会丢 price / number / badge 语义 |
| `WNetworkImageSource` | ui | core | WImageSource 的网络实现（通常用 WImageSource.network） | 不要复用可变 headers 后再改；source 是值对象 |
| `WAssetImageSource` | ui | core | WImageSource 的资源实现（通常用 WImageSource.asset） | 不要传只有文件名的路径；asset 需要完整资源路径 |
| `WFileImageSource` | ui | core | WImageSource 的本地文件实现（通常用 WImageSource.file） | 不要在 Web 上用；Web 上 WImageSource.resolve 抛 UnsupportedError |
| `WBase64ImageSource` | ui | core | WImageSource 的 Base64 实现（通常用 WImageSource.base64） | 不要传超大 Base64 做主线程解码；优先网络 / 资源图 |
| `WProviderImageSource` | ui | core | WImageSource 的 ImageProvider 实现（通常用 WImageSource.provider） | 不要用它绕开 WImage 的错误与语义处理；只在已有 provider 时用 |
| `WImageErrorView` | ui | core | 内置图片错误视图（error / onRetry / retryLabel / showAction） | 不要当页面级错误组件；只用于图片占位 |
| `WAsyncStatus` | async | core | 四态枚举：loading / ready / empty / failed | 不要把它当业务状态机；新增值会破坏 exhaustive switch |
<!-- catalog:2:end -->

> **图标 + 文字排成一行**（垂直居中）：目前没有组件，见文末「待补」——
> 不要用 `Row + Icon + Text`，中文字形在行盒里偏下，图标会看着偏高 1.5~2.5px。

## 3. 按钮与操作

<!-- catalog:3:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WButton` | ui | core | Material 按钮（variant + ButtonStyle），带 loading / 语义 / 尺寸 | 任意 child 点击用 `WPressable`；表单值选择用 `WFormButton` |
| `WButtonTheme` | ui | core | 全站按钮四态 ButtonStyle（filled / outlined / text / danger），ThemeExtension | 单个按钮覆盖用 `WButton(style: ButtonStyle(...))`，不要改全局主题 |
| `WButtonVariant` | ui | core | 按钮语义变体：filled / outlined / text / danger | 不要用它控制尺寸 / 圆角；那些走 WButtonTheme 或 ButtonStyle |
| `WPressable` | ui | core | 任意 child 的点击 + 基础效果（无 button 语义） | 需要 button 语义 / 键盘焦点 / 最小点击区域时用 `WButton` |
| `WActionRow` / `WSelectableRow` | ui | core | 横向滚动按钮行：`WActionRow` 无选中、`WSelectableRow` 单选高亮 | 旧的 `WRowButtons` 已在 5.0 删除；纯静态排列直接用 `Row` |
| `WBadge` | ui | core | 角标数字 / 圆点 | 不要用于长文案；多字提示用 WText |
| `WBadgeStyle` | ui | core | 角标视觉：背景 / 前景 / 文字 / padding / 圆角 / 边框 | 不要在这里放位置；位置用 WBadgePosition |
| `WBadgePosition` | ui | core | 角标位置：topEnd / center | 不要用它做外部布局；它只控制角标相对 child 的位置 |
| `WFormIcons` | form | core | 表单图标统一入口（下拉 / 勾选 / 单选 / 密码 / 清空）；WForm 会继承外层 WFormTheme 的图标 | `WFormDefaults` 已删除；`WForm` / `WFormTheme` 已不再接受单项 `xxxIcon` 参数，统一用 `icons:` |
| `WAsyncController` | async | core | 单区块异步状态、load / replaceData / 旧请求丢弃 | 分页用 `WAsyncPagedController`；纯执行用 `WAsync`；多个独立区块不要共用一个 controller，每块一个 controller + WAsyncView |
| `WAsyncPagedController` | async | core | 分页列表：首屏、刷新、追加、hasMore、本地替换（recipe: docs/recipes/paged-list.md） | 普通单请求用 `WAsyncController` |
| `WAsyncPagedSnapshot` | async | core | 分页的唯一观察快照：state / footerStatus / loadMoreError / hasMore / isLoadingMore | 不要自己拼多个 ValueListenable；footer 读这个快照 |
| `WAsyncPagedFooterStatus` | async | core | 分页 footer 的派生状态：hidden / loading / failed / noMore / loadMore | 不要自己用 data / loadMoreError / hasMore 拼 footer 状态 |
| `WLanguage` | app | core | 实例级语言状态 / 切换 / 只读变化流 | 不要自己保存 currentLanguage；页面用 WLanguageScope.of(context) |
| `WButtonSize` | ui | core | 按钮尺寸令牌（minWidth/minHeight/padding/fontSize/iconSize/gap），映射到 ButtonStyle | 不要用它控制宽度；宽度由父布局决定；颜色 / 边框走 WButtonTheme |
| `WPressEffect` | ui | core | WPressable 按压效果（opacity / scale / none） | 不要用它做 loading；只做按压反馈 |
| `WFormThemeData` | form | core | 表单主题数据（icons / borderStyle + effective* 图标 getter）；`WFormThemeData.of(context)` 读取 | 不要直接构造或改字段；通过 WFormThemeData.of / WFormTheme 读取 |
| `WFormTheme` | form | core | 主题 InheritedWidget：App 级图标 / 边框统一放外层，WForm 会继承 | 不要在普通页面单独包一层；页面级用 WForm(icons:/borderStyle:) |
| `WAsyncPageLoader` | async | core | 分页 loader 的类型：(page, token) => Future<WAsyncPage<T>> | 不要在 loader 里做 UI；不要忽略 token |
| `WAsyncPage` | async | core | 分页 loader 返回 items + 显式 hasMore（第一页不足一页 / total） | 不要把它当完整分页状态；观察 WAsyncPagedSnapshot |
| `WAsyncTokenLoader` | async | core | 控制器 loader 的类型：(token) => Future<T> | 不要在 loader 里忽略 token；不要返回已取消请求的旧结果 |
<!-- catalog:3:end -->

## 4. 布局与容器

<!-- catalog:4:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WScreen` | ui | core | 屏幕 / 字体适配（w/h/sp）、状态栏 / 底部安全区 | 不要重复用 MediaQuery 手写全局适配 |
| `WFormBorderStyle` | form | core | 不可变边框配置：默认 / 聚焦 / 错误 / 只读装饰与 helper/error 文案样式 | 配置通过 `WForm(borderStyle: ...)` 下发；`WFormBorder` 8.0 起移除公开入口 |
| `WAsyncView` | async | core | 普通页面四态视图、默认错误页 / 刷新错误条；onRetry 控制重试按钮 | 滚动页面把滚动组件放进 readyBuilder；纯状态逻辑用 `WAsyncState` / `WAsyncController`；业务页面优先用 WAsyncSection；不要省略 onRetry 还期待默认重试按钮 |
| `WAsyncSection` | async_ui | app | 业务页面单区块四态的规范入口；支持 per-block builder 与自定义 onRetry | 分页用 WAsyncPagedList；纯执行用 WAsync；不要在本组件里塞全局 loading |
| `WAsyncPagedList` | async_ui | app | 标准分页列表的规范入口；内部处理刷新、上拉和 generation；header/footer 可覆盖 | 自定义 ready sliver 用 `WAsyncPagedSliver`；不要在 WAsyncPagedList 外再传 footerStatus / footerChanges |
| `WAsyncPagedSliver` | async_ui | app | 自定义 CustomScrollView 里的分页内容；.custom 支持 readySliverBuilder | 标准页面优先用 `WAsyncPagedList`；不要用它替代普通 WAsyncSection 单区块 |
| `WAsyncStateSliver` | async | core | CustomScrollView 的四态 sliver、failed+旧数据（错误条在列表上方） | 非滚动页面用 `WAsyncSection`；标准分页用 `WAsyncPagedList`；自定义滚动用 `WAsyncPagedSliver`；不要用原语重写分页/footer |
| `WRouteStack` | app_getx | core | 路由栈操作（`app.routeStack`） | 不要跨 WApp 操作路由栈；每个 WApp 持有自己的栈 |
| `WScreenData` | ui | core | WScreen.of(context) 返回的尺寸 / 安全区快照 | 不要在 build 外缓存；它跟随最近的 MediaQuery |
| `WScreenScope` | ui | core | 子树内的屏幕 / 字体缩放注入，替代全局 delegate | 不要和全局 delegate 混用；scope 优先 |
| `WFormReadOnly` | form | core | 读取当前子树是否只读（WForm / 字段自动注入） | 不要手写只读作用域；局部只读用 WForm(readOnly: true) 或字段 readOnly |
| `WFormFieldShell` | form | core | 字段外框装配（内置字段自动使用；自定义字段可参考 form_module.md §4.3） | 普通字段不要手写外框；自定义字段不要用它绕开 FormField |
| `WAsyncErrorView` / `WAsyncErrorBanner` | async | core | 默认整块错误视图 / 保留旧数据时的错误条 | 不要传异常原文；业务错误弹窗用 Toast / 表单错误，不用它 |
<!-- catalog:4:end -->

## 5. 表单

<!-- catalog:5:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WForm` | form | core | 页面表单容器：主题 / Scope / 只读 / 默认字段样式 / 默认校验 | 普通页面不要手写主题 / scope 嵌套（`WFormScope` / `WFormReadOnlyScope` 8.0 起移除公开入口）；App 级图标 / 边框才用外层 `WFormTheme` |
| `WFormController` | form | core | 表单数据 / 字段值 / 校验入口 | 两个 WForm 不能同时挂载同一个 controller（会显示重复挂载提示） |
| `WFormTextField` | form | core | 直接文本 / 密码字段（hintText / message / validator / textAlign / maxLength） | 不要默认写 `WFormTextFieldConfig().build(...)` |
| `WFormDropdown` | form | core | 直接下拉字段（items / 初始值 / icon / iconSize / style / contentPadding） | 多选用 `WFormMultiDropdown`；自定义弹层用 Flutter `MenuAnchor` / `showMenu` |
| `WFormMultiDropdown` | form | core | 直接多选字段（items / disabledKeys / 选项样式；T 由 items 推断） | 单选用 `WFormDropdown` |
| `WFormDatePicker` | form | core | 直接日期字段（initialValue / displayFormat / firstDate / lastDate） | 时间选择不在本组件范围；自定义弹层用 Flutter `MenuAnchor` / `showMenu` |
| `WFormCheckbox` | form | core | 直接复选字段（title 必填，默认 bordered: true） | 多选用 `WFormMultiDropdown` |
| `WFormRadioGroup` | form | core | 直接单选字段（items / titleBuilder / lineSpacing，默认 bordered: true） | 多选用 `WFormMultiDropdown` |
| `WFormButton` | form | core | 直接自定义字段按钮（选择、弹层触发） | 普通业务按钮用 `WButton`；底层 `*Core` 已内部化，不要直接使用 |
| `WFormFieldButton` | form | core | 泛型字段值选择器：enum / int 等非 String 值 | String 值优先用 `WFormButton`；普通业务按钮用 `WButton` |
| `WFormFieldStyle` | form | core | 页面级单行字段默认高度 / 内边距 / 文字 / 占位符样式 | 字段级差异用直接字段参数；单字段样式用 `WFormFieldStyleScope` 包裹 |
| `WFormFieldStyleScope` | form | core | 单个字段覆盖 `WForm.fieldStyle`（高度 / 内边距 / 文字 / hint） | 整页样式直接传 `WForm.fieldStyle`，不要逐字段包一层 |
| `WFormTextFieldAction` / `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton` | form | core | 文本字段插槽 action：自定义按钮 / 密码可见切换 / 清空 | 不要自己用 `InheritedWidget` 读输入状态；用 `WFormTextFieldData.of` |
| `WAsyncTheme` | async | core | App 根部统一默认 loading / empty / error（普通 + sliver 共用） | 不要用它包装单个页面；单个 WAsyncView 的显式 builder 优先 |
| `WRouteObserver` | app_getx | core | 维护 `WRouteStack` 路由栈 | 不要重复添加；WApp 已自动追加 |
| `WFormTextFieldData` | form | core | 文本字段插槽可读的数据（isPasswordVisible / readOnly 等） | 不要在 builder 外构造或缓存；插槽内只读 |
| `WAsyncStrings` | async | core | 全局默认文案：empty / errorTitle / retry / loading | 不要用它写业务文案；项目应注入本地化，默认文案是英文 |
| `WAsyncErrorWidgetBuilder` | async | core | error / errorBanner builder 的类型 | 不要直接显示 error 原文；不要返回 sliver |
<!-- catalog:5:end -->

## 6. 弹层

<!-- catalog:6:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WBottomSheet` | app_getx | core | 底部面板外壳 | 不要用于全屏页面或需要路由返回栈的场景；只做底部面板外壳 |
<!-- catalog:6:end -->

## 7. 状态与反馈

<!-- catalog:7:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WFormValidatorSettings` | form | core | 校验行为：边框错误、短路 / 全量、回调 | 不要用它承载单字段规则；单字段用字段 validators，settings 只放校验行为 |
| `WFormValidator` | form | core | 统一校验入口：短路 / 全量、边框错误、错误汇总 | 不要同时用 `formKey.validate()`，会形成两套错误通道 |
| `WFormValidatorItem` | form | core | 单个校验项：自定义规则或复用字段自身 validator | 字段自带 validator 已够用时不要重复声明规则 |
| `WToast` | toast | core | 轻提示；带遮罩的提示用 `WToast.showModal`（点遮罩关、不穿透、超时兜底） | 提示不要直接用 `WToast.showCustomDialog`（BotToast 直通口：默认关不掉且点击穿透）；确认框用 Flutter `showDialog` |
| `WToastStyle` | toast | core | Toast 的时长 / 对齐 / 背景 / 动画等样式 | 不要为单条 toast 重复造主题；全局用 WToastTheme |
| `WGradientCircularProgressIndicator` | ui | core | 确定 / 不确定进度的渐变圆环 | 不确定进度用 `indeterminate: true`，不要传假 value 假装旋转 |
| `WListView` / `WListViewSliver` | ui | core | 列表（独立滚动 / SmartRefresher sliver） | 不要把 WListViewSliver 直接放进非 sliver 子树 |
| `WKeepAliveWrapper` | ui | core | 列表项保活 | 不要用它做滚动回调；只负责 keepAlive |
| `WNotificationListener` | ui | core | 声明式监听滚动通知 / 百分比；新代码优先 | 百分比只处理 depth 0 的 ScrollUpdateNotification |
<!-- catalog:7:end -->

## 8. 能力（非 UI）

<!-- catalog:8:start -->
| 能力 | 子包 | 说明 | **不要用在哪** |
| --- | --- | --- | --- |
| `WCountdown` | core | 倒计时 | 不要用于服务端计时或精确闹钟；它只是 UI 倒计时 |
| `WStorage` | core | 本地类型读写 | 读取前必须 `init`；明文存储 |
| `WToken` | core | token 存取 | 明文存储；高敏感场景用 Keychain / Keystore |
| `WEncrypt` / `WHash` | core | 加密、摘要 | AES-CBC 不提供完整性 |
| `WLogger` / `WValidator` / `WRegExp` | core | 日志、校验、正则 | 不要用 WLogger 记录敏感信息；不要用 WValidator 替代服务端校验 |
| `WDebounce` / `WThrottle` | core | 防抖 / 节流（`WUx` 的同名方法已弃用） | 不要每次 build 新建实例；页面 dispose 时 cancel |
| `WPlatform` | core | 平台判断 | 不要用 Platform.isXxx 绕过统一判断 |
| `DioRegistry` | api | 按 baseUrl 创建并复用 Dio（可 replace 重建） | 不要直接 `Dio()`；同一 baseUrl 只配置一次 |
| `WTokenInterceptor` | api | Token 注入 / 401 刷新 / 重试（可运行示例：packages/api/example） | 不要在拦截器里存 token |
| `WLogInterceptor` | api | 请求 / 响应 / 错误日志 | 不做业务错误处理；敏感头 / 敏感 body 默认脱敏，但仍不要打进生产日志 |
| `WLogPart` | api | WLogInterceptor 的日志片段选择 | 不要单独使用；作为 `parts` 的枚举值 |
| `WApiSettings` | api | 请求配置与日志注入 | 不要在请求发出后改 baseOptions；它只在 DioRegistry.forBaseUrl 前设置 |
| `WApiClient` | api | GET / POST / PUT / PATCH / DELETE / HEAD / OPTIONS 统一调用 + 显式 JSON 解码 + 上传 | 不要在页面里直接拼 URL；不要用它替代 Repository 的业务编排 |
| `WApiBody` | api | 请求体编码：json / form / multipart / bytes | 不要用它承载业务逻辑；它只决定怎么编码 |
| `WApiException` | api | 统一网络错误分类：timeout / network / 401 / 4xx / 5xx / decode | 不要在库里写死用户文案；UI 按 kind 映射 |
| `WApiEnvelopeParser` | api | 可选业务信封解析：{code, message, data} | 不要默认开启；不是所有后端都用信封 |
| `WPage` | api | 一页数据 + total / hasMore（已弃用，7.0 删除；用 WAsyncPage） | 不要把它当 UI 状态；页面分页用 WAsyncPagedController |
| `WApiResponse` | api | 保留 status / headers / requestOptions 的响应结果 | 普通请求不需要它；get / post 直接返回模型 |
| `WRetryInterceptor` | api | 可选的幂等请求重试（GET / HEAD / PUT / DELETE / OPTIONS） | 不要默认开启；不要对 POST / PATCH 重试（可能重复提交） |
| `WMetricsInterceptor` | api | 可选的请求指标：method / path / status / duration / failed | 不要用它做日志或上报；只产出 WMetric，由业务决定怎么用 |
| `WQrView` | qr | 二维码 / 条形码扫描 | 不要直接用 `QRView`；重扫不要 Key 状态，用 `WQrController.restart` |
| `WQrController` | qr | 相机控制、广播扫描流与重扫 | 不要用它重置 UI 状态：单次锁定与节流由 `WQrView` 管理 |
| `WQrOverlayStyle` | qr | 扫描框颜色（含单次命中高亮）、外边距与扫描区域尺寸 | 不要用 `successColor` 做连续扫描的每码反馈：它只在单次模式生效；也不要自绘扫描框几何 |
| `WQrScanResult` | qr | onScanned 的扫码结果（code / format / rawBytes） | 不要把它当原始 Barcode：需要原始对象请监听 `WQrController.scannedDataStream` |
| `WMap` / `WMapZone` | map_google | Google Maps 地图与数据区域 | 不要直接用 `GoogleMap`；需要 API Key |
| `WMapController` | map_google | 业务侧选中 / 关闭 marker | 未挂载到地图时调用没有任何效果 |
| `WMapItemMapper` | map | 生成模型取地图字段 | 不要在 build 内重复创建 |
| `WNumFormatExtension` | core | 数字格式化：千分位 / 货币 / 百分比 / 前导零（12.0 从 ui 迁入） | 不要重复手写 toStringAsFixed / 正则分组；需要 locale 时用 intl |
<!-- catalog:8:end -->

## 9. 扩展

<!-- catalog:9:start -->
| 组件 | 子包 | 层级 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- | --- |
| `WNumLayoutExtension` | ui | core | num 的 EdgeInsets / BorderSide 糖 | SizedBox / BorderRadius 直接用 Flutter 原生构造；12.0 删除了 heightBox / widthBox / squareBox / horizontalPadding / verticalPadding / borderRadius |
| `WStringExtension` | ui | core | hex 颜色 | 数字转换 / 去空格 / trim / 资源路径都直接用 Dart / WImageSource |
| `WBoxDecorationExtension` | ui | core | BoxDecoration 的唯一背景 / 圆形组合 | 边框 / 圆角 / 阴影直接传 BoxDecoration 构造器；12.0 删除了 withColor / withBorderRadius / withShadow 等逐字段方法 |
| `WWidgetExtension` | ui | core | Widget 安全空间 / 方向 padding / 装饰 / IntrinsicHeight / toPressable | 需要 button 语义用 `WButton`；物理 padding 直接用 Flutter Padding |
| `WColorExtension` | ui | core | 十六进制颜色解析 / 输出 | 不要手写 Color(int.parse(...)) |
| `WGradients` | ui | core | 预设渐变（vertical / horizontal / diagonal / radial） | 不要写死品牌色；它只提供方向，颜色由调用方传 |
| `WShadows` | ui | core | 预设阴影（none / card / elevated / floating） | 不要用于深色模式文字阴影；它只是中性预设 |
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
