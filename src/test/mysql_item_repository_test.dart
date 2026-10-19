// 连接真实 MySQL 的集成测试。需设置环境变量 MEMO_TEST_MYSQL_URL，例如：
//   MEMO_TEST_MYSQL_URL=mysql://用户名:密码@主机:3306/数据库名 flutter test
// 未设置时跳过。测试使用独立的 memo_item_test 表，结束后删除，不影响 memo_item 中的数据。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/services/mysql_item_repository.dart';
import 'package:mysql_client/mysql_client.dart';

void main() {
  final url = Platform.environment['MEMO_TEST_MYSQL_URL'];
  const table = 'memo_item_test';
  late MySqlItemRepository repo;

  setUpAll(() async {
    if (url == null) return;
    final config = MySqlConfig.parse(url);
    // 清理上次可能残留的测试表
    final conn = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.user,
      password: config.password,
      databaseName: config.database,
      secure: config.ssl,
    );
    await conn.connect();
    await conn.execute('DROP TABLE IF EXISTS $table');
    repo = MySqlItemRepository(config, tableName: table);
    addTearDown(() async {
      await repo.close();
      await conn.execute('DROP TABLE IF EXISTS $table');
      await conn.close();
    });
  });

  group('MySqlItemRepository', skip: url == null ? '未设置 MEMO_TEST_MYSQL_URL' : null,
      () {
    test('测试连接时自动建表并返回版本和条数', () async {
      final info = await repo.testConnection();
      expect(info.version, isNotEmpty);
      expect(info.itemCount, 0);
    });

    test('增删改查与重置', () async {
      final id = await repo.insertItem(
          ItemEntry(type: ItemType.fruit, name: '苹果 "测试" \'引号\''));
      expect(id, greaterThan(0));

      var fruits = await repo.getItemsByType(ItemType.fruit);
      expect(fruits.single.name, '苹果 "测试" \'引号\'');
      expect(fruits.single.status, ItemStatus.undone);

      final item = fruits.single..status = ItemStatus.done;
      expect(await repo.updateItem(item), 1);
      fruits = await repo.getItemsByType(ItemType.fruit);
      expect(fruits.single.status, ItemStatus.done);

      await repo.resetAllItems(false);
      fruits = await repo.getItemsByType(ItemType.fruit);
      expect(fruits.single.status, ItemStatus.undone);

      expect(await repo.deleteItem(id), 1);
      expect(await repo.getItems(), isEmpty);
    });

    test('批量导入并按状态排序', () async {
      await repo.importItems([
        ItemEntry(type: ItemType.food, name: '面包', status: ItemStatus.done),
        ItemEntry(type: ItemType.food, name: '鸡蛋'),
        ItemEntry(type: ItemType.drink, name: '牛奶'),
      ]);
      final food = await repo.getItemsByType(ItemType.food);
      expect(food.map((e) => e.name), ['鸡蛋', '面包']);
      expect((await repo.testConnection()).itemCount, 3);
    });

    test('并发请求会排队执行', () async {
      final results = await Future.wait(
          List.generate(10, (_) => repo.getItemsByType(ItemType.food)));
      expect(results.every((r) => r.length == 2), isTrue);
    });
  });
}
