import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../print/shopping_list_layout.dart';
import '../print/shopping_list_renderer.dart';
import '../services/data_source.dart';
import '../services/data_source_errors.dart';
import '../services/page_printer.dart';

/// 打印清单：预览需要购买的物品（按分类排在 A4 纸上），确认后交给系统打印。
class PrintPage extends StatefulWidget {
  const PrintPage({super.key, this.printer});

  /// 打印实现，默认使用安卓系统打印；测试时可替换
  final PagePrinter? printer;

  @override
  PrintPageState createState() => PrintPageState();
}

class PrintPageState extends State<PrintPage> {
  ShoppingListLayout? _layout;
  List<Uint8List>? _pages;
  Object? _error;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final repository = context.read<DataSourceService>().repository;
    try {
      final layout = ShoppingListLayout.fromItems(await repository.getItems());
      final pages = await ShoppingListRenderer(layout).renderAll();
      if (!mounted) return;
      setState(() {
        _layout = layout;
        _pages = pages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _layout = null;
      _pages = null;
    });
    _prepare();
  }

  Future<void> _print() async {
    final now = DateTime.now();
    setState(() => _printing = true);
    try {
      await (widget.printer ?? SystemPagePrinter())
          .printPages('购物清单 ${now.year}-${now.month}-${now.day}', _pages!);
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        UnsupportedError(:final message) => message ?? '当前平台不支持打印',
        _ => e.toString().replaceFirst('Exception: ', ''),
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final canPrint = pages != null && pages.isNotEmpty && !_printing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('打印清单'),
        backgroundColor: Colors.lightGreen,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: canPrint ? _print : null,
            icon: const Icon(Icons.print),
            label: const Text('打印', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('读取数据失败：${describeDataSourceError(error)}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final layout = _layout;
    final pages = _pages;
    if (layout == null || pages == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在生成打印页面…'),
          ],
        ),
      );
    }

    if (pages.isEmpty) {
      return const Center(
        child: Text(
          '没有需要购买的项目\n在首页把要买的物品开关打开后再来打印',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '共 ${layout.itemCount} 项需要购买，'
            '${layout.categories.length} 个分类，A4 共 ${pages.length} 页',
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => Column(
              children: [
                // 页面预览，保持 A4 比例
                AspectRatio(
                  aspectRatio: PrintMetrics.pageWidth / PrintMetrics.pageHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Image.memory(pages[index], fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 4),
                Text('第 ${index + 1} 页',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
