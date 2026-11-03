# 下一个大版本的删除清单（2026-11-04）

> 由 `python3 scripts/list_removals.py --md` 生成；执行前重跑，避免清单过期。
> 删除前提：对应的目标版本已经发布（用户已有一版弃用警告）；删除后跑
> `python3 scripts/check_deprecations.py` + `bash scripts/preflight.sh`。

## 汇总

| 目标版本 | 数量 | 包 |
| --- | --- | --- |
| 2.0.0 | 16 | app（字段版配置） |
| 3.0.0 | 17 | core（WConfig / WRegExpPattern / WUx / 旧清理函数） |
| 4.0.0 | 4 | form（自定义边框 builder / WFormDefaults） |
| 5.0.0 | 30 | ui（WRowButtons / 图片预设 / 布局糖 / HexColor / WSizeBox 等） |

## 明细

| 到期 | 包 | 位置 | 声明 |
| --- | --- | --- | --- |
| 2.0.0 | app | `packages/app/lib/src/app.dart:103` | `Locale? locale;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:108` | `Locale? fallbackLocale;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:120` | `Widget Function(Widget child)? appWrapper;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:45` | `String? title;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:50` | `String? initialRoute;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:55` | `List<GetPage<dynamic>>? getPages;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:60` | `List<DeviceOrientation> orientations = [DeviceOrientation.portraitUp];` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:68` | `SystemUiOverlayStyle? systemUiOverlayStyle = const SystemUiOverlayStyle(` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:78` | `TransitionBuilder? builder;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:83` | `List<NavigatorObserver>? navigatorObservers;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:88` | `Transition? defaultTransition;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:93` | `ThemeData? theme;` |
| 2.0.0 | app | `packages/app/lib/src/app.dart:98` | `Translations? translations;` |
| 2.0.0 | app | `packages/app/lib/src/utils/route.dart:65` | `class WRoute {` |
| 2.0.0 | map | `packages/map/lib/src/map_zone.dart:138` | `void Function()? onDataUpdated;` |
| 2.0.0 | toast | `packages/toast/lib/src/toast_config.dart:15` | `class WToastConfig {` |
| 3.0.0 | async | `packages/async/lib/src/view/async_sliver_defaults.dart:14` | `class WAsyncSliverDefaults extends InheritedWidget {` |
| 3.0.0 | async | `packages/async/lib/src/view/async_view_defaults.dart:23` | `class WAsyncViewDefaults extends InheritedWidget {` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:16` | `'该字段没有任何效果；请改用 w_tools_ui 的 WAssets.imagePath'` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:28` | `static set tokenKey(String value) => WToken.tokenKey = value;` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:33` | `static String get refreshTokenKey => WToken.refreshTokenKey;` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:38` | `static set refreshTokenKey(String value) => WToken.refreshTokenKey = value;` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:43` | `static String get tokenExpiryKey => WToken.tokenExpiryKey;` |
| 3.0.0 | core | `packages/core/lib/src/config.dart:48` | `static set tokenExpiryKey(String value) => WToken.tokenExpiryKey = value;` |
| 3.0.0 | core | `packages/core/lib/src/utils/hash.dart:66` | `static String hashPassword(String password, {String? salt}) {` |
| 3.0.0 | core | `packages/core/lib/src/utils/platform.dart:105` | `static T getPlatformValue<T>({` |
| 3.0.0 | core | `packages/core/lib/src/utils/platform.dart:135` | `static void runForPlatform({` |
| 3.0.0 | core | `packages/core/lib/src/utils/reg_exp.dart:8` | `class WRegExpPattern {` |
| 3.0.0 | core | `packages/core/lib/src/utils/reg_exp.dart:85` | `class WRegExpPreset {` |
| 3.0.0 | core | `packages/core/lib/src/utils/ux.dart:24` | `WCancellableAction debounce(Function() function, {int duration = 300}) {` |
| 3.0.0 | core | `packages/core/lib/src/utils/ux.dart:47` | `WCancellableAction throttle(Function() function, {int duration = 300}) {` |
| 3.0.0 | core | `packages/core/lib/src/utils/validator.dart:107` | `static String escapeSql(String input) {` |
| 3.0.0 | core | `packages/core/lib/src/utils/validator.dart:124` | `static String stripHtml(String input) {` |
| 4.0.0 | form | `packages/form/lib/src/components/border/border.dart:230` | `static WFormBorderConfigBuilder builder() => WFormBorderConfigBuilder();` |
| 4.0.0 | form | `packages/form/lib/src/components/border/border.dart:414` | `class WFormBorderConfigBuilder {` |
| 4.0.0 | form | `packages/form/lib/src/components/border/field_shell.dart:11` | `extension WFormRowBorderExtension on Row {` |
| 4.0.0 | form | `packages/form/lib/src/components/form_defaults.dart:9` | `class WFormDefaults {` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:67` | `(unknown)` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:70` | `(unknown)` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:73` | `this.enableLog = true,` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:76` | `this.enableLog = true,` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:79` | `this.enableLog = true,` |
| 5.0.0 | api | `packages/api/lib/src/interceptors/log.dart:82` | `this.enableLog = true,` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/button/button_styles.dart:66` | `static final primary = WButtonStyle.filled(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/button/button_styles.dart:73` | `static final secondary = WButtonStyle.outlined(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/button/button_styles.dart:80` | `static final text = WButtonStyle.text(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/button/button_styles.dart:86` | `static final danger = WButtonStyle.filled(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image.dart:252` | `factory WImage.avatar(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image.dart:287` | `'用 `WImage(data, style: WImageStyle.thumbnail(...), config: WImageLoadConfig(memCacheWidth: ...))`；5.0 移除',` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image.dart:330` | `factory WImage.cover(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image.dart:359` | `factory WImage.assetImage(` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_cache_policy.dart:10` | `class WImageCachePolicy {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_config.dart:114` | `typedef WImageConfig = WImageLoadConfig;` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_defaults.dart:11` | `class WImageDefaults {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:117` | `final class WImageEmptyError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:128` | `final class WImageNetworkError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:142` | `final class WImageAssetError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:156` | `final class WImageDecodeError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:170` | `final class WImageProviderError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:184` | `final class WImageFileError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/image/image_types.dart:198` | `final class WImageUnsupportedError extends WImageError {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/row_buttons.dart:14` | `class WRowButtons extends StatefulWidget {` |
| 5.0.0 | ui | `packages/ui/lib/src/components/common/row_buttons.dart:263` | `class WRowButtonsController {` |
| 5.0.0 | ui | `packages/ui/lib/src/utils/column.dart:4` | `class WColumn {` |
| 5.0.0 | ui | `packages/ui/lib/src/utils/padding.dart:4` | `class WPadding {` |
| 5.0.0 | ui | `packages/ui/lib/src/utils/row.dart:4` | `class WRow {` |
| 5.0.0 | ui | `packages/ui/lib/src/utils/size_box.dart:4` | `class WSizeBox {` |
