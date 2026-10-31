# UI 组件选择规则

高风险的组件选择先看这里；完整目录见 [`docs/modules/components.md`](../modules/components.md)。

## 图片

```text
网络图 / 资源图 → WImage
不要裸用 Image.network / Image.asset
```

`WImage` 负责缓存、占位、重试等网络图细节；普通图片也优先复用它，避免各页面重复处理加载态。

## 扩展方法

```text
数字格式化 → toThousandsSeparated / toCurrency / toPercent
hex 颜色 → HexColor.fromHex / '#rrggbb'.toColor()
间距 → num.heightBox / allPadding
BoxDecoration → withColor / withBorderRadius / withShadow
```

新增通用工具前先看 `packages/ui/lib/src/extensions/` 是否已有。

## 页面骨架

```text
普通页面 → WScaffold + WAppBar
底部 tab → WNavBar / WNavController
顶部 tab → WTabBar（依赖 TabController / DefaultTabController）
步骤流程 → WStep / WStepFlow
```

不要为了统一把任意叠放布局塞进 `WScaffold`；需要自定义覆盖时在页面层用 `Container` / `Stack`。

## 弹层

```text
锚定下拉 / 选择 → WFormPopup
底部面板 → WBottomSheet
确认弹窗 → Flutter showDialog（当前无统一 WDialog）
```

`WFormPopup` 是锚定式弹层，不是居中确认框。

## 图标 + 文字

当前没有统一的“图标和文字垂直居中一行”组件，不要直接用 `Row + Icon + Text` 当作稳定方案；中文行盒可能导致图标偏高。

## 轻提示

```text
轻提示 → WToast
```

不要在页面里重复实现 toast；需要页面内常驻提示时再用普通 Widget。

## 异步

异步四态、分页、刷新规则见根目录 `AGENTS.md` 的异步区块规则。

## 文字

文字、字号、行高规则见根目录 `AGENTS.md` 的文字规则；新代码使用 `WText` + `WTextStyles`。
