import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_entry.dart';
import '../services/data_source.dart';
import '../services/item_repository.dart';

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

  ItemRepository get _repository =>
      context.read<DataSourceService>().repository;

  void _loadItems() {
    _itemsFuture = _repository.getItemsByType(widget.type);
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

        // 前一半放左列、后一半放右列，两列放在同一个 ListView 中一起滚动
        final items = snapshot.data!;
        final left = items.sublist(0, (items.length + 1) ~/ 2);
        final right = items.sublist(left.length);
        return ListView.builder(
          itemCount: left.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(child: _buildTile(left[index])),
                Expanded(
                  child: index < right.length
                      ? _buildTile(right[index])
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTile(ItemEntry item) {
    return SwitchListTile(
      title: Text(item.name),
      value: item.status == ItemStatus.undone, // 未完成时开关打开
      onChanged: (bool value) => _toggleItem(item, value),
      activeTrackColor: Colors.lightGreen, // 未完成（开关打开）时中间区域的颜色
    );
  }

  Future<void> _toggleItem(ItemEntry item, bool undone) async {
    final previous = item.status;
    setState(() {
      item.status = undone ? ItemStatus.undone : ItemStatus.done;
    });
    try {
      await _repository.updateItem(item); // 更新数据库
    } catch (e) {
      // 写库失败时回滚界面状态，避免与数据库不一致
      if (!mounted) return;
      setState(() => item.status = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败：$e')),
      );
    }
  }
}
