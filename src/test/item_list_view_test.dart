// 物品列表的界面测试：读取失败时显示原因与重试，下拉刷新。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/services/data_source.dart';
import 'package:memo/services/item_repository.dart';
import 'package:memo/widgets/item_list_view.dart';
import 'package:provider/provider.dart';

import 'data_source_page_test.dart' show MemoryConfigStore;

/// 按顺序返回预设结果：字符串列表表示物品名，异常表示读取失败
class ScriptedRepository implements ItemRepository {
  ScriptedRepository(this.results);

  final List<Object> results;
  int reads = 0;

  @override
  Future<List<ItemEntry>> getItemsByType(ItemType type) async {
    final result = results[reads < results.length ? reads : results.length - 1];
    reads++;
    if (result is Exception) throw result;
    return [
      for (final (i, name) in (result as List<String>).indexed)
        ItemEntry(id: i + 1, type: type, name: name),
    ];
  }

  @override
  Future<List<ItemEntry>> getItems() async => [];

  @override
  Future<int> insertItem(ItemEntry entry) async => 1;

  @override
  Future<int> deleteItem(int id) async => 1;

  @override
  Future<int> updateItem(ItemEntry entry) async => 1;

  @override
  Future<void> resetAllItems(bool isDone) async {}
}

void main() {
  const networkError = SocketException('Connection refused');

  Future<void> pumpList(WidgetTester tester, ItemRepository repo) async {
    final service = DataSourceService(local: repo, config: MemoryConfigStore());
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: service,
      child: const MaterialApp(
        home: Scaffold(body: ItemListView(type: ItemType.food)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
        find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
  }

  testWidgets('读取失败时显示中文原因和重试按钮，重试成功后显示数据', (tester) async {
    final repo = ScriptedRepository([
      networkError,
      ['鸡蛋']
    ]);
    await pumpList(tester, repo);
    expect(find.textContaining('读取数据失败：无法连接到服务器'), findsOneWidget);
    expect(find.text('鸡蛋'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(repo.reads, 2);
    expect(find.text('鸡蛋'), findsOneWidget);
  });

  testWidgets('下拉刷新读取最新数据', (tester) async {
    final repo = ScriptedRepository([
      ['鸡蛋'],
      ['鸡蛋', '面包']
    ]);
    await pumpList(tester, repo);
    expect(find.text('面包'), findsNothing);

    await pullToRefresh(tester);
    expect(repo.reads, 2);
    expect(find.text('面包'), findsOneWidget);
  });

  testWidgets('刷新失败时保留现有列表并提示', (tester) async {
    final repo = ScriptedRepository([
      ['鸡蛋'],
      networkError
    ]);
    await pumpList(tester, repo);

    await pullToRefresh(tester);
    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.textContaining('刷新失败：无法连接到服务器'), findsOneWidget);
  });

  testWidgets('空列表和错误状态也能下拉刷新', (tester) async {
    final repo = ScriptedRepository([
      <String>[],
      networkError,
      ['鸡蛋']
    ]);
    await pumpList(tester, repo);
    expect(find.text('没有数据'), findsOneWidget);

    await pullToRefresh(tester);
    expect(find.text('没有数据'), findsOneWidget); // 已有（空）数据，失败只提示

    await pullToRefresh(tester);
    expect(find.text('鸡蛋'), findsOneWidget);
  });
}
