import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_source.dart';
import '../services/data_source_errors.dart';

class ResetPage extends StatelessWidget {
  const ResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重置所有项目'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _resetAllItems(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('将所有项目标记为已完成'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _resetAllItems(context, false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('将所有项目标记为未完成'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetAllItems(BuildContext context, bool isDone) async {
    try {
      await context.read<DataSourceService>().repository.resetAllItems(isDone);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDone ? '所有项目已标记为完成' : '所有项目已标记为未完成')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：${describeDataSourceError(e)}')),
      );
    }
  }
}
