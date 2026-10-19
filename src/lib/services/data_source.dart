import 'package:flutter/foundation.dart';

import 'config_store.dart';
import 'item_repository.dart';
import 'mysql_item_repository.dart';

enum DataSourceType {
  local('本机'),
  remote('网络');

  final String label;
  const DataSourceType(this.label);
}

/// 管理当前使用的数据源，页面通过它拿到 [repository] 读写数据。
///
/// 数据源设置保存在本机的 [ConfigStore] 中：切回本机时仍保留上次填写的
/// 网络连接串，方便再次切换。
class DataSourceService extends ChangeNotifier {
  DataSourceService({
    required ItemRepository local,
    required ConfigStore config,
    MySqlItemRepository Function(MySqlConfig config)? remoteFactory,
  })  : _local = local,
        _config = config,
        _remoteFactory = remoteFactory ?? MySqlItemRepository.new;

  static const _keyType = 'data_source';
  static const _keyRemoteUrl = 'remote_url';

  final ItemRepository _local;
  final ConfigStore _config;
  final MySqlItemRepository Function(MySqlConfig config) _remoteFactory;

  DataSourceType _type = DataSourceType.local;
  String _remoteUrl = '';
  MySqlItemRepository? _remote;

  DataSourceType get type => _type;

  /// 上次保存的网络连接串（切回本机后仍保留）
  String get remoteUrl => _remoteUrl;

  ItemRepository get repository => _remote ?? _local;

  /// 本机数据源，用于把本机数据上传到网络等场景
  ItemRepository get local => _local;

  /// 当前数据源的说明，网络时附带地址（不含密码）
  String get description {
    final remote = _remote;
    return remote == null
        ? _type.label
        : '${_type.label}（${remote.config.displayName}）';
  }

  /// 启动时读取保存的设置。保存的连接串无法解析时退回本机。
  Future<void> load() async {
    _remoteUrl = await _config.getConfig(_keyRemoteUrl) ?? '';
    if (await _config.getConfig(_keyType) == DataSourceType.remote.name) {
      try {
        _remote = _remoteFactory(MySqlConfig.parse(_remoteUrl));
        _type = DataSourceType.remote;
      } on FormatException {
        _type = DataSourceType.local;
      }
    }
  }

  /// 用给定连接串测试连接，不改变当前数据源。
  Future<MySqlServerInfo> testRemote(String url) async {
    final repo = _remoteFactory(MySqlConfig.parse(url));
    try {
      return await repo.testConnection();
    } finally {
      await repo.close();
    }
  }

  Future<void> useLocal() async {
    await _config.setConfig(_keyType, DataSourceType.local.name);
    await _switchTo(DataSourceType.local, null);
  }

  /// 切换到网络数据源。调用前应先用 [testRemote] 确认可以连接。
  Future<void> useRemote(String url) async {
    final remote = _remoteFactory(MySqlConfig.parse(url));
    _remoteUrl = url.trim();
    await _config.setConfig(_keyRemoteUrl, _remoteUrl);
    await _config.setConfig(_keyType, DataSourceType.remote.name);
    await _switchTo(DataSourceType.remote, remote);
  }

  Future<void> _switchTo(
      DataSourceType type, MySqlItemRepository? remote) async {
    final old = _remote;
    _type = type;
    _remote = remote;
    notifyListeners();
    await old?.close();
  }

  @override
  void dispose() {
    _remote?.close();
    super.dispose();
  }
}
