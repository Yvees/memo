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
    // 预置一些初始数据
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '保鲜膜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '保鲜袋',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '密实袋',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '厨房纸',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '肥皂',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '抹布',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '洗洁精',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '百洁布',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '洗发水',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '护发素',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '沐浴露',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '护手霜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '洗手液',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '洗衣液',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '防染巾',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '洗碗块',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '亮碟剂',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '软化盐',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '卷纸',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '湿厕纸',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '牙膏',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '牙刷',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '餐巾纸',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '湿纸巾',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '厨房手套',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '化妆棉',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '身体乳',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '沐浴球',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': 'KH7',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.home.value,
      'name': '马桶清洁剂',
      'status': ItemStatus.undone.value
    });

    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '鸡蛋',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '切片面包',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '小餐包',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '咖啡胶囊',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '盐',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '白糖',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '生抽',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '老抽',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '橄榄油',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '醋',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '孜然粉',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '芝麻',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '面条',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '茶叶',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '薯片',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '瓜子',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '花生',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.food.value,
      'name': '巧克力',
      'status': ItemStatus.undone.value
    });

    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '橙子',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '番茄',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '香蕉',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '苹果',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '梨',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '葡萄',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '草莓',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '芒果',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '猕猴桃',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '荔枝',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '菠萝',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '西瓜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '哈密瓜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '葱',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '姜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '洋葱',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '香菜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '青椒',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '土豆',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '胡萝卜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '黄瓜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '西兰花',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '芦笋',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '番茄',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '茄子',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '青菜',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.fruit.value,
      'name': '丝瓜',
      'status': ItemStatus.undone.value
    });

    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '童子鸡',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '鸡腿',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '鸡翅',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '鸡胗',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '鸡心',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '牛腱子',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '牛腩',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '五花肉',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '大排',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '猪蹄',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '小排',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '羊排',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '羊腿',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '三文鱼',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '虾',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '中卷',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.meat.value,
      'name': '蟹',
      'status': ItemStatus.undone.value
    });

    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '牛奶',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '酸奶',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '豆浆',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '可乐',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '橙汁',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '椰子水',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '啤酒',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.drink.value,
      'name': '红酒',
      'status': ItemStatus.undone.value
    });

    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '辅食',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '奶粉',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '尿不湿',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '奶瓶',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '奶嘴',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '口水巾',
      'status': ItemStatus.undone.value
    });
    await db.insert('item', {
      'type': ItemType.baby.value,
      'name': '湿巾',
      'status': ItemStatus.undone.value
    });
  }

  Future<int> insertItem(ItemEntry entry) async {
    Database db = await database;
    return await db.insert('item', entry.toMap());
  }

  Future<List<ItemEntry>> getItems() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('item', orderBy: 'type DESC');
    return List.generate(maps.length, (i) => ItemEntry.fromMap(maps[i]));
  }

  Future<List<ItemEntry>> getItemsByType(ItemType type) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('item',
        where: 'type = ?', whereArgs: [type.value], orderBy: 'status ASC');
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

  Future<void> resetAllItems(bool isDone) async {
    final db = await database;
    await db.update(
      'item',
      {'status': isDone ? 1 : 0},
      where: null, // 这将更新所有行
    );
  }
}
