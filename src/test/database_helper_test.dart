// 本机数据库测试，使用 sqflite FFI 在电脑上运行（Windows 上与 App 的桌面端实现相同）。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/services/database_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('从 v1 升级到 v2：保留原有物品并新增 config 表', () async {
    if (!Platform.isWindows) return; // DatabaseHelper 仅在 Windows 上走 FFI
    final path = join(await getDatabasesPath(), 'memo.db');
    await databaseFactoryFfi.deleteDatabase(path);

    // 构造一个 v1 数据库：只有 item 表和一条数据
    final v1 = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('CREATE TABLE item(id INTEGER NOT NULL PRIMARY KEY '
                'AUTOINCREMENT, type INTEGER NOT NULL DEFAULT 0, '
                'name TEXT NOT NULL, status INTEGER NOT NULL DEFAULT 0)');
            await db.insert('item', {'type': 1, 'name': '旧数据', 'status': 1});
          },
        ));
    await v1.close();

    final helper = DatabaseHelper();
    final items = await helper.getItems();
    expect(items.single.name, '旧数据');
    expect(items.single.status, ItemStatus.done);
    expect((await helper.database).getVersion(), completion(2));

    expect(await helper.getConfig('data_source'), isNull);
    await helper.setConfig('data_source', 'remote');
    await helper.setConfig('data_source', 'local');
    expect(await helper.getConfig('data_source'), 'local');

    await (await helper.database).close();
    await databaseFactoryFfi.deleteDatabase(path);
  });
}
