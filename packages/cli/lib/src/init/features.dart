/// init 的能力组合。profile 只决定默认集合；CLI 参数可以再覆盖单项。
enum InitProfile { minimal, ui, api, full }

class InitFeatures {
  const InitFeatures({
    this.core = true,
    this.app = false,
    this.form = false,
    this.ui = false,
    this.api = false,
    this.toast = false,
    this.qr = false,
    this.map = false,
  });

  final bool core;
  final bool app;
  final bool form;
  final bool ui;
  final bool api;
  final bool toast;
  final bool qr;
  final bool map;

  List<String> get enabled => <String>[
    if (core) 'core',
    if (app) 'app',
    if (form) 'form',
    if (ui) 'ui',
    if (api) 'api',
    if (toast) 'toast',
    if (qr) 'qr',
    if (map) 'map',
  ];

  String get summary => enabled.join(', ');

  static const full = InitFeatures(
    app: true,
    form: true,
    ui: true,
    api: true,
    toast: true,
    qr: true,
  );

  factory InitFeatures.forProfile(InitProfile profile) {
    return switch (profile) {
      InitProfile.minimal => const InitFeatures(),
      InitProfile.ui => const InitFeatures(ui: true, toast: true),
      InitProfile.api => const InitFeatures(api: true),
      InitProfile.full => full,
    };
  }

  InitFeatures copyWith({
    bool? core,
    bool? app,
    bool? form,
    bool? ui,
    bool? api,
    bool? toast,
    bool? qr,
    bool? map,
  }) {
    return InitFeatures(
      core: core ?? this.core,
      app: app ?? this.app,
      form: form ?? this.form,
      ui: ui ?? this.ui,
      api: api ?? this.api,
      toast: toast ?? this.toast,
      qr: qr ?? this.qr,
      map: map ?? this.map,
    );
  }
}
