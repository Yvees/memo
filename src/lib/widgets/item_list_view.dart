import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_entry.dart';
import '../services/data_source.dart';
import '../services/data_source_errors.dart';
import '../services/item_repository.dart';

class ItemListView extends StatefulWidget {
  final ItemType type;

  const ItemListView({super.key, required this.type});

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  /// 当前显示的物品，null 表示首次加载中
  List<ItemEntry>? _items;

  /// 首次加载失败的原因（已有数据时刷新失败只弹提示，不替换列表）
  Object? _error;

  /// 每次加载递增，用于丢弃快速切换类别后过期的加载结果
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(ItemListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _items = null;
      _error = null;
      _refresh();
    }
  }

  ItemRepository get _repository =>
      context.read<DataSourceService>().repository;

  /// 从数据源重新读取当前类别；下拉刷新、重试和首次加载都走这里
  Future<void> _refresh() async {
    final id = ++_loadId;
    try {
      final items = await _repository.getItemsByType(widget.type);
      if (!mounted || id != _loadId) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted || id != _loadId) return;
      if (_items == null) {
        setState(() => _error = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败：${describeDataSourceError(e)}')),
        );
      }
    }
  }

  void _retry() {
    setState(() => _error = null);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final error = _error;
    if (error != null) {
      return _scrollable(_buildError(error));
    }
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return _scrollable(const Text('没有数据'));
    }

    // 前一半放左列、后一半放右列，两列放在同一个 ListView 中一起滚动
    final left = items.sublist(0, (items.length + 1) ~/ 2);
    final right = items.sublist(left.length);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
  }

  /// 让空状态和错误状态也能下拉刷新：内容居中，外层可滚动
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  /// 读取失败（多见于网络数据源断网或服务器不可用）时显示原因和重试按钮
  Widget _buildError(Object error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '读取数据失败：${describeDataSourceError(error)}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
          const SizedBox(height: 8),
          Text(
            '也可以在右上角菜单的"数据源配置"中切换回本机',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        SnackBar(content: Text('更新失败：${describeDataSourceError(e)}')),
      );
    }
  }
}
