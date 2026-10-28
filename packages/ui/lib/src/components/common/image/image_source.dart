import 'package:flutter/foundation.dart';

import '../../../utils/assets.dart';
import 'image_types.dart';

/// 图片来源。
///
/// 绿field 设计里 `WImage` 接收 [WImageSource]，不再用 `String data` 猜类型；
/// 需要字符串入口时用 [WImageSource.parse]。
sealed class WImageSource {
  const WImageSource();

  /// 来源类型
  WImageType get type;

  /// 调用方传入的原始值（未 trim / 未规范化）
  String get raw;

  /// 规范化后的值（URL / 路径 / 资源名 / Base64 串）
  String get value;

  /// 用于相等判断与诊断的 key
  String get key;

  /// 从字符串解析来源；猜不中时按 asset 处理。
  factory WImageSource.parse(String raw, {WImageType? type}) {
    final value = raw.trim();
    if (value.isEmpty) return WAssetImageSource(raw);
    final resolved = type ?? _detect(value);
    return switch (resolved) {
      WImageType.network => WNetworkImageSource(raw),
      WImageType.asset => WAssetImageSource(raw),
      WImageType.file => WFileImageSource(raw),
      WImageType.base64 => WBase64ImageSource(raw),
    };
  }

  /// 网络图片
  factory WImageSource.network(
    String url, {
    Map<String, String>? headers,
    String? cacheKey,
  }) =>
      WNetworkImageSource(url, headers: headers, cacheKey: cacheKey);

  /// 本地资源
  factory WImageSource.asset(
    String name, {
    String? package,
    bool prefix = false,
  }) =>
      WAssetImageSource(name, package: package, prefix: prefix);

  /// 本地文件
  factory WImageSource.file(String path) => WFileImageSource(path);

  /// Base64（可带 data: 前缀）
  factory WImageSource.base64(String data) => WBase64ImageSource(data);

  static WImageType _detect(String value) {
    final uri = Uri.tryParse(value);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    if ((scheme == 'http' || scheme == 'https') && (uri?.host.isNotEmpty ?? false)) {
      return WImageType.network;
    }
    if (scheme == 'file') return WImageType.file;
    if (value.startsWith('data:')) return WImageType.base64;
    if (value.startsWith('//')) return WImageType.network;
    return WImageType.asset;
  }

  static String _filePathOf(String value) {
    if (!value.startsWith('file:')) return value;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        // 非法 file URI（例如 Windows 盘符写法）退回字符串处理
      }
    }
    return value.replaceFirst(RegExp(r'^file://'), '');
  }

  static String _stripDataPrefix(String value) {
    if (!value.startsWith('data:')) return value;
    final comma = value.indexOf(',');
    return comma < 0 ? value : value.substring(comma + 1);
  }
}

/// 网络来源
final class WNetworkImageSource extends WImageSource {
  const WNetworkImageSource(this._url, {this.headers, this.cacheKey});

  final String _url;
  final Map<String, String>? headers;
  final String? cacheKey;

  @override
  WImageType get type => WImageType.network;

  @override
  String get raw => _url;

  @override
  String get value {
    final url = _url.trim();
    return url.startsWith('//') ? 'https:$url' : url;
  }

  @override
  String get key => 'network:$value#${cacheKey ?? ''}';

  @override
  bool operator ==(Object other) =>
      other is WNetworkImageSource &&
      other._url == _url &&
      other.cacheKey == cacheKey &&
      mapEquals(other.headers, headers);

  @override
  int get hashCode => Object.hash(
      _url,
      cacheKey,
      headers == null
          ? null
          : Object.hashAll(headers!.entries.map((e) => Object.hash(e.key, e.value))));
}

/// 本地资源
final class WAssetImageSource extends WImageSource {
  const WAssetImageSource(this.name, {this.package, this.prefix = false});

  final String name;
  final String? package;
  final bool prefix;

  @override
  WImageType get type => WImageType.asset;

  @override
  String get raw => name;

  @override
  String get value {
    final name = this.name.trim();
    return prefix ? '${WAssets.imagePath}$name' : name;
  }

  @override
  String get key => 'asset:${package ?? ''}:$value';

  @override
  bool operator ==(Object other) =>
      other is WAssetImageSource &&
      other.name == name &&
      other.package == package &&
      other.prefix == prefix;

  @override
  int get hashCode => Object.hash(name, package, prefix);
}

/// 本地文件
final class WFileImageSource extends WImageSource {
  const WFileImageSource(this.path);

  final String path;

  @override
  WImageType get type => WImageType.file;

  @override
  String get raw => path;

  @override
  String get value => WImageSource._filePathOf(path.trim());

  @override
  String get key => 'file:$value';

  @override
  bool operator ==(Object other) => other is WFileImageSource && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// Base64
final class WBase64ImageSource extends WImageSource {
  const WBase64ImageSource(this.data);

  final String data;

  @override
  WImageType get type => WImageType.base64;

  @override
  String get raw => data;

  @override
  String get value => WImageSource._stripDataPrefix(data.trim());

  @override
  String get key => 'base64:${value.hashCode}';

  @override
  bool operator ==(Object other) => other is WBase64ImageSource && other.data == data;

  @override
  int get hashCode => data.hashCode;
}
