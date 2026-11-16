/// w_tools_qr 的内部实现库。
///
/// `WQrController` 与 `WQrView` 之间需要互相调用私有接线（平台视图挂载 /
/// 重扫回调），因此放在同一个 library 里：接线不进入公开 API。
/// 对外入口只有 barrel 导出的 `WQrController` / `WQrView`。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import 'qr_overlay_style.dart';
import 'qr_scan_result.dart';

part 'qr_controller.dart';
part 'qr_view.dart';
