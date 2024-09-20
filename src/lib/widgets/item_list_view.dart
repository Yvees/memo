import 'package:flutter/material.dart';
import '../models/item_entry.dart';
import '../services/database_helper.dart'; // 假设您有一个数据库服务

class ItemListView extends StatefulWidget {
  final ItemType type;

  const ItemListView({super.key, required this.type});

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  late Future<List<ItemEntry>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(ItemListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _loadItems();
    }
  }

  void _loadItems() {
    _itemsFuture = DatabaseHelper().getItemsByType(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemEntry>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('没有数据'));
        }

        final items = snapshot.data!;
        return Row(
          children: [
            Expanded(child: _buildColumn(items.sublist(0, items.length ~/ 2))),
            Expanded(child: _buildColumn(items.sublist(items.length ~/ 2))),
          ],
        );
      },
    );
  }

  Widget _buildColumn(List<ItemEntry> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SwitchListTile(
          title: Text(item.name),
          value: item.status == ItemStatus.undone, // 未完成时开关打开
          onChanged: (bool value) {
            setState(() {
              item.status = value ? ItemStatus.undone : ItemStatus.done;
              DatabaseHelper().updateItem(item); // 更新数据库
            });
          },
          activeColor: Colors.lightGreen, // 未完成（开关打开）时的颜色
          inactiveThumbColor: Colors.grey, // 已完成（开关关闭）时的颜色
        );
      },
    );
  }
}
