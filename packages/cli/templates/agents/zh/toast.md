- **初始化**：`MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`；
  未初始化时所有提示会静默失败。
- **轻提示**：用 `WToast.showSuccess/showError/showWarning/showText`；确认框用 Flutter `showDialog`。
- **遮罩提示**：错误卡片 / 网络异常这类「看得见但不困住用户」的提示用 `WToast.showModal`
  （点遮罩关、拦截穿透、默认 4 秒兜底）；不要用 `WToast.showCustomDialog` 做提示 ——
  它的默认值 `duration:null` + `clickClose:false` + `allowClick:true` = 关不掉且点击穿透。
- **加载**：用 `WToast.runWithLoading`；不要手写遮罩。
- **样式**：单个提示的样式用 `WToastStyle`，全局主题用 `WToastTheme`；不要写死颜色。
