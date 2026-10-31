# 组件目录（先查这里，没有再动手）

> CLI 内置同一份目录：`dart run w_tools_cli:list <关键词>` / `:explain <组件名>`。

> 用法：**按用途找**。找到就用，找不到再看文末「待补」清单 —— 待补的东西应该先进消费方的
> `lib/app/design_system/`，出现第二个用例后再上移进包（见 [`docs/conventions.md`](../conventions.md)）。

## 1. 页面骨架与导航

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WScaffold` | ui | 页面壳：默认 WAppBar、body、底部导航/FAB、安全区 | 任意顶部叠放用页面层 Container/Stack |
| `WAppBar` | ui | 标准顶部导航栏（leading/title/actions/bottom） | 任意叠放/覆盖布局在页面层用 Container/Stack |
| `WNavBar` / `WNavController` | ui | 底部 tab 栏；controller 需 vsync 并由页面 State dispose | 不要自己写 `BottomNavigationBar` |
| `WTabBar` | ui | 顶部 tab；依赖 TabController / DefaultTabController | 需要下划线跟随的复杂交互时先看它够不够 |
| `WStep` / `WStepFlow` | ui | 步骤条（注册流程等） | 背景/高度用外层 Container；多步骤注意横向空间 |

## 2. 文本与图标

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WText` / `WTextVariant` / `WTextStyles` | ui | 语义文字样式、overrides、maxLines、textScaler | 不要再用 `WTextConfig`；已移除，使用 `WTextStyles` |
| `WImage` | ui | 网络图/资源图（缓存、重试、占位） | 不要裸用 `Image.network` |

> **图标 + 文字排成一行**（垂直居中）：目前没有组件，见文末「待补」——
> 不要用 `Row + Icon + Text`，中文字形在行盒里偏下，图标会看着偏高 1.5~2.5px。

## 3. 按钮与操作

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WButton` | ui | 真正的按钮（label/icon + style/size/loading） | 任意 child 点击用 `WPressable` |
| `WPressable` | ui | 任意 child 的点击 + 基础效果（无 button 语义） | 需要 button 语义时用 `WButton` |
| `WRowButtons` | ui | 一行多个按钮 | — |
| `WBadge` | ui | 角标数字 | — |

## 4. 布局与容器

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WRow` / `WColumn` / `WPadding` / `WSizeBox` | ui | 常用布局糖 | — |
| `WClipRRect` | ui | 裁剪 | — |
| `WScreen` | ui | 屏幕 / 字体适配（w/h/sp）、状态栏 / 底部安全区 | 不要重复用 MediaQuery 手写全局适配 |
| `WAssets` | ui | 图片资源前缀唯一开关 | 不要硬编码 `assets/images/` |

## 5. 表单

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WForm` | form | 页面表单容器：主题 / Scope / 只读 / 默认字段样式 / 默认校验 | 不要手写 `WFormTheme + WFormScope + WFormReadOnlyScope` |
| `WFormController` | form | 表单数据 / 字段值 / 校验入口 | 多个 WForm 不要共用一个 controller |
| `WFormTextField` | form | 直接文本 / 密码字段（label / message / validator） | 不要默认写 `WFormTextFieldConfig().build(...)` |
| `WFormDropdown` / `WFormMultiDropdown` | form | 直接下拉 / 多选字段 | 选择类弹层用 `WFormPopup` |
| `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup` | form | 直接日期 / 复选 / 单选字段 | — |
| `WFormButton` | form | 直接自定义字段按钮（选择、弹层触发） | 普通业务按钮用 `WButton`；底层用 `WFormFieldButtonCore` |
| `WFormFieldStyle` | form | 页面级字段默认高度 / 内边距 / 文字 / hint 样式 | 字段特殊样式用字段 `config` 覆盖 |
| `WFormValidatorSettings` | form | 校验行为：边框错误、短路 / 全量、回调 | — |
| `WFormBorder` | form | 低层边框 / 错误展示；普通页面由 `WForm` 统一提供 | 普通字段不要手写 `WFormBorder` |

## 6. 弹层

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WBottomSheet` | app | 底部面板外壳 | — |
| `WFormPopup` | form | **锚定式**下拉弹层（贴在输入框下方） | ⚠️ 它不是居中对话框，别拿来做「确认弹窗」 |

## 7. 状态与反馈

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WAsyncView` / `WAsyncErrorView` / `WAsyncErrorBanner` | async | 普通页面异步四态视图、默认重试页与刷新错误条 | 滚动页面用 `WAsyncStateBuilder`；纯状态逻辑用 `WAsyncState` / `WAsyncController` |
| `WAsyncStateBuilder` / `WAsyncBuilder` | async | 滚动页面 / `SmartRefresher` / 自定义状态布局 | 普通页面优先用 `WAsyncView`；`WAsyncBuilder` 是兼容别名 |
| `WAsyncController` | async | 单区块异步状态、load / retry / 旧请求丢弃 | 分页用 `WAsyncPagedController`；纯执行用 `WAsync` |
| `WAsyncPagedController` | async | 分页列表：首屏、刷新、追加、hasMore | 普通单请求用 `WAsyncController` |
| `WAsyncStateSliver` | async | CustomScrollView 的四态 sliver、failed+旧数据 | 非滚动页面用 `WAsyncView` |
| `WAsyncSliverDefaults` | async | WAsyncStateSliver 的 sliver 默认视图 | 不要复用 `WAsyncViewDefaults`；状态 builder 必须非滚动 |
| `WToast` | toast | 轻提示 | — |
| `WGradientCircularProgressIndicator` | ui | 加载指示 | — |
| `WListView` / `WListViewSliver` | ui | 列表（独立滚动 / SmartRefresher sliver） | — |
| `WKeepAliveWrapper` | ui | 列表项保活 | 不要用它做滚动回调；只负责 keepAlive |
| `WNotificationListenerBuilder` | ui | 监听滚动通知 / 百分比 | 百分比只处理 depth 0 的 ScrollUpdateNotification |

## 8. 能力（非 UI）

| 能力 | 子包 | 说明 |
| --- | --- | --- |
| `WApp` / `WAppPlugin` | app | 启动器与插件分层初始化 |
| `WAsyncState` | async | 四态快照与 `when` | 不要手写 `ValueNotifier<WAsyncState>` |
| `WAsync` / `WCancelToken` | async | 异步执行、取消 | — |
| `WCountdown` | core | 倒计时 |
| `WStorage` / `WToken` / `WEncrypt` / `WHash` | core | 存储、令牌、加密、摘要 |
| `WLogger` / `WValidator` / `WRegExp` | core | 日志、校验、正则 |
| `WApiConfig` | api | 请求配置与日志注入 |
| `WRoute` | app | 路由工具 |

## 9. 扩展

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WNumExtension` | ui | 数字格式化 / 间距 / 圆角 / BorderSide 糖 | 不要重复手写 toStringAsFixed / SizedBox / EdgeInsets |
| `WStringExtension` | ui | String 转数字 / 去空格 / hex 颜色 / 资源路径 | 图片组件转换用 `WUiStringExtension` |
| `WBoxDecorationExtension` | ui | BoxDecoration 组合（颜色 / 边框 / 圆角 / 阴影） | 不要每次重写完整 BoxDecoration |
| `WWidgetExtension` | ui | Widget 间距 / 安全空间 / 装饰 / IntrinsicHeight | 需要 button 语义用 `WButton` |
| `WUiWidgetExtension` | ui | `toPressable`（任意 child 点击，无 button 语义） | 需要 button 语义用 `WButton` |
| `HexColor` | ui | 十六进制颜色解析 / 输出 | 不要手写 Color(int.parse(...)) |

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
