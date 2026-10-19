import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_entry.dart';
import '../services/data_source.dart';
import '../services/data_source_errors.dart';
import '../services/mysql_item_repository.dart';

/// 数据源配置：选择数据保存在本机还是远程 MySQL。
class DataSourcePage extends StatefulWidget {
  const DataSourcePage({super.key});

  @override
  DataSourcePageState createState() => DataSourcePageState();
}

class DataSourcePageState extends State<DataSourcePage> {
  late final DataSourceService _service;
  late DataSourceType _type;
  late final TextEditingController _urlController;
  bool _obscureUrl = true;
  bool _busy = false;

  /// 最近一次测试连接的结果，null 表示尚未测试
  String? _testMessage;
  bool _testSucceeded = false;

  @override
  void initState() {
    super.initState();
    _service = context.read<DataSourceService>();
    _type = _service.type;
    _urlController = TextEditingController(text: _service.remoteUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 测试连接，成功时返回服务器信息，失败时在页面上显示原因并返回 null
  Future<MySqlServerInfo?> _runTest() async {
    setState(() {
      _busy = true;
      _testMessage = null;
    });
    try {
      final info = await _service.testRemote(_urlController.text);
      _showTestResult(true,
          '连接成功：MySQL ${info.version}，表 ${MySqlItemRepository.defaultTableName} '
          '中现有 ${info.itemCount} 条数据');
      return info;
    } catch (e) {
      _showTestResult(false, '连接失败：${describeDataSourceError(e)}');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showTestResult(bool succeeded, String message) {
    if (!mounted) return;
    setState(() {
      _testSucceeded = succeeded;
      _testMessage = message;
    });
  }

  Future<void> _save() async {
    if (_type == DataSourceType.local) {
      await _service.useLocal();
    } else {
      // 保存前必须能连上，避免切换到一个无法使用的数据源
      final info = await _runTest();
      if (info == null) return;

      // 网络数据库为空时，询问是否把本机数据带过去
      var upload = <ItemEntry>[];
      if (info.itemCount == 0) {
        final localItems = await _service.local.getItems();
        if (localItems.isNotEmpty) {
          final choice = await _askUpload(localItems.length);
          if (choice == null) return; // 取消
          if (choice) upload = localItems;
        }
      }

      setState(() => _busy = true);
      try {
        await _service.useRemote(_urlController.text, upload: upload);
      } catch (e) {
        _showTestResult(false, '上传本机数据失败：${describeDataSourceError(e)}');
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到${_service.description}')),
    );
    Navigator.pop(context);
  }

  /// 返回 true 上传，false 不上传，null 取消保存
  Future<bool?> _askUpload(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传本机数据？'),
        content: Text('网络数据库中还没有数据。是否把本机的 $count 条数据上传到网络？\n'
            '不上传则从空清单开始；本机数据不会被删除，切回本机后仍可使用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('不上传'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('上传'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据源配置'),
        backgroundColor: Colors.lightGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioListTile<DataSourceType>(
            title: const Text('本机'),
            subtitle: const Text('数据保存在这台设备上（默认）'),
            value: DataSourceType.local,
            groupValue: _type,
            onChanged: _busy ? null : (v) => setState(() => _type = v!),
          ),
          RadioListTile<DataSourceType>(
            title: const Text('网络'),
            subtitle: const Text('数据保存在远程 MySQL 数据库，多台设备可共享同一份清单'),
            value: DataSourceType.remote,
            groupValue: _type,
            onChanged: _busy ? null : (v) => setState(() => _type = v!),
          ),
          if (_type == DataSourceType.remote) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              enabled: !_busy,
              obscureText: _obscureUrl,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'MySQL 连接串',
                hintText: MySqlConfig.example,
                helperText: '服务器未开启 SSL 时在末尾加 ?ssl=false；'
                    '用户名或密码含 @ : / 等字符时需 URL 编码（如 @ 写作 %40）',
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.lightGreen[50],
                suffixIcon: IconButton(
                  tooltip: _obscureUrl ? '显示' : '隐藏',
                  icon: Icon(
                      _obscureUrl ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureUrl = !_obscureUrl),
                ),
              ),
              // 修改连接串后之前的测试结果不再有效
              onChanged: (_) => setState(() => _testMessage = null),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _runTest,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: const Text('测试连接'),
              ),
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _testSucceeded ? Icons.check_circle : Icons.error,
                    color: _testSucceeded ? Colors.green : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_testMessage!)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '提示：连接信息（含密码）以明文保存在本机 App 的私有存储中。'
              '建议为本应用单独创建一个只拥有该数据库权限的 MySQL 账号。',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: _busy ? null : _save,
              child: const Text('保存', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
