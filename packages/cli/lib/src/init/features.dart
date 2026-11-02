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
  InitFeatureSpec(InitFeature.qr, 'qr', '导出 w_tools_qr（默认 full 开）'),
  InitFeatureSpec(InitFeature.map, 'map', '导出 w_tools_map（默认关，原生依赖）'),
  InitFeatureSpec(InitFeature.asyncFeature, 'async', '导出 w_tools_async'),
];

class InitFeatures {
  const InitFeatures._(this._values);

  final Set<InitFeature> _values;

  bool get core => true;
  bool get app => _values.contains(InitFeature.app);
  bool get form => _values.contains(InitFeature.form);
  bool get ui => _values.contains(InitFeature.ui);
  bool get api => _values.contains(InitFeature.api);
  bool get toast => _values.contains(InitFeature.toast);
  bool get qr => _values.contains(InitFeature.qr);
  bool get map => _values.contains(InitFeature.map);
  bool get asyncFeature => _values.contains(InitFeature.asyncFeature);

  List<String> get enabled => <String>[
    'core',
    for (final spec in initFeatureSpecs)
      if (isEnabled(spec.feature)) spec.flag,
  ];

  String get summary => enabled.join(', ');

  Map<String, bool> toJson() => <String, bool>{
    'core': true,
    for (final spec in initFeatureSpecs) spec.flag: isEnabled(spec.feature),
  };

  static const full = InitFeatures._(<InitFeature>{
    InitFeature.app,
    InitFeature.form,
    InitFeature.ui,
    InitFeature.api,
    InitFeature.toast,
    InitFeature.qr,
    InitFeature.asyncFeature,
  });

  factory InitFeatures.forProfile(InitProfile profile) {
    return switch (profile) {
      InitProfile.minimal => const InitFeatures._(<InitFeature>{}),
      InitProfile.ui => const InitFeatures._(<InitFeature>{InitFeature.ui, InitFeature.toast}),
      InitProfile.api => const InitFeatures._(<InitFeature>{InitFeature.api}),
      InitProfile.full => full,
    };
  }

  bool isEnabled(InitFeature feature) => _values.contains(feature);

  InitFeatures withFeature(InitFeature feature, bool value) {
    final next = <InitFeature>{..._values};
    if (value) {
      next.add(feature);
    } else {
      next.remove(feature);
    }
    return InitFeatures._(next);
  }

  InitFeatures copyWith({
    bool? app,
    bool? form,
    bool? ui,
    bool? api,
    bool? toast,
    bool? qr,
    bool? map,
    bool? asyncFeature,
  }) {
    var next = this;
    final values = <InitFeature, bool?>{
      InitFeature.app: app,
      InitFeature.form: form,
      InitFeature.ui: ui,
      InitFeature.api: api,
      InitFeature.toast: toast,
      InitFeature.qr: qr,
      InitFeature.map: map,
      InitFeature.asyncFeature: asyncFeature,
    };
    for (final entry in values.entries) {
      if (entry.value != null) next = next.withFeature(entry.key, entry.value!);
    }
    return next;
  }
}
