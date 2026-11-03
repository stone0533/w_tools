# Toast 模块文档


> **默认样式跟随主题**：文本气泡取 `colorScheme.inverseSurface`、文字取
> `textTheme.bodyMedium` + `onInverseSurface`；`WToastStyle.backgroundColor` 默认 `null`
> （遮罩用中性半透明黑，气泡取主题反色）。深色主题下颜色自动反转。

## 概述

Toast 模块（`w_tools_toast` 子包）基于 `bot_toast` 提供轻量的提示层，入口是 `WToast` 的静态方法，样式是 `WToastStyle`（不可变）；旧 `WToastConfig` 已弃用（2.0 移除）。

模块将提示分为三类：**全屏遮罩类**（成功 / 错误 / 警告 / 加载 / 自定义）、**纯文本气泡类**（无遮罩、可跨页面）、**全局清理**。所有入口在显示失败时（例如 BotToast 未初始化）都**不会抛异常**：显示类入口通过 `onError` 上报并返回一个空取消函数 `() {}`，调用方无需判空。

依赖：`bot_toast`。

## 快速判断
- 轻提示 → `WToast`
- 不要在每个页面重复实现 Toast
- 页面内常驻提示用普通 Widget，不用 Toast
- 完整规则见根 [`AGENTS.md`](../../AGENTS.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```
toast/
└── lib/src/
    ├── toast.dart           # WToast 入口（静态方法）
    ├── toast_style.dart     # WToastStyle 样式（不可变）
    └── toast_config.dart    # 旧门面（弃用，2.0 移除）
```


---

## 1. WToast - 底层封装静态类

### 功能说明

对 `BotToast` 的薄封装，并把业务入口统一成静态方法（`showSuccess` / `showError` / `showWarning` / `showLoading` / `showCustom`），所有失败路径收敛到 `onError`。

### 核心方法

| 方法 | 说明 |
|------|------|
| `showCustomDialog({toastBuilder, align, onClose, duration, backgroundColor, animationDuration=200ms, onError})` | 全屏遮罩对话框。内部调用 `BotToast.showCustomLoading`，`toastBuilder` 在后续 build 阶段执行，由内部 `_guardBuilder` 兜底异常 |
| `showText({text, align, backgroundColor, contentColor, borderRadius, textStyle, contentPadding, duration, onClose, clickClose=false, crossPage=true, onlyOne=true, onError})` | 纯文本气泡提示，默认位置屏幕下方（`Alignment(0, 0.8)`） |
| `hideAll({onError})` | 立即清理全部提示（文本 / 加载 / 自定义），不播放关闭动画 |

### 返回值

- `showCustomDialog` / `showText` 返回 `CancelFunc`（即 `void Function()`），可用于手动关闭；即使显示失败也返回空函数 `() {}`。
- `hideAll` 无返回值。

### 行为说明

- `showCustomDialog` 的 `onClose` 回调会**延迟 1ms** 执行：BotToast 在移除提示的过程中同步触发 `onClose`，此时组件树仍处于销毁流程中，延后回调可避免用户在回调里执行 `setState` / 导航等操作时触发框架断言。
- `showCustomDialog` 的 `toastBuilder` 在 Flutter 的 build 阶段才执行，其抛出的异常不会被外层 `try-catch` 捕获，因此 `_guardBuilder` 会单独兜底：构建失败时上报 `onError` 并返回 `SizedBox.shrink()`。
- `showText` 的 `backgroundColor` 是**提示层背景色**（默认透明），`contentColor` 才是**气泡底色**（默认 `Colors.black54`）。

### 使用示例

```dart
// 自定义对话框
final cancel = WToast.showCustomDialog(
  toastBuilder: (cancelFunc) {
    return const Center(child: CircularProgressIndicator());
  },
  duration: const Duration(seconds: 3),
  onClose: () => print('关闭'),
  onError: (e) => debugPrint('错误: $e'),
);

// 纯文本气泡
final textCancel = WToast.showText(
  text: '操作成功',
  duration: const Duration(seconds: 2),
);

// 一次性清理全部
WToast.hideAll(onError: (e) => debugPrint('清理失败: $e'));
```

---

## 2. WToastStyle + WToast 静态入口

### 功能说明

`WToastStyle` 只描述样式（时长、对齐、背景色、自定义 builder），通过 `WToast.showSuccess(message, style: style)` 这类静态方法使用；需要复用一组样式时创建一个 `WToastStyle` 反复传入即可。所有字段不可变，用 `copyWith` 生成副本（传 `null` 可清空）。

加载提示为**全局唯一**（`WToast._loadingCancelFunc`）：再次 `WToast.showLoading` 会先关闭上一个，且不会自动关闭。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `duration` | `Duration(seconds: 2)` | 提示显示时长（加载提示固定不自动关闭，不受此值影响） |
| `backgroundColor` | `null`（主题派生） | 成功/错误/警告/加载/自定义中作为**全屏遮罩色**；`showText` 中没有遮罩，该值作为**文本气泡底色** |
| `align` | `Alignment.center` | 提示对齐方式（`showText` 仍使用 BotToast 默认的屏幕下方） |
| `animationDuration` | `Duration(milliseconds: 200)` | 进出场动画时长（`showText` 使用 BotToast 自带动画，不受此值影响） |
| `toastBuilder` | `null` | 自定义提示构建器，供 `showCustom` 使用；未设置时 `showCustom` 抛 `ArgumentError` |
| `onClose` | `null` | 提示关闭回调（自定义/加载提示延迟 1ms 回调，文本提示由 BotToast 直接回调） |
| `successBuilder` | `null` | 自定义成功提示 Widget 构建回调：`Widget Function(Object? message, CancelFunc cancelFunc)?` |
| `errorBuilder` | `null` | 自定义错误提示 Widget 构建回调 |
| `warningBuilder` | `null` | 自定义警告提示 Widget 构建回调 |
| `loadingBuilder` | `null` | 自定义加载提示 Widget 构建回调：`Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)?`。`dismissible` 仅供自定义 builder 使用，默认样式忽略 |
| `onError` | `null` | 提示显示失败回调（例如 BotToast 未初始化），签名 `void Function(dynamic error)?` |

### 副本方法

| 方法 | 说明 |
|------|------|
| `copy()` | 创建当前配置的副本（等同 `copyWith()`） |
| `copyWith({...})` | 创建副本并选择性更新属性；参数为 null 表示沿用原值 |

### 入口方法（WToast 静态）

| 方法 | 说明 |
|------|------|
| `WToast.showSuccess(message, {style, duration, align})` | 成功提示。全屏遮罩 + 默认主题文本（或 `style.successBuilder`），自动关闭。返回 `CancelFunc` |
| `WToast.showError(message, {style, duration, align})` | 错误提示。行为同 `showSuccess` |
| `WToast.showWarning(message, {style, duration, align})` | 警告提示。行为同 `showSuccess` |
| `WToast.showText(text, {...})` | 纯文本气泡模式（底层封装）。**无遮罩**，默认位置屏幕下方，`contentColor` 作为气泡底色 |
| `WToast.showCustom({style, duration, align, toastBuilder})` | 自定义提示。`style.toastBuilder` 与 `toastBuilder` 都为空时抛 `ArgumentError` |
| `WToast.showLoading({message, dismissible=false, style})` | 全局唯一加载提示。调用前先关闭上一个，不自动关闭 |
| `WToast.hideLoading()` | 关闭全局 loading |
| `WToast.hideAll()` | 关闭全部提示 + 清理全局 loading 状态 |

### duration / align 优先级

- `duration`：调用参数 > `style.duration` > 2 秒
- `align`：调用参数 > `style.align` > 居中

### 默认样式

| 场景 | 默认 UI |
|------|---------|
| 成功 / 错误 / 警告 | 全屏遮罩（`backgroundColor`）+ 主题 `bodyMedium` + `onInverseSurface`（`Padding(16, 10)`） |
| 加载 | 全屏遮罩 + 主题反色转圈（20x20, strokeWidth=2）+ 可选主题文本（`Padding(16)`） |
| 自定义 | 由 `toastBuilder` 决定 |

### 使用示例

```dart
// 基础用法（默认样式）
WToast.showSuccess('保存成功');
WToast.showError('网络异常，请重试');
WToast.showWarning('当前为只读模式');
WToast.showText(text: '已复制到剪贴板');

// 全局 loading
final loading = WToast.showLoading(message: '加载中...');
// ... 业务逻辑
loading(); // 或 WToast.hideLoading()

// 可复用的样式
final primaryStyle = WToastStyle.defaults.copyWith(
  backgroundColor: Colors.black54,
  duration: const Duration(seconds: 3),
  onError: (e) => debugPrint('Toast 错误: $e'),
  successBuilder: (message, cancelFunc) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(message?.toString() ?? '', style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  },
);
WToast.showSuccess('操作成功', style: primaryStyle);

// 自定义提示（style.toastBuilder）
final customStyle = WToastStyle.defaults.copyWith(
  toastBuilder: (cancelFunc) {
    return GestureDetector(
      onTap: cancelFunc,
      child: const Center(child: Text('点击关闭')),
    );
  },
);
WToast.showCustom(style: customStyle);

// 一次性清理全部
WToast.hideAll();
```

---

## 完整使用示例

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 页面级复用样式（可选）
  final WToastStyle style = WToastStyle.defaults.copyWith(
    duration: const Duration(seconds: 2),
  );

  Future<void> _save() async {
    final cancel = WToast.showLoading(message: '保存中...');
    try {
      await api.save();
      cancel();
      WToast.showSuccess('保存成功', style: style);
    } catch (e) {
      cancel();
      WToast.showError('保存失败: $e');
    }
  }

  void _copy() {
    WToast.showText(text: '已复制', duration: style.duration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(onPressed: _save, child: const Text('保存')),
          ElevatedButton(onPressed: _copy, child: const Text('复制')),
        ],
      ),
    );
  }
}
```

---

## 注意事项

- **BotToast 必须先初始化**：在应用入口调用 `BotToastInit()` + `MaterialApp.builder: botToastBuilder`，否则所有 Toast 入口都会通过 `onError` 上报并返回空函数。
- **加载提示全局唯一**：`WToast` 全局共享同一个 loading 状态。再次调用 `showLoading` 会先关闭上一个，切换页面或组件销毁时 loading 仍会保留（除非显式 `hideLoading` / `hideAll`）。
- **全屏遮罩 vs 文本气泡**：`backgroundColor` 在两类提示中含义不同——遮罩类用作全屏底色，气泡类用作气泡底色（且无遮罩）。
- **`onClose` 延迟回调**：全屏遮罩类（成功/错误/警告/加载/自定义）的 `onClose` 会延迟 1ms 执行，避免在组件树销毁期间 `setState`。文本提示的 `onClose` 由 BotToast 直接回调，无延迟。
- **`_guardBuilder` 兜底**：`WToast.showCustomDialog` 的 `toastBuilder` 在 build 阶段执行，其异常由内部 `_guardBuilder` 兜底上报 `onError`，不会逃逸出 try-catch。
- **`showCustom` 必须先设置 `toastBuilder`**：`style.toastBuilder` 与调用参数都为空时抛 `ArgumentError`，不走 `onError` 兜底。
- **`WToast.hideAll` vs `cancelFunc()`**：前者一次性清理所有提示且不播放关闭动画；后者只关闭单个提示。调用 `hideAll` 后 `_loadingCancelFunc` 会被置为 null。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
