# 公开 API 快照

每个文件是某个包在**已发布版本**上的公开 API 基线，用于 `scripts/check_public_api_diff.py`。
文件名是 `w_tools_<包>-<版本>.txt`；历史版本可以保留，脚本按版本号取**最新**的一条。
`cli` 在 `check_public_api_diff.py` 里登记为无 barrel（不适用），它的快照只为
`release_status.py` 的版本对齐而存在。

- 发布时 `scripts/publish_package.sh` 先把快照写到 `.w_tools/release-snapshots/`
  （gitignored，不会弄脏工作区，也不会挡住下一个包）；一批发完后运行
  `bash scripts/apply_snapshots.sh` 应用到这里，再提交 + PR。
- 这里的快照**必须提交**（否则基线漂移，且下次 `release_check --strict` 会因未跟踪文件失败）。
- 根包发布前，`release_check.sh --strict`（完整模式）会运行
  `release_status.py --quiet --check --require-tracked --require-local`：最新快照必须已被
  git 跟踪，且**根聚合包**的版本等于本地 pubspec（工具包 / 不聚合的包允许待发布）；
  `.w_tools/release-snapshots/` 还有未应用快照时，`publish_package.sh .` 会直接拒绝。
  untracked 快照会被 `reset --hard` / `clean` 丢掉（PR #8 实际发生过）。
- 补基线 / 新包：从 pub.dev 归档（或首次发布前的当前版本）生成：

```bash
python3 scripts/check_public_api_diff.py \
  --snapshot-from /tmp/<pkg>-<version> \
  --package <pkg> --version <version>
```

  `--snapshot-from` 必须指向**包目录本身**（含 `pubspec.yaml` 与 `lib/w_tools_<pkg>.dart`
  barrel），`--version` 必须等于该目录 pubspec 的版本；空目录 / 空 surface 会被拒绝，
  不会写出「只有 header」的空基线（空基线会让这个包的门禁永久空转）。

`preflight` 按 `scripts/packages.manifest` 逐包比较，**缺基线直接失败**；删除 / 类型变化 /
可空性变化必须写进**当前 pubspec 版本**对应 CHANGELOG 段的 `### Breaking` / `### Removed`，
或 `docs/migrations/` 对应迁移。聚合包 `w_tools` 只 re-export，没有快照。
