import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import '../models/item_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'memo.db');
    if (Platform.isWindows) {
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDb,
        ),
      );
    } else {
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
      );
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE item(
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertItem(ItemEntry entry) async {
    Database db = await database;
    return await db.insert('item', entry.toMap());
  }

  Future<List<ItemEntry>> getItems() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('item', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => ItemEntry.fromMap(maps[i]));
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'item',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItem(ItemEntry entry) async {
    final db = await database;
    return await db.update(
      'item',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }
}
