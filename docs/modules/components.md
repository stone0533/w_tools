# 组件目录（先查这里，没有再动手）

> 用法：**按用途找**。找到就用，找不到再看文末「待补」清单 —— 待补的东西应该先进消费方的
> `lib/app/design_system/`，出现第二个用例后再上移进包（见 [`docs/conventions.md`](../conventions.md)）。

## 1. 页面骨架与导航

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WScaffold` | ui | 页面容器：背景色、状态栏样式、底部安全区 | 不要在页面里再手写 `Scaffold` 包一层 |
| `WAppBar` | ui | 顶部导航栏（配全局 `WAppBarConfig`） | **不要**逐页覆盖高度/标题字号来「贴合设计稿」 |
| `WNavBar` / `WNavController` | ui | 底部 tab 栏 | 不要自己写 `BottomNavigationBar` |
| `WTabBar` | ui | 顶部 tab | 需要下划线跟随的复杂交互时先看它够不够 |
| `WStep` | ui | 步骤条（注册流程等） | — |

## 2. 文本与图标

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WText` / `WTextConfig` | ui | 所有文字（字体、字重、行高、颜色） | 不要裸用 `Text` —— 字体会漏配 NotoSansTC |
| `WRichText` | ui | 一段文字里多种颜色/字重 | 单色文本用 `WText` 更省事 |
| `WImage` | ui | 网络图/资源图（缓存、重试、占位） | 不要裸用 `Image.network` |

> **图标 + 文字排成一行**（垂直居中）：目前没有组件，见文末「待补」——
> 不要用 `Row + Icon + Text`，中文字形在行盒里偏下，图标会看着偏高 1.5~2.5px。

## 3. 按钮与操作

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WButton` | ui | 纯点击区域（无样式，包任何 child） | 需要「看起来像按钮」时用 `WForm.buttonLogin` 等 |
| `WRowButtons` | ui | 一行多个按钮 | — |
| `WBadge` | ui | 角标数字 | — |

## 4. 布局与容器

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WContainer` / `WContainerConfig` | ui | 圆角/描边/阴影/内边距的盒子 | 需要**1px 描边且不占宽度**时用 `foregroundDecoration`（`border` 会挤掉 2px） |
| `WRow` / `WColumn` / `WPadding` / `WSizeBox` | ui | 常用布局糖 | — |
| `WClipRRect` | ui | 裁剪 | — |

## 5. 表单

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WFormTextField` / `WForm.textFieldStyle1` | form | 输入框（含校验、清除、密码显隐） | **不要**自己画 `Container + TextField` |
| `WFormBorder` / `WForm.field` | form | 输入框的框与标签（错误态） | — |
| `WFormDropdown` / `WFormMultiDropdown` | form | 下拉、多选 | 选择类面板用 `WForm.showBottomSheet`（ADR-0002） |
| `WFormCheckbox` / `WFormRadioGroup` | form | 复选、单选 | — |
| `WFormDatePicker` | form | 日期选择 | — |
| `WFormValidator*` | form | 表单校验 | — |
| `WFormButton` | form | 带样式的按钮（登录/注册/主按钮） | 纯点击用 `WButton` |

## 6. 弹层

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WBottomSheet` | app | 底部面板外壳 | — |
| `WForm.showBottomSheet` | form | 选择类面板（42 高行、无勾选图标） | **不要**自己写 sheet（ADR-0002） |
| `WFormPopup` | form | **锚定式**下拉弹层（贴在输入框下方） | ⚠️ 它不是居中对话框，别拿来做「确认弹窗」 |

## 7. 状态与反馈

| 组件 | 子包 | 用来做什么 | **不要用在哪** |
| --- | --- | --- | --- |
| `WToast` / `WnnToast` | toast | 轻提示 | — |
| `WGradientCircularProgressIndicator` | ui | 加载指示 | — |
| `WListView` / `WListViewConfig` | ui | 列表（分页、下拉刷新） | — |

## 8. 能力（非 UI）

| 能力 | 子包 | 说明 |
| --- | --- | --- |
| `WApp` / `WAppPlugin` | app | 启动器与插件分层初始化 |
| `WAsync` / `WCountdown` / `WCancelToken` | core | 异步、倒计时、取消 |
| `WStorage` / `WToken` / `WEncrypt` / `WHash` | core | 存储、令牌、加密、摘要 |
| `WLogger` / `WValidator` / `WRegExp` | core | 日志、校验、正则 |
| `WApiConfig` | api | 请求配置与日志注入 |
| `WRoute` | app | 路由工具 |

## 9. 待补（有重复用例，尚未进包）

| 组件 | 现状 | 计划去向 |
| --- | --- | --- |
| **居中弹窗壳**（311 宽 / r20 / 57 高 `#F8F8F5` 头部 / 按钮排布） | 各项目手写，样式已开始漂移 | `w_tools_ui` |
| **图标 + 文字一行**（`WidgetSpan` + 光学补偿） | 各项目手写 `Row`，对齐普遍偏 1.5~2.5px | `w_tools_ui` |
| **品牌 logo 方块**（48 底 / 40 图 / r10 / `#EAEAEA` 边） | 至少 3 处重复 | `w_tools_ui` |
| **虚线分隔**（`#CFCFCF` dash[2,2] 等） | 各项目自己画 | `w_tools_ui` |
| **空态**（80 圆 + 图标 + 文案） | 各项目各写一份 | `w_tools_ui` |
| **语义颜色 token**（`#3F3F3F`/`#545454`/`#EAEAEA`/`#409C35`…） | 全项目硬编码 | `w_tools_core` |

## 10. 版本

版本以各包 `pubspec.yaml` 与 pub.dev 为准，**不要在这里硬编码**（历史上这张表已经漂移过）。
聚合包 `w_tools` 只做 re-export，消费方不要依赖它（理由见
[ADR-0002](../adr/0002-consumers-depend-on-subpackages.md)）。
