import 'package:flutter/material.dart';

const Object _unset = Object();

/// Playground 的不可变控件快照。
@immutable
class PlaygroundConfig {
  const PlaygroundConfig({
    this.isNetwork = false,
    this.width = 320,
    this.height = 180,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.memCache = 240,
    this.radius = 12,
    this.retryCount = 0,
    this.customPlaceholder = true,
    this.withBorder = false,
    this.withShadow = false,
    this.withMargin = false,
  });

  final bool isNetwork;
  final double width;
  final double height;
  final double? aspectRatio;
  final BoxFit fit;
  final int? memCache;
  final double radius;
  final int retryCount;
  final bool customPlaceholder;
  final bool withBorder;
  final bool withShadow;
  final bool withMargin;

  PlaygroundConfig copyWith({
    bool? isNetwork,
    double? width,
    double? height,
    Object? aspectRatio = _unset,
    BoxFit? fit,
    Object? memCache = _unset,
    double? radius,
    int? retryCount,
    bool? customPlaceholder,
    bool? withBorder,
    bool? withShadow,
    bool? withMargin,
  }) {
    return PlaygroundConfig(
      isNetwork: isNetwork ?? this.isNetwork,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: identical(aspectRatio, _unset) ? this.aspectRatio : aspectRatio as double?,
      fit: fit ?? this.fit,
      memCache: identical(memCache, _unset) ? this.memCache : memCache as int?,
      radius: radius ?? this.radius,
      retryCount: retryCount ?? this.retryCount,
      customPlaceholder: customPlaceholder ?? this.customPlaceholder,
      withBorder: withBorder ?? this.withBorder,
      withShadow: withShadow ?? this.withShadow,
      withMargin: withMargin ?? this.withMargin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaygroundConfig &&
          other.isNetwork == isNetwork &&
          other.width == width &&
          other.height == height &&
          other.aspectRatio == aspectRatio &&
          other.fit == fit &&
          other.memCache == memCache &&
          other.radius == radius &&
          other.retryCount == retryCount &&
          other.customPlaceholder == customPlaceholder &&
          other.withBorder == withBorder &&
          other.withShadow == withShadow &&
          other.withMargin == withMargin;

  @override
  int get hashCode => Object.hash(
    isNetwork,
    width,
    height,
    aspectRatio,
    fit,
    memCache,
    radius,
    retryCount,
    customPlaceholder,
    withBorder,
    withShadow,
    withMargin,
  );
}
