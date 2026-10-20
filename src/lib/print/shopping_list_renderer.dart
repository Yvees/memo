import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'shopping_list_layout.dart';

/// 把 [ShoppingListLayout] 的每一页画成 A4 比例的 PNG 图片。
///
/// 用 Flutter 引擎绘制文字，中文直接使用系统字体，无需在 App 中打包中文字体。
class ShoppingListRenderer {
  ShoppingListRenderer(this.layout,
      {DateTime? date, this.dpi = 200, this.fontFamily})
      : date = date ?? DateTime.now();

  final ShoppingListLayout layout;
  final DateTime date;
  final double dpi;

  /// 字体，默认 null 使用系统字体
  final String? fontFamily;

  double get _scale => dpi / 25.4; // 毫米 → 像素

  int get pixelWidth => (PrintMetrics.pageWidth * _scale).round();
  int get pixelHeight => (PrintMetrics.pageHeight * _scale).round();

  Future<List<Uint8List>> renderAll() async {
    return [
      for (var i = 0; i < layout.pages.length; i++) await renderPage(i),
    ];
  }

  Future<Uint8List> renderPage(int index) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_scale); // 之后都用毫米作单位绘制
    canvas.drawRect(
      const Rect.fromLTWH(
          0, 0, PrintMetrics.pageWidth, PrintMetrics.pageHeight),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    var y = PrintMetrics.margin;
    if (index == 0) {
      y = _paintHeader(canvas, y);
    }
    for (final block in layout.pages[index].blocks) {
      y = _paintBlock(canvas, block, y);
    }
    _paintFooter(canvas, index);

    final image =
        await recorder.endRecording().toImage(pixelWidth, pixelHeight);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static const _black = Color(0xFF000000);
  static const _grey = Color(0xFF666666);

  double _paintHeader(Canvas canvas, double top) {
    _text(canvas, '购物清单', PrintMetrics.margin, top,
        size: 8, weight: FontWeight.bold);
    _text(
      canvas,
      '${date.year}年${date.month}月${date.day}日  ·  共 ${layout.itemCount} 项',
      PrintMetrics.margin,
      top + 11,
      size: 4,
      color: _grey,
    );
    final lineY = top + PrintMetrics.headerHeight - 4;
    _line(canvas, lineY, 0.4);
    return top + PrintMetrics.headerHeight;
  }

  double _paintBlock(Canvas canvas, PrintBlock block, double top) {
    final title = '${block.type.label}（${block.categoryTotal} 项）'
        '${block.continued ? ' 续' : ''}';
    _text(canvas, title, PrintMetrics.margin, top + 2,
        size: 5, weight: FontWeight.bold);
    _line(canvas, top + PrintMetrics.categoryHeight - 1.5, 0.2);

    const columnWidth = PrintMetrics.contentWidth / PrintMetrics.columns;
    const box = 3.6;
    final boxPaint = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    for (var i = 0; i < block.names.length; i++) {
      final row = i ~/ PrintMetrics.columns;
      final column = i % PrintMetrics.columns;
      final x = PrintMetrics.margin + column * columnWidth;
      final rowTop =
          top + PrintMetrics.categoryHeight + row * PrintMetrics.rowHeight;
      // 打印出来可以手写打勾的方框
      canvas.drawRect(
        Rect.fromLTWH(
            x + 0.5, rowTop + (PrintMetrics.rowHeight - box) / 2, box, box),
        boxPaint,
      );
      _text(canvas, block.names[i], x + 6, rowTop + 1.8,
          size: 4.2, maxWidth: columnWidth - 7);
    }
    return top + block.height;
  }

  void _paintFooter(Canvas canvas, int index) {
    final painter = _painter('第 ${index + 1} / ${layout.pages.length} 页',
        size: 3.2, color: _grey);
    painter.paint(
      canvas,
      Offset((PrintMetrics.pageWidth - painter.width) / 2,
          PrintMetrics.pageHeight - PrintMetrics.margin - 4),
    );
  }

  void _line(Canvas canvas, double y, double width) {
    canvas.drawLine(
      Offset(PrintMetrics.margin, y),
      Offset(PrintMetrics.pageWidth - PrintMetrics.margin, y),
      Paint()
        ..color = _black
        ..strokeWidth = width,
    );
  }

  TextPainter _painter(String text,
      {required double size,
      FontWeight weight = FontWeight.normal,
      Color color = _black,
      double maxWidth = PrintMetrics.contentWidth}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
            fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…', // 名称过长时截断，避免挤进相邻一列
    )..layout(maxWidth: maxWidth);
  }

  void _text(Canvas canvas, String text, double x, double y,
      {required double size,
      FontWeight weight = FontWeight.normal,
      Color color = _black,
      double maxWidth = PrintMetrics.contentWidth}) {
    _painter(text, size: size, weight: weight, color: color, maxWidth: maxWidth)
        .paint(canvas, Offset(x, y));
  }
}
