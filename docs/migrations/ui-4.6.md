# ui 4.6 迁移：横向按钮行

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WRowButtons`（选中 + 滚动耦合） | `WActionRow`（无选中）/ `WSelectableRow`（单选高亮） | 旧类 5.0 移除 |
| `WRowButtonsController` | `WSelectableRow(selectedIndex, onSelected)`；滚动用可选 `scrollController` | 旧控制器 5.0 移除 |

`WActionRow` 只负责横向滚动与间距，点击语义由子项自己决定；
`WSelectableRow` 默认把选中项滚到视口中间（`scrollToSelected: true`）。
