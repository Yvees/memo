// 打印清单页面的界面测试，用假的打印机，不调用系统打印。
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/pages/print.dart';
import 'package:memo/services/data_source.dart';
import 'package:memo/services/page_printer.dart';
import 'package:provider/provider.dart';

import 'data_source_page_test.dart' show FakeLocalRepository, MemoryConfigStore;

class FakePrinter implements PagePrinter {
  FakePrinter({this.error});

  final Object? error;
  String? jobName;
  List<Uint8List>? pages;

  @override
  Future<void> printPages(String jobName, List<Uint8List> pngPages) async {
    if (error != null) throw error!;
    this.jobName = jobName;
    pages = pngPages;
  }
}

void main() {
  Future<void> openPrintPage(
      WidgetTester tester, List<ItemEntry> items, PagePrinter printer) async {
    final service = DataSourceService(
        local: FakeLocalRepository(items), config: MemoryConfigStore());
    // 页面渲染图片需要真实的异步环境
    await tester.runAsync(() async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(home: PrintPage(printer: printer)),
      ));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
  }

  final items = [
    ItemEntry(id: 1, type: ItemType.food, name: '鸡蛋'),
    ItemEntry(id: 2, type: ItemType.food, name: '面包', status: ItemStatus.done),
    ItemEntry(id: 3, type: ItemType.drink, name: '牛奶'),
  ];

  testWidgets('显示需要购买的项数和页数预览，点击打印交给打印机', (tester) async {
    final printer = FakePrinter();
    await openPrintPage(tester, items, printer);

    expect(find.text('共 2 项需要购买，2 个分类，A4 共 1 页'), findsOneWidget);
    expect(find.text('第 1 页'), findsOneWidget);

    await tester.tap(find.text('打印'));
    await tester.pump();
    expect(printer.pages, hasLength(1));
    expect(printer.jobName, startsWith('购物清单 '));
  });

  testWidgets('没有需要购买的项目时提示且不能打印', (tester) async {
    final printer = FakePrinter();
    await openPrintPage(tester, [items[1]], printer);

    expect(find.textContaining('没有需要购买的项目'), findsOneWidget);
    await tester.tap(find.text('打印'));
    await tester.pump();
    expect(printer.pages, isNull);
  });

  testWidgets('打印失败时显示原因', (tester) async {
    await openPrintPage(
        tester, items, FakePrinter(error: UnsupportedError('打印目前仅支持安卓')));
    await tester.tap(find.text('打印'));
    await tester.pump();
    expect(find.text('打印目前仅支持安卓'), findsOneWidget);
  });
}
