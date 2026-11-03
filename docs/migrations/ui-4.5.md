# ui 4.5 迁移：屏幕信息 / 图片装饰顺序

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WScreen.screenWidth` 等静态 getter | `WScreen.of(context)` → `WScreenData` | 静态仍可用，但读的是平台 view；树内 `MediaQuery`（分屏/多窗口/测试）用 `of` |

行为修复（无需迁移，但视觉可能变化）：

- `WImageFrame`：`padding` 现在在装饰层内（内容与边框之间），`margin` 在最外，与 `Container` 语义一致；
  此前两者都在装饰层外，`padding` 实际等价于 `margin`。
- `WNetworkImageSource`：`hashCode` 改为与 `==` 一致的顺序无关（`headers` 顺序不再影响相等性）；
- 删除未导出的死代码 `WImageStyleIO.buildFile`。
