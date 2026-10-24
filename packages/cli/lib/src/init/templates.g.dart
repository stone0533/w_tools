// 由 tool/gen_templates.dart 生成，不要手改。
// 模板源文件在 templates/（唯一来源）；改完跑 `dart run tool/gen_templates.dart`。
//
// dart format off
// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars

const String toolkitTemplate = r'''
// 本项目实际用到的 w_tools 能力清单（由 `dart run w_tools_cli:init` 生成）。
//
// 业务代码统一 import 这里，不要直接 import 各个子包 ——
// 将来换依赖方式（分包 / 精简聚合）只改这一个文件。
//
// 为什么不用聚合包 w_tools：它会把 w_tools_map 的 google_maps_flutter
// 原生 SDK 一起拖进构建（Android registrant + iOS pod）。理由见 https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md 。
library;

export 'package:w_tools_core/w_tools_core.dart';
export 'package:w_tools_app/w_tools_app.dart';
export 'package:w_tools_form/w_tools_form.dart';
export 'package:w_tools_ui/w_tools_ui.dart';
export 'package:w_tools_api/w_tools_api.dart';
export 'package:w_tools_toast/w_tools_toast.dart';
export 'package:w_tools_qr/w_tools_qr.dart';   // @optional:qr
export 'package:w_tools_map/w_tools_map.dart'; // @optional:map
''';

const String designSystemReadme = r'''
# lib/app/design_system —— 通用组件暂存层

> **这里不是终点，是「等着上移到 w_tools 的候车室」。**
> 判定方法与上移流程见 [w_tools 的接入约定](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)。

## 什么该放这里

只描述「长什么样」、完全不知道业务的组件：弹窗壳、品牌 logo 方块、图标+文字一行、
虚线分隔、空态/加载态、语义颜色。

**不该放**：知道业务概念的（交易卡、点数徽章、会员等级条）—— 留在 `lib/app/modules/`。

## 四条硬约束

1. **import 边界**：只允许 `dart:*`、`package:flutter*`、`package:w_tools*`、`package:get`；
   禁止 `data/`、`modules/`、`routes/`、`services/`
2. 文件头标 `// STAGED: 待上移到 w_tools_ui`
3. 注释写清设计稿实测尺寸（宽/高/圆角/颜色/行距）
4. 至少一个测试

> 这一层**可以**直接 import 子包（`package:w_tools_ui/...`）：它将来要整体搬进包里。

## 检查

```bash
dart run w_tools_cli:doctor      # R4 / R5 会检查这一层
```
''';

const String agentsSnippet = r'''
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
''';

