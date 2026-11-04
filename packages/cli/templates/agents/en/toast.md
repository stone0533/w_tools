- **Setup**: `MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`;
  without it every toast fails silently.
- **Light feedback**: use `WToast.showSuccess/showError/showWarning/showText`; use Flutter
  `showDialog` for confirmations.
- **Loading**: use `WToast.runWithLoading`; do not hand-roll an overlay.
