> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# toast 1.2 迁移：门面与样式拆分

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WToastConfig()` 的 `showSuccess` / `showError` / ... | `WToast.showSuccess(...)` 等静态方法 | `WToast` 成为唯一门面 |
| `WToastConfig` 可变字段 | `WToastStyle`（不可变，`copyWith` 传 `null` 可清空） | `WToastConfig` 弃用（2.0 移除），仍可用 |
