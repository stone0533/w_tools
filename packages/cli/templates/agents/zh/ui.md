- **页面与 UI**（`{{projectUiDir}}/` 是项目永久 UI 层，由 CLI 生成、不走 STAGED、不计划上移）：
  页面壳 `AppScaffold`（原生 `WScaffold` / `WAppBar` 只在特殊顶部栏或非标准安全区用）；
  `AppButtons` / `WButton` / `WPressable`；`WText(variant:)` / `WText.rich` / `WIconText`；`WImage.source`；`WListView` /
  `WKeepAliveWrapper` / `WNotificationListener` / `WGradientCircularProgressIndicator`；
  `WNavBar` / `WStep` / `WBadge`（`WBadge.count` / `WBadge.dot`）/ `WActionRow`；顶部 tab 直接用 Material `TabBar`；`WScreen`；
  `WSizeBox` / `WPadding` 已在 5.0 删除，用原生 `SizedBox` / `Padding`。细节：`explain WImage` / `explain WText` / `explain WIconText` / `{{projectUiDir}}/README.md`。
