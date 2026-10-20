import 'dart:io';

import 'package:flutter/services.dart';

/// 把渲染好的页面图片（PNG）送去打印。
abstract class PagePrinter {
  Future<void> printPages(String jobName, List<Uint8List> pngPages);
}

/// 通过安卓系统打印框架打印：弹出系统打印界面，由用户选择局域网中的打印机。
/// 原生实现见 android/app/src/main/kotlin/com/example/memo/PageImagePrinter.kt。
class SystemPagePrinter implements PagePrinter {
  static const _channel = MethodChannel('memo/print');

  @override
  Future<void> printPages(String jobName, List<Uint8List> pngPages) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('打印目前仅支持安卓');
    }
    try {
      await _channel.invokeMethod<void>('printPages', {
        'jobName': jobName,
        'pages': pngPages,
      });
    } on PlatformException catch (e) {
      throw Exception('无法启动打印：${e.message ?? e.code}');
    }
  }
}
