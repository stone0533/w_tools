# Toast 模块文档

## 概述

Toast 模块（`w_tools_toast` 子包）基于 `bot_toast` 提供轻量的提示层，包含底层封装类 `WToast` 和上层配置+入口类 `WToastConfig`。

模块将提示分为三类：**全屏遮罩类**（成功 / 错误 / 警告 / 加载 / 自定义）、**纯文本气泡类**（无遮罩、可跨页面）、**全局清理**。所有入口在显示失败时（例如 BotToast 未初始化）都**不会抛异常**：显示类入口通过 `onError` 上报并返回一个空取消函数 `() {}`，调用方无需判空。

依赖：`bot_toast`。

## 模块结构

```
toast/
└── lib/src/
    ├── toast.dart           # WToast 底层封装
    └── toast_config.dart    # WToastConfig 配置与调用入口
```

---

## 1. WToast - 底层封装静态类

### 功能说明

直接对 `BotToast` 的薄封装，将所有失败路径收敛到 `onError` 回调。业务方通常不直接调用 `WToast`，而是通过 `WToastConfig` 的入口方法间接触达。

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

## 2. WToastConfig - 配置类 + 调用入口

### 功能说明

持有一组可复用的样式配置（时长、对齐、背景色、自定义 builder 等），并提供六个入口方法（`showSuccess` / `showError` / `showWarning` / `showLoading` / `showText` / `showCustom`）。所有字段均可通过 `copy()` / `copyWith()` 生成副本。

加载提示为**全局唯一**（跨 `WToastConfig` 实例共享同一个 `static CancelFunc? _loadingCancelFunc`）：再次 `showLoading` 会先关闭上一个，且不会自动关闭。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `duration` | `Duration(seconds: 2)` | 提示显示时长（加载提示固定不自动关闭，不受此值影响） |
| `backgroundColor` | `Colors.black38` | 成功/错误/警告/加载/自定义中作为**全屏遮罩色**；`showText` 中没有遮罩，该值作为**文本气泡底色** |
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

### 入口方法

| 方法 | 说明 |
|------|------|
| `showSuccess(message, {duration, align})` | 成功提示。全屏遮罩 + 默认白字 14 号文本（或 `successBuilder` 自定义），自动关闭。返回 `CancelFunc` |
| `showError(message, {duration, align})` | 错误提示。行为同 `showSuccess` |
| `showWarning(message, {duration, align})` | 警告提示。行为同 `showSuccess` |
| `showText(text, {duration, align})` | 纯文本气泡模式。**无遮罩**，默认位置屏幕下方，`backgroundColor` 作为气泡底色，自动关闭。返回 `CancelFunc` |
| `showCustom({duration, align})` | 自定义提示。需先设置 `toastBuilder`，否则抛 `ArgumentError`。返回 `CancelFunc` |
| `showLoading({message, dismissible=false})` | 全局唯一加载提示。调用前先关闭上一个，不自动关闭。返回 `CancelFunc` |
| `hideLoading()` | 关闭全局 loading（跨实例共享） |
| `hideAll()` | 关闭全部提示 + 清理全局 loading 状态 |

### duration / align 优先级

- `duration`：调用参数 > `WToastConfig.duration` > 2 秒
- `align`：调用参数 > `WToastConfig.align` > 居中

### 默认样式

| 场景 | 默认 UI |
|------|---------|
| 成功 / 错误 / 警告 | 全屏遮罩（`backgroundColor`）+ 白色 `CircularProgressIndicator` + 白字 14 号（`Padding(16, 10)`） |
| 加载 | 全屏遮罩 + 白色转圈（20x20, strokeWidth=2）+ 可选白字 14 号（`Padding(16)`） |
| 自定义 | 由 `toastBuilder` 决定 |

### 使用示例

```dart
// 基础用法（默认配置）
final toast = WToastConfig();
toast.showSuccess('保存成功');
toast.showError('网络异常，请重试');
toast.showWarning('当前为只读模式');
toast.showText('已复制到剪贴板');

// 全局 loading
final loading = toast.showLoading(message: '加载中...');
// ... 业务逻辑
loading(); // 或 toast.hideLoading()

// 自定义样式副本
final primaryToast = toast.copyWith(
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
primaryToast.showSuccess('操作成功');

// 自定义提示（需先设置 toastBuilder）
final customToast = toast.copyWith(
  toastBuilder: (cancelFunc) {
    return GestureDetector(
      onTap: cancelFunc,
      child: const Center(child: Text('点击关闭')),
    );
  },
);
customToast.showCustom();

// 一次性清理全部
toast.hideAll();
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
  // 页面级共享配置
  final WToastConfig toast = WToastConfig();

  Future<void> _save() async {
    final cancel = toast.showLoading(message: '保存中...');
    try {
      await api.save();
      cancel();
      toast.showSuccess('保存成功');
    } catch (e) {
      cancel();
      toast.showError('保存失败: $e');
    }
  }

  void _copy() {
    toast.showText('已复制');
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
- **加载提示全局唯一**：所有 `WToastConfig` 实例共享同一个 loading 状态。再次调用 `showLoading` 会先关闭上一个，切换页面或组件销毁时 loading 仍会保留（除非显式 `hideLoading` / `hideAll`）。
- **全屏遮罩 vs 文本气泡**：`backgroundColor` 在两类提示中含义不同——遮罩类用作全屏底色，气泡类用作气泡底色（且无遮罩）。
- **`onClose` 延迟回调**：全屏遮罩类（成功/错误/警告/加载/自定义）的 `onClose` 会延迟 1ms 执行，避免在组件树销毁期间 `setState`。文本提示的 `onClose` 由 BotToast 直接回调，无延迟。
- **`_guardBuilder` 兜底**：`WToast.showCustomDialog` 的 `toastBuilder` 在 build 阶段执行，其异常由内部 `_guardBuilder` 兜底上报 `onError`，不会逃逸出 try-catch。
- **`showCustom` 必须先设置 `toastBuilder`**：未设置时会抛 `ArgumentError`，不走 `onError` 兜底。
- **`WToast.hideAll` vs `cancelFunc()`**：前者一次性清理所有提示且不播放关闭动画；后者只关闭单个提示。调用 `hideAll` 后 `_loadingCancelFunc` 会被置为 null。
