import 'package:flutter/material.dart';

import '../models/item_entry.dart';
import '../widgets/item_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  ItemType _currentType = ItemType.home;

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
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 75, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'add',
                    child: const Text('添加项目'),
                    onTap: () {
                      Navigator.pushNamed(context, '/add');
                    },
                  ),
                  PopupMenuItem(
                    value: 'repeat',
                    child: const Text('移除项目'),
                    onTap: () {
                      Navigator.pushNamed(context, '/remove');
                    },
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: const Text('重置所有'),
                    onTap: () {
                      Navigator.pushNamed(context, '/reset');
                    },
                  ),
                ],
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: ItemListView(type: _currentType),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, ItemType type) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => setState(() => _currentType = type),
    );
  }
}
