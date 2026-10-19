import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_entry.dart';
import '../services/data_source.dart';
import '../widgets/item_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  ItemType _currentType = ItemType.home;
  int _reloadToken = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(context, Icons.shopping_basket, ItemType.home),
            _buildIconButton(context, Icons.fastfood, ItemType.food),
            _buildIconButton(context, Icons.apple, ItemType.fruit),
            _buildIconButton(context, Icons.restaurant_menu, ItemType.meat),
            _buildIconButton(context, Icons.local_drink, ItemType.drink),
            _buildIconButton(
                context, Icons.baby_changing_station, ItemType.baby),
          ],
        ),
        actions: [
          // PopupMenuButton 会自动把菜单定位在按钮旁边
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: _openPage,
            itemBuilder: (context) => [
              const PopupMenuItem(value: '/add', child: Text('添加项目')),
              const PopupMenuItem(value: '/remove', child: Text('移除项目')),
              const PopupMenuItem(value: '/reset', child: Text('重置所有')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: '/datasource',
                child: Text(
                    '数据源配置（${context.read<DataSourceService>().type.label}）'),
              ),
            ],
          ),
        ],
        centerTitle: true,
      ),
      // 换 key 会重建列表，从而重新读取数据库
      body: ItemListView(key: ValueKey(_reloadToken), type: _currentType),
    );
  }

  Future<void> _openPage(String route) async {
    await Navigator.pushNamed(context, route);
    // 子页面可能增删改了数据，返回后刷新列表
    if (!mounted) return;
    setState(() => _reloadToken++);
  }

  Widget _buildIconButton(BuildContext context, IconData icon, ItemType type) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => setState(() => _currentType = type),
    );
  }
}
