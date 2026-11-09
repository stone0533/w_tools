- **Setup**: `MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`;
  without it every toast fails silently.
- **Light feedback**: use `WToast.showSuccess/showError/showWarning/showText`; use Flutter
  `showDialog` for confirmations.
- **Barrier hints**: for error cards / network errors use `WToast.showModal` (tap barrier to
  dismiss, blocks tap-through, 4s timeout fallback). Do not use `WToast.showCustomDialog` for
  hints — its defaults (`duration:null` + `clickClose:false` + `allowClick:true`) never close and
  let taps pass through.
- **Loading**: use `WToast.runWithLoading`; do not hand-roll an overlay.
- **Styling**: `WToastStyle` styles a single toast; `WToastTheme` provides the global theme;
  do not hardcode colors.
