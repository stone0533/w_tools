# w_tools_cli

`w_tools` 的接入工具（纯 Dart，不依赖 Flutter）：

- **init**：把接入约定装进当前项目，生成聚合入口、暂存层 README、`AGENTS.md` 片段
  和 `.w_tools_doctor.yaml`（全注释，不改变行为）。
- **doctor**：扫描项目，检查是否遵守「只依赖子包、业务代码只 import 聚合入口、
  暂存层不依赖业务」等约定（R1~R6）。

## 安装

```yaml
dev_dependencies:
  w_tools_cli: ^1.0.0
```

```bash
dart run w_tools_cli:init      # 生成到当前项目
dart run w_tools_cli:doctor    # 之后随时检查
```

> 通过 `dart run` 使用；这个包不声明全局可执行文件，避免把 `init` / `doctor`
> 这么泛的名字装进用户 PATH。

`init` 不会改 `pubspec.yaml`：它只打印需要加入的依赖片段。

`init --check` **只检查缺失**：已存在的文件即使内容不同也只提示（用 `--force` 更新），
`.w_tools_doctor.yaml` 作为项目配置更不做内容比对 —— 所以可以把它当「是否初始化过」的 CI 门禁。
需要同时发现「模板已过期」时用 `--check-drift`（内容不同也返回非 0）。

## doctor 规则

| id | 级别 | 内容 |
| --- | --- | --- |
| R1 | error | `dependencies` 里出现聚合包 `w_tools` |
| R2 | error | 业务代码直接 import `package:w_tools_*`（聚合入口、暂存层除外） |
| R3 | warn | 硬编码语义色（默认关；需在 `.w_tools_doctor.yaml` 声明 `colors.palette`） |
| R4 | error | 暂存层 import 了 `data/` / `modules/` / `routes/` / `services/` |
| R5 | warn | 暂存层文件缺 `// STAGED:` 标记 |
| R6 | warn | 禁用单位 `.h` / `.r`（项目专用，默认关，配置 `rules.R6: true` 打开；`--strict` 才失败） |

`--strict` 让 warning 也失败；`--json` 给 CI 解析；`--only=R1,R2` 只跑指定规则；
`--include-tests` 同时扫 `test/` 与 `tool/`。

```bash
dart run w_tools_cli:doctor --print-config   # 打印带注释的默认配置
dart run w_tools_cli:doctor --write-config   # 写到 .w_tools_doctor.yaml
```

设计依据与接入约定见仓库 [`docs/conventions.md`](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)
与 [ADR-0002](https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md)。

## 开发

模板唯一来源是 `templates/`，修改后必须重新生成：

```bash
cd packages/cli
dart run tool/gen_templates.dart        # 生成 lib/src/init/templates.g.dart
dart run tool/gen_templates.dart --check # CI 校验
dart test --coverage=coverage            # 覆盖率
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib --package=.
```
