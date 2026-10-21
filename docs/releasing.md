# 发版流程（8 个子包 + 聚合包）

`w_tools` 是 8 个独立发布的子包 + 1 个聚合包。两边版本各自演进，所以「仓库里有什么」和
「pub.dev 上用户能装到什么」很容易分叉 —— 例如 `w_tools_map` 曾经是仓库 1.1.0、
pub.dev 1.0.0，聚合包用户拿不到 1.1.0 的地图改进。

下面这套流程把这种分叉变成可执行检查。

## 版本规则

- **子包**：各自独立发版，版本号写在 `packages/<pkg>/pubspec.yaml`。破坏性改动 → major；
  新能力 → minor；修 bug / 文档 → patch。`CHANGELOG.md` 必须有与 pubspec 版本**完全一致**的
  `## x.y.z` 段。
- **聚合包**：`w_tools` 按聚合层独立发版。它对各子包的 caret 约束必须**覆盖子包当前版本**，
  否则用户装聚合包时解析不到那个子包的新版本。
- **发布顺序**：先子包，后聚合包。聚合包约束抬高到新子包版本之后才能发。

## 发版步骤

1. 改子包 `version` + 写 `CHANGELOG.md`（`## x.y.z`）。
2. 需要聚合包跟上的，改根 `pubspec.yaml` 里对应的 `w_tools_<pkg>: ^x.y.z`。
3. 改根 `version` + 写根 `CHANGELOG.md`。
4. 本地预检（不要求工作区干净）：
   ```bash
   bash scripts/release_check.sh --package map
   ```
5. 提交（`pub publish` 只有在干净工作区才不会报 65）。
6. 干净工作区复核 + 发布预演：
   ```bash
   bash scripts/release_check.sh --strict --package map
   cd packages/map && flutter pub publish --dry-run
   ```
7. 发布子包：
   ```bash
   cd packages/map && flutter pub publish
   # 其余需要发布的子包同理
   ```
8. 需要聚合包跟上时，最后发聚合包：
   ```bash
   flutter pub publish
   ```
9. 发布后确认（这一步才会把「待发布」判成通过）：
   ```bash
   bash scripts/release_check.sh --package map --online
   # 发布多个包/聚合包时去掉 --package，做全量比对
   ```

> `--online` 在**发布前**跑必然报「待发布」，它只用于发布后核对线上版本；
> 发布前的门禁是第 4、6 步。

## 只发一个子包时

- 用 `--package <pkg>` 收窄检查范围：根包版本、其他子包的漂移都不再阻塞你。
- 但要确认根包对该子包的 caret 约束仍覆盖新版本（脚本在 `--package` 模式下也会检查这一条），
  否则聚合包用户装不到新版本。
- 已发布的聚合包不会自动升级依赖，需要一次新的聚合版本才会带上它。

## `scripts/release_check.sh` 检查项

| 检查 | 说明 |
|---|---|
| 包名 / `resolution: workspace` | 目录与包名一致，否则 pub workspace 解析异常 |
| 发布物料 | 每个包有 `README.md` / `CHANGELOG.md` / `LICENSE` |
| 版本 ↔ CHANGELOG | `## <pubspec version>` 必须存在（点号按字面匹配） |
| 根包约束 | 每个 `w_tools_<pkg>: ^x.y.z` 必须接受子包本地版本 |
| 根包版本 ↔ CHANGELOG | 同上 |
| README 版本声明 | 禁止出现「当前 `x.y.z`」这种会漂移的硬编码 |
| `## Unreleased` 条目 | 只提醒：说明有已记录但未发版的改动 |
| `--strict` | 已跟踪文件无未提交改动、无未跟踪文件 |
| `--online` | 与 pub.dev API 对比最新版本，指出待发布 / 落后 |
| `--package <pkg>` | 只检查指定子包；根包与其他子包不参与 |

## 常见坑

- **`pub publish --dry-run` 返回 65**：多半是工作区不干净。先提交再跑。
- **只发子包不发聚合包**：已发布过的聚合包不会自动更新依赖约束；想让它带上新子包必须发一次
  新的聚合版本。
- **忘记抬约束**：子包发了 1.1.0，但根包还写 `^1.0.0`，用户拿到的是 1.0.0。脚本会直接报错。
- **CHANGELOG 写成 `## v1.1.0`**：脚本按 `## 1.1.0` 精确匹配，不要带 `v`。
