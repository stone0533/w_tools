> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 1.1 迁移：底部弹窗参数 / 路由回退

- `WBottomSheet.show` 新增透传参数：`backgroundColor` / `barrierColor` / `isDismissible` /
  `enableDrag` / `shape` / `clipBehavior` / `ignoreSafeArea` / `elevation` / `isScrollControlled`；
  不传时保持原行为（`isScrollControlled: true`）。
- `WRoute.popUntilRoute` 改用路由自身 `settings.name` 判断（不再依赖 `Get.currentRoute`），
  避免名不一致时一路弹空。
- `WApp.run()` 的 `title ?? ''` 死分支移除（前面已校验非空），行为不变。
