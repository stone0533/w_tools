# toast 1.3 迁移：全局主题与组合入口

| 旧 | 新 | 说明 |
| --- | --- | --- |
| 每个调用点传 `style:` | `WToastTheme(style: ...)` + `WToast.showXxx(..., context: context)` | 显式 `style:` 仍最高优先 |
| 手写 loading → 执行 → 结果提示 | `WToast.runWithLoading(task, message:, successMessage:, errorMessage:)` | 失败先提示再 `rethrow` |
| `showXxx(style: ...)` 非空 | `style` 改可空（不传按 context / 默认解析） | 源码兼容 |
