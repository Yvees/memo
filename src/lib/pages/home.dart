import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
      backgroundColor: Colors.lightGreen,
      // leading: Builder(
      //   builder: (BuildContext context) {
      //     return IconButton(
      //       icon: const Icon(Icons.menu, color: Colors.white),
      //       onPressed: () {
      //         Scaffold.of(context).openDrawer();
      //       },
      //     );
      //   },
      // ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_basket, color: Colors.white),
            onPressed: () => {},
          ),
          IconButton(
            icon: const Icon(Icons.fastfood, color: Colors.white),
            onPressed: () => {},
          ),
          IconButton(
            icon: const Icon(Icons.eco, color: Colors.white),
            onPressed: () => {},
          ),
          IconButton(
            icon: const Icon(Icons.dinner_dining, color: Colors.white),
            onPressed: () => {},
          ),
          IconButton(
            icon: const Icon(Icons.wine_bar, color: Colors.white),
            onPressed: () => {},
          ),
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
              ],
            );
          },
        ),
      ],
      centerTitle: true,
    ));
  }
}
