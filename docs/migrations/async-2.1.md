> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 2.1 迁移：视图默认值收敛

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WAsyncViewDefaults` | `WAsyncTheme`（普通 builder） | 旧类弃用（3.0 移除），仍识别但优先级更低 |
| `WAsyncSliverDefaults` | `WAsyncTheme` 的 `sliver*Builder` | 同上 |

解析顺序：显式 builder > `WAsyncTheme` > 旧 defaults > 包内默认。
