import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class ResetPage extends StatelessWidget {
  const ResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重置状态'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _resetAllItems(context, true),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('全部完成'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetAllItems(context, false),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('全部未完成'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllItems(BuildContext context, bool isDone) async {
    try {
      await DatabaseHelper().resetAllItems(isDone);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDone ? '所有项目已标记为完成' : '所有项目已标记为未完成')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$e')),
      );
    }
  }
}
