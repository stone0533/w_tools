<!-- w_tools:begin -->
## 组件来源（优先用 w_tools）

1. 先在 `w_tools` 找现成的（[组件清单](https://github.com/stone0533/w_tools/blob/main/docs/modules/components.md)）。业务代码统一
   `import 'package:<app>/app/w/toolkit.dart';`（本项目用到的能力清单）
2. 找不到 → 先放 **`lib/app/design_system/`**（暂存层），**不要**直接改 w_tools
   - 只允许 import `dart:*` / `package:flutter*` / `package:w_tools*` / `package:get`
   - 文件头标 `// STAGED: 待上移到 w_tools_ui`，并写清设计稿实测尺寸
   - 是否进 w_tools 由包维护者决定（触发：第二个功能也用到 / 到发版窗口）
3. 业务层只放「这个功能独有的组合」，不放「通用组件」

**硬规则**：pubspec 只依赖具体子包（禁止聚合包 `w_tools`）；业务代码只 import 聚合入口，
禁止直接 import `package:w_tools_*`。

**提交前**：`dart run w_tools_cli:doctor`（R1 依赖、R2 直连、R3 硬编码色、R4/R5 暂存层）
<!-- w_tools:end -->
