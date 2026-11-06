# 公开 API 快照

每个文件是某个包在**已发布版本**上的公开 API 基线，用于 `scripts/check_public_api_diff.py`。
文件名是 `w_tools_<包>-<版本>.txt`，每个包只保留一条：最新发布版本。

- 正常由 `scripts/publish_package.sh` 在发布成功后写入，**必须提交**（否则基线漂移，
  且下次 `release_check --strict` 会因未跟踪文件失败）。
- 补基线 / 新包：从 pub.dev 归档（或首次发布前的当前版本）生成：

```bash
python3 scripts/check_public_api_diff.py \
  --snapshot-from /tmp/<pkg>-<version> \
  --package <pkg> --version <version>
```

`preflight` 按 `scripts/packages.manifest` 逐包比较，**缺基线直接失败**；删除 / 类型变化 /
可空性变化必须写进**当前 pubspec 版本**对应 CHANGELOG 段的 `### Breaking` / `### Removed`，
或 `docs/migrations/` 对应迁移。聚合包 `w_tools` 只 re-export，没有快照。
