> 分析记录：提案；阶段 A / B 已于 2026-11-11 落地到 `w_tools_cli 1.19.0`（实现见
> `packages/cli/lib/src/upgrade/`，结论与偏差见文末「落地情况」）。

# CLI 增加「把 w_tools 依赖抬到 pub 最新」命令（2026-11-11）

> 需求：消费方项目里一条命令，把 `pubspec.yaml` 里的 `w_tools*` 依赖抬到 pub 上的最新版本。
> 样本：`28_uReward/01_Git/ureward`（下称 ureward）。基线 `main`，本地 `w_tools_cli 1.18.2`。

## 1. 结论

值得做，但**不要从「改 pubspec 里的版本号」开始**。

实测（见 §3）：ureward 现在**所有** `w_tools*` 约束下界都已经允许最新版本，
`flutter pub upgrade` 就能装到最新；真正落后的是**声明下界、`pubspec.lock`、生成物的版本标记**这三处，
以及**没有任何一条命令把「查最新 → 抬下界 → 装 → 刷新生成物 → 自检」串起来**（这正是
`templates/ai/consumer-prompts.md` 的 F-1/F-2/F-3 场景，现在要人手工做）。

所以命令的价值排序是：

1. **只读的一句「我落后了几个包」**（给人和 AI 的 F-1 输入，可进 CI）——最先做，零风险；
2. 抬下界 + 定向安装 + 失败回滚（写文件，但只写 pubspec 的版本 token）；
3. 跨 major 的策略与报告（w_tools 的 major 都是 breaking，不能自动跨）；
4. 闭环：提示/执行 `init`（R8 的生成物版本标记只在 `init` 里刷新）。

## 2. 三种「升级」不能混为一谈

| 语义 | 载体 | 谁改 | 失败模式 |
| --- | --- | --- | --- |
| 抬声明下界（"我承诺至少用 x.y.z"） | `pubspec.yaml` 的约束 | 命令写 | 抬高后团队/CI 必须重解析；写坏 YAML 会毁掉项目注释 |
| 更换实际解析版本 | `pubspec.lock` | `pub get` / `pub upgrade` | 只改 lock 不改下界 → 下一个人 `pub get` 又回到旧版本 |
| 跨 major（8.x → 9.x） | 约束 + 业务代码 | 人 + 迁移文档 | w_tools 的 major 都是 breaking（ui 7→8、form 5→6），自动跨 = 静默破坏 |

ureward 的实际缺口在第 1、3 行：约束下界是 `^8.0.1`，锁是 8.0.1，pub 上是 8.1.0。
它现在**没有**跨 major 风险（最新都还在同 major 内），但 `w_tools_ui 8.1.0` 与 `8.0.1` 的
`environment` 都是 `sdk ^3.10.0 / flutter >=3.38.0`，说明「能不能装」与「装完能不能编译」是两件事，
命令至少要能核对 SDK 约束（§5）。

## 3. 实测：pub 已经能做多少

在本机（`PUB_HOSTED_URL=https://pub.flutter-io.cn`）与 `/tmp` 沙箱项目上验过：

| 试验 | 结果 |
| --- | --- |
| `dart pub upgrade --tighten`（单独用） | **不抬下界**：`pub_semver: ^2.0.0` 解析到 2.2.1 后 pubspec 仍是 `^2.0.0` |
| `dart pub upgrade --major-versions --tighten pub_semver` | 只改指名的包：`^2.0.0 -> ^2.2.1`，**行首注释与行尾注释都保留** |
| `dart pub outdated --json` | 需要完整解析（含 git 依赖）；本机 agent 沙箱里直接挂在 `~/.pub-cache/git/.../FETCH_HEAD`，拿不到 JSON |
| `dart pub upgrade --dry-run w_tools_core`（ureward） | 可用；在 Flutter 工程里 `dart pub` 不需要换成 `flutter pub` |
| `curl $PUB_HOSTED_URL/api/packages/w_tools_ui` | 返回 `latest.version` + `latest.pubspec.environment`；镜像与 pub.dev 的 latest 一致 |

由此定两条实现原则：

- **YAML 编辑与解析交给 pub，不要自己写**：`pub upgrade --major-versions --tighten <包...>`
  已经证明「只改指名包的版本 token、保留注释」；手写正则改 `^x.y.z` 会踩 `"^x.y.z"`、
  `>=x <y`、map 形式、缩进与行内注释。
- **「查最新」不要走 `pub outdated`**：它要求项目能完整解析（git 依赖 / 私有源 / 沙箱都可能是坑）。
  用 hosted API 只读查询，一条命令就能给出计划，且不依赖项目是否可解析。

## 4. 现状数据（ureward，2026-11-11）

| 包 | 声明 | lock | pub 最新 | 落后 |
| --- | --- | --- | --- | --- |
| `w_tools_core` | `^3.1.1` | 3.1.1 | 3.1.2 | 补丁 |
| `w_tools_ui` | `^8.0.1` | 8.0.1 | 8.1.0 | 次版本 |
| `w_tools_cli`（dev） | `^1.18.0` | 1.18.0 | 1.18.2 | 补丁 |
| `w_tools_figma`（dev） | `^0.13.1` | 0.13.1 | 0.13.2 | 补丁 |
| `w_tools_device`（dev） | `^0.3.1` | 0.3.1 | 0.3.2 | 补丁 |
| `w_tools_app_getx` / `form` / `async` / `api` / `toast` / `qr` / `e2e` | — | 同最新 | — | 否 |
| `w_tools_app`（transitive） | — | 3.1.1 | 3.1.1 | 否 |

另有 `.w_tools/init.json` 的 `"generator": "1.18.0"` 与生成物头部版本标记，落后于 lock 里的 1.18.2 之前版本。
这正是 doctor R8 管的东西：**抬完依赖不跑 `init`，R8 会红；跑旧版 CLI 的 `init` 又刷不出新内容**。

## 5. 建议的命令面

规范名 `upgrade`（对齐 `pub upgrade`，且不与 `init` 的语义混）。只处理 `w_tools` 与 `w_tools_*`，
其余依赖一概不碰（ureward 里 `retrofit: 4.9.0` 这种**刻意钉死 + 大段注释**的约束必须原样保留）。

```bash
dart run w_tools_cli:w_tools upgrade            # 抬到「同 major 最新」并安装，打印 diff
dart run w_tools_cli:w_tools upgrade --check    # 只读；有落后 exit 1（CI / AI 的 F-1）
dart run w_tools_cli:w_tools upgrade --dry-run  # 打印将要写的内容，不写
```

| 参数 | 语义 | 默认 |
| --- | --- | --- |
| `--check` | 只报告、不写、不跑 pub；有落后 exit 1 | 关 |
| `--dry-run` | 打印 pubspec 的目标 diff 与将要执行的 pub 命令 | 关 |
| `--major` / `--major=<包,包>` | 允许跨 major（0.x 包按 semver：跨 minor 也是 breaking） | 关；跨 major 的包只报告 |
| `--via-pub` | 交给 `pub upgrade --major-versions --tighten <包>` 执行（会让 pub 顺带重解析其他依赖） | 关（默认贴近最小 diff） |
| `--no-get` | 只改 pubspec，不跑 pub | 关 |
| `--hosted=<url>` | 覆盖 hosted 源（默认 `PUB_HOSTED_URL`，再退回 `https://pub.dev`） | — |
| `--format=json\|prompt` | 机器/ AI 输出（schema `w_tools_cli.upgrade/1`） | text |

退出码沿用全仓约定：`0` 成功（含「已是最新」）· `1` `--check` 发现有落后 · `2` 参数 / 项目错误
（无 pubspec、`resolution: workspace`、YAML 解析失败、`pub get` 解析冲突）· `3` hosted 不可达。

默认流程（写文件路径）：

1. 选包：`dependencies` + `dev_dependencies` 里 `name == 'w_tools' || name.startsWith('w_tools_')`
   且约束是字符串；`path` / `git` / `dependency_overrides` 里的包**跳过并说明原因**；
2. 查最新：`GET <hosted>/api/packages/<name>`，读 `latest.version`、`latest.pubspec.environment`（并发 + 超时）；
3. 分类：`up-to-date` / `patch|minor`（可自动）/ `major`（默认只报告）/ `sdk-blocked` / `skipped`；
4. 写 pubspec：只改被选中包的版本 token（`yaml_edit`；或整体委托 `--via-pub`）；
5. 安装：`flutter pub get`（`isFlutter` 时）或 `dart pub get`；失败 → 还原 pubspec、exit 2、贴 pub 原文；
6. 提示闭环：若 `w_tools_cli` 被抬了，打印
   `dart run w_tools_cli:w_tools init --force`（必须用**新** CLI 跑）与 `doctor --format=json`。

## 6. 必修的边界

1. **workspace / 仓库检出**：`resolution: workspace` 或本仓库自身，包版本来自本地，抬 pub 版本无意义 → exit 2。
2. **`dependency_overrides`**：override 里的 `w_tools*` 不参与抬版本（override 优先），但要 warn。
3. **0.x 的 caret**：`^0.13.1` 只允许 `<0.14.0`；`^0.3.1` 只允许 `<0.4.0`。跨 minor 按 breaking 处理，别让 `--major` 之外的路走到。
4. **pubspec 注释**：ureward 的 pubspec 里 30+ 行注释是事实源（为什么钉 `retrofit 4.9.0`、各包 major 的语义变化）。禁止整份 YAML 往返。
5. **SDK / Flutter 约束**：比对 `latest.pubspec.environment` 与本机 SDK；项目 `environment.sdk` 下界（ureward 是 `^3.5.4`）低于依赖要求时给 warning。
6. **镜像**：本机 `PUB_HOSTED_URL=https://pub.flutter-io.cn`；`pubspec.lock` 里的 `url` 字段是解析时的记录（ureward 里仍是 pub.dev），**不可作为当前源**。输出里打印实际用的 host。
7. **代理**：`dart:io` 的 `HttpClient` 默认不读 `HTTP(S)_PROXY`，必须 `HttpClient.findProxyFromEnvironment`；否则办公室网段下命令「无输出卡住」。
8. **自升级鸡生蛋**：命令由旧 CLI 执行，抬 `w_tools_cli` 后不能同一进程里再跑 `init`（会刷出旧模板）。
9. **幂等**：第二次运行必须 0 改动、exit 0；`--check` 在「lock 落后但下界已最新」时也要报。
10. **失败回滚**：`pub get` 失败不得留下半改的 pubspec；内存里保留原文，失败恢复。
11. **大存量漂移**：一次跨多个包时，输出按「可自动 / 需人工」分组，不要一条条刷屏。

## 7. 实现切分

```
packages/cli/lib/src/upgrade/
  plan.dart          # 纯函数：声明 + lock + latest → 计划（无 IO，可穷举测试）
  pubspec_edit.dart  # 纯函数：String + Map<包, 新版本> → String（保留注释）
  hosted.dart        # LatestFetcher 接口 + HTTP 实现（注入 http.Client）
  run.dart           # 编排：写文件、跑 pub、回滚、输出
packages/cli/bin/upgrade.dart   # 兼容入口（可选，按现有 bin 惯例）
```

依赖新增（都是纯 Dart，CI 的 `dart analyze` 就能过）：`pub_semver`（caret 语义，别手写 `^` 规则）、
`yaml_edit`（若走自建编辑）、`http`（可注入假 client，测试不联网）。

测试重点：
- 用 ureward 那份带注释的 pubspec 当 fixture：改 5 行，其余字节不变（golden diff）；
- `plan.dart` 的表驱动用例：0.x、跨 major、`^8.0.1 → 8.1.0`、`sdk-blocked`、path/git/override 跳过；
- 假 fetcher 返回镜像/滞后/404/超时；`--check` 的 exit 1 与幂等；
- 变异验证：删掉「跨 major 拦截」后 `--check` 必须变红（`scripts/mutate_guard.sh`）。

## 8. 文档与门禁（按 `AGENTS.md` 的「改动前先分类」）

新增命令 = 公开变化：抬 `w_tools_cli` minor + `CHANGELOG` 段；同步

- `docs/agents/cli.md`：命令选择表、关键边界、退出码；
- `packages/cli/README.md`：「命令怎么选」与「退出码」两张表；
- `packages/cli/templates/ai/consumer-prompts.md`：F-2 的第 1 步改成
  `dart run w_tools_cli:w_tools upgrade`（现文案是「手动改约束或用 `pub upgrade --major-versions`」），
  F-3 保留 `init --check-drift` 收尾；改完跑 `dart run tool/gen_templates.dart`；
- `packages/cli/templates/agents/{zh,en}/base.md` 的「生成物不要手改」附近加一条升级路由（受 `check_agents_routing.py` 锚点约束、`catalog/agent_budget.yaml` 预算约束）；
- `docs/conventions.md` §7 的「提交前自检」加一行 `upgrade --check`；
- `context` 的 `commands()` 加 `upgradeCheck`（`schema/context.v1.json` 的 `commands` 是
  `additionalProperties: string`，加键不需要 bump）；
- 跑 `python3 scripts/check_docs_facts.py`、`bash scripts/check_docs.sh`、`bash scripts/preflight.sh --package=cli`。

## 9. 明确不做

- 不接管非 `w_tools*` 依赖（`pub upgrade --major-versions` 已经够，且会动到刻意钉死的包）；
- 不解析 CHANGELOG 自动做迁移（迁移仍走 `docs/migrations/` + F-1/F-2）；
- 不把这条检查塞进 `doctor`（doctor 现在是纯文本、离线、每次 CI 都跑；加网络会毁掉这个性质）；
- 不做交互式确认（CLI 要能被 AI / CI 直接调用），危险动作靠 `--major` 白名单而不是 prompt。

## 10. 分阶段与验收

| 阶段 | 内容 | 验收 |
| --- | --- | --- |
| A | `upgrade --check`（只读 + `--format`） | ureward 上输出 5 行落后 + exit 1；断网 exit 3 |
| B | 写 pubspec + `pub get` + 回滚 | ureward 上 golden diff 只动 5 个版本 token，注释零改动 |
| C | `--major` 报告与白名单 | 造一个「latest 跨 major」的假 fetcher，默认不写、`--major` 才写 |
| D | 闭环与文档 | ureward 跑完后 `init --force` + `doctor` 0 error，R8 从红转绿 |

理想终态（ureward 上应得到的结果）：

```text
w_tools upgrade
  w_tools_core     ^3.1.1 -> ^3.1.2
  w_tools_ui       ^8.0.1 -> ^8.1.0
  w_tools_cli      ^1.18.0 -> ^1.18.2   (dev)
  w_tools_figma    ^0.13.1 -> ^0.13.2   (dev)
  w_tools_device   ^0.3.1 -> ^0.3.2     (dev)
  其余 7 个已是最新
运行 pub get … 完成
next: 用新版 CLI 刷新生成物
  dart run w_tools_cli:w_tools init --force
  dart run w_tools_cli:w_tools doctor --format=json
```


## 落地情况（2026-11-11）

已实现阶段 A + B（`w_tools_cli 1.19.0`）：

- `upgrade --check`（只读，exit 1）、`--dry-run`、默认写入 + `pub get` + 失败还原、
  `--major` / `--only` / `--strict` / `--hosted` / `--format=text|json|prompt`。
- 计划 / 编辑 / 报告三段是纯函数（`upgrade_plan.dart` / `pubspec_edit.dart` / `upgrade_report.dart`），
  网络与 pub 都是注入点（`LatestFetcher` / `PubRunner`），测试不联网、不跑 pub。
- **零新依赖**：没引入 `pub_semver` / `yaml_edit` / `http` —— caret 语义与 `environment.sdk` 只用窄解析
  （非 `^x.y.z` 一律 skipped 交人工），pubspec 用定点 token 替换（引号 / 行尾注释 / CRLF / 其它字节不变），
  hosted 查询用 `dart:io` 的 `HttpClient`（`findProxyFromEnvironment`）。
- `--via-pub` 没有实现：实测 `pub upgrade --tighten` 单独用不抬下界，`--major-versions` 又会跨 major，
  交给 pub 反而更难控；需要时用 `pub upgrade --major-versions --tighten <包>` 手工兜底。
- `upgrade` 的 hosted 源、`PUB_HOSTED_URL` / 镜像、workspace 拒绝、override / path / git 跳过、回滚都有测试覆盖；
  ureward 实测：`--check` 报 5 个落后并 exit 1，`--dry-run` 只差 5 行 token。
