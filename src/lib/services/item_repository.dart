import '../models/item_entry.dart';

/// 物品数据的读写接口。本机（SQLite）和网络（MySQL）数据源各有一个实现，
/// 页面只依赖这个接口，不关心数据实际存在哪里。
abstract class ItemRepository {
  Future<List<ItemEntry>> getItems();

  Future<List<ItemEntry>> getItemsByType(ItemType type);

  Future<int> insertItem(ItemEntry entry);

  Future<int> deleteItem(int id);

  Future<int> updateItem(ItemEntry entry);

  Future<void> resetAllItems(bool isDone);
}
