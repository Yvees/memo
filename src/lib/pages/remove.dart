import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_entry.dart';
import '../services/data_source.dart';
import '../services/item_repository.dart';

class RemovePage extends StatefulWidget {
  const RemovePage({super.key});

  @override
  RemovePageState createState() => RemovePageState();
}

class RemovePageState extends State<RemovePage> {
  late final ItemRepository _repository;
  late Future<List<ItemEntry>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _repository = context.read<DataSourceService>().repository;
    _itemsFuture = _loadItems();
  }

  Future<List<ItemEntry>> _loadItems() async {
    final items = await _repository.getItems();
    items.sort((a, b) => a.type.index.compareTo(b.type.index));
    return items;
  }

  Future<void> _removeItem(ItemEntry item) async {
    await _repository.deleteItem(item.id!);
    setState(() {
      _itemsFuture = _loadItems();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('项目 "${item.name}" 已删除')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('删除项目'),
        backgroundColor: Colors.lightGreen,
      ),
      body: FutureBuilder<List<ItemEntry>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有项目'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.lightGreen[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.type.label,
                          style: TextStyle(color: Colors.lightGreen[700]),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.lightGreen),
                    onPressed: () => _removeItem(item),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
