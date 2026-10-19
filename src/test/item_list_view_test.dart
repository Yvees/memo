// 物品列表的界面测试：读取失败时显示原因与重试。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/services/data_source.dart';
import 'package:memo/services/item_repository.dart';
import 'package:memo/widgets/item_list_view.dart';
import 'package:provider/provider.dart';

import 'data_source_page_test.dart' show MemoryConfigStore;

/// 前 [failures] 次读取抛出网络错误，之后正常返回
class FlakyRepository implements ItemRepository {
  FlakyRepository(this.failures);

  int failures;
  int reads = 0;

  @override
  Future<List<ItemEntry>> getItemsByType(ItemType type) async {
    reads++;
    if (failures > 0) {
      failures--;
      throw const SocketException('Connection refused');
    }
    return [ItemEntry(id: 1, type: type, name: '鸡蛋')];
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
  Future<void> pumpList(WidgetTester tester, ItemRepository repo) async {
    final service =
        DataSourceService(local: repo, config: MemoryConfigStore());
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: service,
      child: const MaterialApp(
        home: Scaffold(body: ItemListView(type: ItemType.food)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('读取失败时显示中文原因和重试按钮，重试成功后显示数据', (tester) async {
    final repo = FlakyRepository(1);
    await pumpList(tester, repo);
    expect(find.textContaining('读取数据失败：无法连接到服务器'), findsOneWidget);
    expect(find.text('鸡蛋'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(repo.reads, 2);
    expect(find.text('鸡蛋'), findsOneWidget);
  });
}
