# ui 4.4 迁移：布局糖 / `WHexColor` / String 扩展

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WRow` / `WColumn` | `Row` / `Column` | 5.0 移除；`WRow.min` 用 `Row(mainAxisSize: MainAxisSize.min)` |
| `WSizeBox.height(8)` / `.square(32)` | `SizedBox(height: 8)` / `8.verticalSpace` | 5.0 移除 |
| `WPadding.all(8)` | `Padding(padding: EdgeInsets.all(8))` | 5.0 移除 |
| `HexColor.fromHex(...)` | `WHexColor.fromHex(...)` | 扩展改名（无别名，需同步替换） |
| `WStringExtension` + `WUiStringExtension` | `WStringExtension`（已合并） | 成员不变，只是不再分两个扩展 |

`'#RRGGBB'.toColor()` 保持不变，内部改走 `WHexColor`。
