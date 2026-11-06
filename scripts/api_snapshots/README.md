# 公开 API 快照

每个文件是某个包在上一次发布版本上的公开 API 基线，用于 `scripts/check_public_api_diff.py`。

生成（不要手改）：

```bash
python3 scripts/check_public_api_diff.py \
  --snapshot-from /tmp/<pkg>-<version> \
  --package <pkg> --version <version>
```

`preflight` 会拿本地公开 API 与最新快照比较；删除 / 类型变化 / 可空性变化必须写进
当前版本 CHANGELOG 的 `### Breaking` / `### Removed`，或 `docs/migrations/` 对应迁移。
