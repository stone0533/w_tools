- **初始化**：`MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`；
  未初始化时所有提示会静默失败。
- **轻提示**：用 `WToast.showSuccess/showError/showWarning/showText`；确认框用 Flutter `showDialog`。
- **加载**：用 `WToast.runWithLoading`；不要手写遮罩。
- **样式**：单个提示的样式用 `WToastStyle`，全局主题用 `WToastTheme`；不要写死颜色。
