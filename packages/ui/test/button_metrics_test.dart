import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  test('WButtonMetrics.fromStyle / applyTo 迁移布局字段', () {
    const style = WButtonStyle(
      padding: EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      minWidth: 80,
      minHeight: 40,
      tapTargetSize: 44,
      iconSize: 18,
      gap: 6,
    );
    final metrics = WButtonMetrics.fromStyle(style);
    expect(metrics.padding, const EdgeInsets.symmetric(horizontal: 20));
    expect(metrics.alignment, Alignment.centerLeft);
    expect(metrics.minWidth, 80);
    expect(metrics.minHeight, 40);
    expect(metrics.tapTargetSize, 44);
    expect(metrics.iconSize, 18);
    expect(metrics.gap, 6);

    final applied = metrics.applyTo(const WButtonStyle());
    expect(applied.padding, const EdgeInsets.symmetric(horizontal: 20));
    expect(applied.minWidth, 80);
    expect(applied.minHeight, 40);
    expect(applied.iconSize, 18);
    expect(applied.gap, 6);
  });

  test('WButtonStyle.metrics 暴露布局字段', () {
    const style = WButtonStyle(minWidth: 64);
    expect(style.metrics.minWidth, 64);
    expect(style.metrics, WButtonMetrics.fromStyle(style));
  });
}
