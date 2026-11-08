# w_tools_ui · 组件示例

`w_tools_ui` 的可运行示例：主壳用 `WScaffold` + `WAppBar` + `WNavBar`，
5 个主 Tab + 「更多」里的 6 个二级页。

## 页面

| 页面 | 位置 | 覆盖 |
|---|---|---|
| **Playground** | `lib/playground_page.dart` | WImage 参数实时调整：width / height / aspectRatio / fit / memCache / borderRadius / retryCount / placeholder / border / boxShadow / margin；`onLoadStatusChanged`、`onProgress`、`WImageController.retry`、`WImageSource.network(headers/cacheKey)`，并同步生成当前 `WImageStyle` / `WImageLoadOptions` / `WImageSlots` 代码 |
| **状态矩阵** | `lib/states_page.dart` | 加载成功 / 失败 / 空数据 / 加载中 / 主题默认错误占位 / file 不支持 / `precacheImage` 预热 |
| **常用配方** | `lib/recipes_page.dart` | `WImageStyle.avatar / thumbnail / cover`、asset prefix、`WImageSource.provider(MemoryImage)`、内置错误 + 自动重试 |
| **按钮** | `lib/buttons_page.dart` | `WButton` 的主题四态、loading / disabled、3 档尺寸 + 自定义、纯图标、列表行、对话框、content / contentBuilder、WidgetStateProperty、键盘 / 语义、`onLongPress`、`loadingBuilder`、`WButtonMotion`；`WPressable` 的 enabled / onLongPress / pressedOpacity |
| **组件** | `lib/components_page.dart` | WText、WScaffold、WScreen.w、扩展、WBadge（topRight / center / showBadge / 空内容）、WClipRRect（含配置变体）、渐变进度（含 totalAngle / strokeCapRound）、WStep、WListView（separated / grid）、WActionRow、WSelectableRow、WTabBar、WNavBar、通知百分比、WImageController、keepAlive |
| **更多** | `lib/more_page.dart` | 二级示例入口（见下） |
| └ WScaffold / WAppBar / WScreen | `lib/scaffold_page.dart` | WScaffold 全参数（appBar 覆盖 / titleWidget / leading / actions / onBack / appBarStyle / appBarBottom / FAB / underlay / 状态栏 / 安全区）、WAppBar 全参数、WAppBarStyle（背景 / 渐变 / 高度 / 标题 / overlay）、WScreen.of / 安全区 / 适配委托、WAssets + `assetImagePath` |
| └ WText / WTextStyles | `lib/text_page.dart` | 11 个 variant、price/number 表格数字、maxLines / overflow / softWrap / textAlign / textScaler / style / color / semanticsLabel、自定义 `WTextStyles` + `withWTextStyles` |
| └ 扩展方法 | `lib/extensions_page.dart` | 7 个扩展文件：数字、字符串、颜色 / hex、文字样式、Widget（expanded / padding / intrinsic / decoration / toPressable）、GlobalKey、BoxDecoration、WGradients / WShadows |
| └ 列表 / 通知 / 保活 | `lib/lists_page.dart` | WListViewSliver 的 list / separated / grid / overlap、header / footer / empty / emptyFill、keepAlive、WNotificationListener（onNotification / percentage / prevent）、WKeepAliveWrapper 开关 |
| └ 导航 / Tab | `lib/nav_page.dart` | WNavController（animateTo / currentIndex / previousIndex / indexIsChanging / offset）、onItemTap 拦截、WNavBarStyle 装饰 / padding、WTabBar 配置（indicator / divider / scrollable / tabAlignment / onTap）、WTabBarStyle.copyWith |
| └ 步骤 | `lib/steps_page.dart` | WStep 默认、WStepStyle 全字段、itemBuilder / separatorBuilder / semanticLabelBuilder、WStepFlow 复用 + copyWith |

## 覆盖矩阵（25 个入口分组 / 68 条 catalog）

| 入口 | 页面 | 关键点 |
|---|---|---|
| `WScaffold` | scaffold_page、main | title / actions / FAB / appBar 覆盖 / underlay / 安全区 |
| `WAppBar` | scaffold_page | title / titleWidget / leading / actions / bottom / onBack / centerTitle / includeStatusBar |
| `WNavBar` / `WNavController` | main、nav_page、components_page | 切换动画、拦截、状态、config |
| `WTabBar` | nav_page、components_page | indicator / divider / scrollable / onTap |
| `WStep` / `WStepFlow` | steps_page、components_page | style / builders / 复用 |
| `WText` / `WTextVariant` / `WTextStyles` | text_page、components_page | 11 variant / 覆盖 / 自定义主题 |
| `WImage` | playground、states、recipes、components | 四种来源 / 状态 / 重试 / 进度 / 控制器 |
| `WImageSource` | playground、states、recipes | network(headers/cacheKey) / asset / file / base64 / provider / parse |
| `WButton` | buttons_page | 主题 / 尺寸 / loading / 语义 / motion / 长按 |
| `WPressable` | buttons_page、extensions_page | enabled / long press / pressedOpacity / toPressable |
| `WActionRow` / `WSelectableRow` | components_page | 横向操作行 / 单选高亮 |
| `WBadge` | components_page | topRight / center / showBadge / 空内容 |
| `WClipRRect` | components_page | all / copyWith / 默认值 |
| `WScreen` | scaffold_page、components_page | of(context) / w·h·sp / 委托 |
| `WAssets` | scaffold_page、recipes_page | imagePath / assetImagePath |
| `WGradientCircularProgressIndicator` | components_page | value / totalAngle / strokeCapRound / backgroundColor |
| `WListView` / `WListViewSliver` | lists_page、components_page | list / separated / grid / overlap / 空态 / keepAlive |
| `WKeepAliveWrapper` | lists_page、components_page | 开关与回收 |
| `WNotificationListener` | lists_page、components_page | onNotification / percentage / prevent |
| `WNumExtension` | extensions_page、components_page | 间距 / 格式化 / 圆角 |
| `WStringExtension` | extensions_page | toInt / toDouble / trimAll / toColor / assetImagePath |
| `WBoxDecorationExtension` | extensions_page、components_page | with* / without* / shape |
| `WWidgetExtension` | extensions_page | expanded / padding / intrinsic / decoration |
| `WUiWidgetExtension` | extensions_page | toPressable |
| `WColorExtension` | extensions_page | fromHex / toHex |

## 运行

```bash
cd packages/ui/example
flutter pub get
flutter run
```

> 示例使用 `https://picsum.photos` 的远程图片；重试演示使用必然失败的
> `example.invalid`，用于观察错误占位和重试按钮。
>
> `assets/demo.png` 由 `WAssets.imagePath = 'assets/'` + `prefix: true` 解析。

## 测试

```bash
flutter test                       # 每页都可切换、二级页可打开、代码面板是 6.0 API
```

## 真实引擎 keep-alive / TickerMode 测试

`integration_test/app_keepalive_smoke_test.dart` 是参考示例，验证 `WKeepAliveWrapper`
在真实引擎上的 State / 滚动保留与不可见页 TickerMode 关闭：

```bash
cd packages/ui/example
flutter test integration_test/app_keepalive_smoke_test.dart -d <device>
```

它使用固定 `_Harness`，不能替代业务 App 自己的页面测试；需要时复制 / 改写。
