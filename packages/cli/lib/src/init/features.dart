/// init 的能力组合。profile 只决定默认集合；CLI 参数可以再覆盖单项。
enum InitProfile { minimal, ui, api, full }

enum InitFeature { app, form, ui, api, toast, qr, map, asyncFeature }

/// feature 的 CLI 元数据；parser / help / 文档都从这里取。
class InitFeatureSpec {
  const InitFeatureSpec(this.feature, this.flag, this.label);

  final InitFeature feature;
  final String flag;
  final String label;
}

const initFeatureSpecs = <InitFeatureSpec>[
  InitFeatureSpec(InitFeature.app, 'app', '导出 w_tools_app'),
  InitFeatureSpec(InitFeature.form, 'form', '导出 w_tools_form'),
  InitFeatureSpec(InitFeature.ui, 'ui', '导出 w_tools_ui 与页面规范'),
  InitFeatureSpec(InitFeature.api, 'api', '导出 w_tools_api'),
  InitFeatureSpec(InitFeature.toast, 'toast', '导出 w_tools_toast'),
  InitFeatureSpec(InitFeature.qr, 'qr', '导出 w_tools_qr'),
  InitFeatureSpec(InitFeature.map, 'map', '导出 w_tools_map（原生依赖）'),
  InitFeatureSpec(InitFeature.asyncFeature, 'async', '导出 w_tools_async'),
];

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
    this.asyncFeature = false,
  });

  final bool core;
  final bool app;
  final bool form;
  final bool ui;
  final bool api;
  final bool toast;
  final bool qr;
  final bool map;
  final bool asyncFeature;

  List<String> get enabled => <String>[
    if (core) 'core',
    if (app) 'app',
    if (form) 'form',
    if (ui) 'ui',
    if (api) 'api',
    if (toast) 'toast',
    if (qr) 'qr',
    if (map) 'map',
    if (asyncFeature) 'async',
  ];

  String get summary => enabled.join(', ');

  static const full = InitFeatures(
    app: true,
    form: true,
    ui: true,
    api: true,
    toast: true,
    qr: true,
    asyncFeature: true,
  );

  factory InitFeatures.forProfile(InitProfile profile) {
    return switch (profile) {
      InitProfile.minimal => const InitFeatures(),
      InitProfile.ui => const InitFeatures(ui: true, toast: true),
      InitProfile.api => const InitFeatures(api: true),
      InitProfile.full => full,
    };
  }

  bool isEnabled(InitFeature feature) => switch (feature) {
    InitFeature.app => app,
    InitFeature.form => form,
    InitFeature.ui => ui,
    InitFeature.api => api,
    InitFeature.toast => toast,
    InitFeature.qr => qr,
    InitFeature.map => map,
    InitFeature.asyncFeature => asyncFeature,
  };

  InitFeatures withFeature(InitFeature feature, bool value) => switch (feature) {
    InitFeature.app => copyWith(app: value),
    InitFeature.form => copyWith(form: value),
    InitFeature.ui => copyWith(ui: value),
    InitFeature.api => copyWith(api: value),
    InitFeature.toast => copyWith(toast: value),
    InitFeature.qr => copyWith(qr: value),
    InitFeature.map => copyWith(map: value),
    InitFeature.asyncFeature => copyWith(asyncFeature: value),
  };

  InitFeatures copyWith({
    bool? core,
    bool? app,
    bool? form,
    bool? ui,
    bool? api,
    bool? toast,
    bool? qr,
    bool? map,
    bool? asyncFeature,
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
      asyncFeature: asyncFeature ?? this.asyncFeature,
    );
  }
}
