# 组件使用约定（跨项目通用）

> 这份约定回答一个问题：**这个 UI，我该用现成的、加进包里，还是自己写？**
>
> 只写会被违反的规则；每条都配「怎么检查」。详细组件清单见 [`modules/components.md`](modules/components.md)。

## 1. 四个层，各放各的

| 层 | 路径（消费方项目内） | 放什么 |
| --- | --- | --- |
| **包** | `package:w_tools_*` | 与业务无关、多项目可用 |
| **项目 UI 层** | `lib/app/ui/` | 项目永久设计系统（AppScaffold / AppBars / AppBoxes / AppButtons / AppCard） |
| **暂存层** | `lib/app/design_system/` | 判定为「通用」、待上移进包的组件 |
| **业务层** | `lib/app/modules/**`、`data/**` | 知道业务的组合、数据、路由 |

`lib/app/ui/` 是项目永久规范，**不用于上移**；`design_system/` 只放带
`// STAGED:` 标记的候车组件。两者都允许直接 import `package:w_tools_*`。

## 2. 判定三连

```
① 它知道业务概念吗？（钱包、点数、会员等级…）
   知道 → 业务层，结束
   不知道 → 继续

② 别的功能 / 别的项目会不会也要？
   会 → 通用：
        项目永久规范（页面壳 / 样式注册表）→ lib/app/ui/
        可能进包 → lib/app/design_system/
   不确定 → 先放业务层，第二次出现再上移

③ 它只是「长什么样」（尺寸/颜色/圆角/间距）吗？
   是 → 就是通用壳，绝不能手写在业务层
```

## 3. Rule of two

```
第 1 次需要 → 业务层写（prototype，允许不完美）
第 2 次需要 → 上移：先进 design_system/，再由包维护者决定是否进 w_tools
```

上移时必须带：**设计稿实测尺寸写进注释** + 默认值可用 + 至少一个测试 + CHANGELOG 条目。

## 4. 暂存层（`lib/app/design_system/`）的四条硬约束

1. **import 边界**：只允许 `dart:*`、`package:flutter*`、`package:w_tools*`、`package:get`；
   禁止 import `data/`、`modules/`、`routes/`、`services/`（**依赖业务就永远上移不了**）
2. 文件头标 `// STAGED: 待上移到 w_tools_ui`
3. 注释写清设计稿实测尺寸（宽/高/圆角/颜色/行距）
4. 至少一个测试

> 暂存层**可以**直接 import 子包（`package:w_tools_ui/...`），不要 import 项目自己的聚合入口
> —— 它将来要整体搬进包里，走项目入口反而多一道坎。

## 5. 依赖策略

- 消费方**只依赖用到的子包**，不要依赖聚合包 `w_tools`
  （聚合包会把 `w_tools_map` 的 `google_maps_flutter` 一起拖进构建）
- 业务代码**只 import 项目自己的聚合入口**（如 `lib/app/w/toolkit.dart`），不直接 import 子包
- 开发期要现场改子包：用 `dependency_overrides` 指向本地 workspace，**不要**改回聚合包

完整理由见 [ADR-0002](adr/0002-consumers-depend-on-subpackages.md)。

## 6. API 设计原则（加组件时）

- **参数 ≤ 3 个** → 合成一个组件；**> 3 个** → 说明它们是两个组件，不要硬合并
- 默认值必须能用（调用方不传参数也能跑）
- 只暴露必要的东西；内部结构不要出现在 API 上
- 组件名用「它长什么样」，不用「它被谁用」

## 7. 提交前自检

先安装（纯 Dart，不依赖 Flutter）：

```yaml
dev_dependencies:
  w_tools_cli: ^1.1.0
```

```bash
dart run w_tools_cli:doctor            # 本项目是否遵守接入约定
dart run w_tools_cli:init --check      # 只检查缺失、不写文件（CI 用；内容不同只提示）
dart run w_tools_cli:init --check-drift # 连「模板已过期」也判失败（CI 想追踪模板更新时）
```

doctor 检查项：

| id | 级别 | 内容 |
| --- | --- | --- |
| R1 | error | `dependencies` 里出现聚合包 `w_tools`（`dev_dependencies` 豁免 —— doctor 自己就靠它；`dependency_overrides` 里出现只 **warn**） |
| R2 | error | 业务代码直接 import `package:w_tools_*`（聚合入口、`lib/app/ui/`、暂存层除外） |
| R3 | warn | 业务层硬编码语义色（**调色板默认空**，需声明 `colors.palette`；项目 UI / 暂存层豁免） |
| R4 | error | 设计系统（`lib/app/ui/`、暂存层）import 了 `data/` / `modules/` / `routes/` / `services/` |
| R5 | warn | 暂存层文件缺 `// STAGED:` 标记 |
| R6 | warn | 禁用单位 `.h` / `.r`（**项目专用，默认关**，配置 `rules.R6: true` 打开） |
| R7 | error | toolkit 的 `export` 与 pubspec 依赖不一致（导出未依赖 / 依赖未导出） |
| R8 | warn | 生成物由旧版 `w_tools_cli` 生成（只检查带 w_tools 标记的 target 文件与 toolkit；版本标记与 `pubspec.lock` 不一致） |

`--strict` 让 warning 也失败（默认关）；`--json` 给 CI 解析，issue 里的 `fix`
（`run` / `edit`）可直接执行，没有 `fix` 时看 `hint`。

**配置（可选）**：`.w_tools_doctor.yaml`。不写它 doctor 也按默认值运行；
把开关摊开用：

```bash
dart run w_tools_cli:doctor --print-config    # 打印带注释的默认配置
dart run w_tools_cli:doctor --write-config    # 写到 .w_tools_doctor.yaml（已存在则跳过，--force 覆盖）
```

`init` 也会顺手生成这个文件（带注释的默认配置，值与内置默认一致）。
常见调整：`colors.palette` 填项目语义色（不填则 R3 跳过）、`rules.R6: true` 打开禁用单位检查；
项目 UI 层固定为 `lib/app/ui/`，暂存层固定为 `lib/app/design_system/`；`init` 与 doctor 使用同一套路径。

> 早期这里放的是三条 grep 命令，现在**以 doctor 为唯一事实源** —— 同一份规则不能有两个实现，
> 否则必然漂移。
