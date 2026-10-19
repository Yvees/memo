import 'dart:async';

import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';

import '../models/item_entry.dart';
import 'item_repository.dart';

/// 从连接串解析出的 MySQL 连接参数。
///
/// 连接串格式：`mysql://用户名:密码@主机[:端口]/数据库名[?ssl=false]`
/// - 端口默认 3306；
/// - 默认使用 SSL（MySQL 8 默认的 caching_sha2_password 认证要求 SSL），
///   服务器未开启 SSL 时加 `?ssl=false`；
/// - 用户名或密码中含 `@ : / ? #` 等字符时需做 URL 编码，如 `@` 写成 `%40`。
class MySqlConfig {
  const MySqlConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    this.ssl = true,
  });

  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final bool ssl;

  static const example = 'mysql://用户名:密码@主机:3306/数据库名';

  /// 解析连接串，格式不正确时抛出带中文说明的 [FormatException]。
  factory MySqlConfig.parse(String url) {
    final text = url.trim();
    if (text.isEmpty) {
      throw const FormatException('请填写连接串');
    }
    final Uri uri;
    try {
      uri = Uri.parse(text);
    } on FormatException {
      throw const FormatException('连接串格式不正确，应为 $example');
    }
    if (uri.scheme != 'mysql') {
      throw const FormatException('连接串应以 mysql:// 开头');
    }
    if (uri.host.isEmpty) {
      throw const FormatException('缺少主机地址');
    }
    final userInfo = uri.userInfo;
    final separator = userInfo.indexOf(':');
    final user = Uri.decodeComponent(
        separator < 0 ? userInfo : userInfo.substring(0, separator));
    final password = separator < 0
        ? ''
        : Uri.decodeComponent(userInfo.substring(separator + 1));
    if (user.isEmpty) {
      throw const FormatException('缺少用户名');
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) {
      throw const FormatException('缺少数据库名，应为 $example');
    }
    final sslParam = uri.queryParameters['ssl']?.toLowerCase();
    if (sslParam != null && sslParam != 'true' && sslParam != 'false') {
      throw const FormatException('ssl 参数只能是 true 或 false');
    }
    return MySqlConfig(
      host: uri.host,
      port: uri.hasPort ? uri.port : 3306,
      user: user,
      password: password,
      database: Uri.decodeComponent(segments.single),
      ssl: sslParam != 'false',
    );
  }

  /// 用于界面展示的地址，不含密码。
  String get displayName => '$user@$host:$port/$database';
}

/// 测试连接的结果。
class MySqlServerInfo {
  const MySqlServerInfo({required this.version, required this.itemCount});

  final String version;
  final int itemCount;
}

/// 网络数据源：数据保存在远程 MySQL 数据库的 [tableName] 表中，
/// 多台设备连接同一个数据库即可共享清单。
class MySqlItemRepository implements ItemRepository {
  MySqlItemRepository(this.config, {this.tableName = defaultTableName});

  final MySqlConfig config;

  /// 数据表名，测试时可指定其他表名以免影响正式数据
  final String tableName;

  /// 使用带前缀的表名，避免和共享数据库中的其他表冲突
  static const defaultTableName = 'memo_item';

  static const _timeout = Duration(seconds: 8);

  MySQLConnection? _connection;
  Future<void> _queue = Future.value();

  /// 同一连接不能并发执行查询，这里把所有操作排队串行执行
  Future<T> _run<T>(Future<T> Function(MySQLConnection conn) action) {
    final result = _queue.then((_) async {
      final conn = await _ensureConnected();
      try {
        return await action(conn);
      } on MySQLServerException {
        // SQL 执行错误，连接本身仍可用
        rethrow;
      } catch (_) {
        // 超时、断网等错误后连接状态不可靠，丢弃，下次操作时重新连接
        _connection = null;
        conn.close().catchError((_) {});
        rethrow;
      }
    });
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<MySQLConnection> _ensureConnected() async {
    final existing = _connection;
    if (existing != null && existing.connected) return existing;
    _connection = null;
    final conn = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.user,
      password: config.password,
      databaseName: config.database,
      secure: config.ssl,
    ).timeout(_timeout);
    try {
      await conn.connect(timeoutMs: _timeout.inMilliseconds);
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
          type INT NOT NULL DEFAULT 0,
          name VARCHAR(255) NOT NULL,
          status INT NOT NULL DEFAULT 0
        ) DEFAULT CHARSET=utf8mb4
      ''');
    } catch (_) {
      await conn.close().catchError((_) {});
      rethrow;
    }
    _connection = conn;
    return conn;
  }

  /// 连接服务器并确保数据表存在，返回服务器版本和现有数据条数。
  Future<MySqlServerInfo> testConnection() {
    return _run((conn) async {
      final version = await conn.execute('SELECT VERSION() AS v');
      final count =
          await conn.execute('SELECT COUNT(*) AS c FROM $tableName');
      return MySqlServerInfo(
        version: version.rows.first.colByName('v') ?? '',
        itemCount: int.parse(count.rows.first.colByName('c') ?? '0'),
      );
    });
  }

  ItemEntry _fromRow(ResultSetRow row) {
    return ItemEntry.fromMap({
      'id': int.parse(row.colByName('id')!),
      'type': int.parse(row.colByName('type')!),
      'name': row.colByName('name')!,
      'status': int.parse(row.colByName('status')!),
    });
  }

  @override
  Future<List<ItemEntry>> getItems() {
    return _run((conn) async {
      final result = await conn.execute(
          'SELECT id, type, name, status FROM $tableName ORDER BY type DESC, id');
      return result.rows.map(_fromRow).toList();
    });
  }

  @override
  Future<List<ItemEntry>> getItemsByType(ItemType type) {
    return _run((conn) async {
      final result = await conn.execute(
        'SELECT id, type, name, status FROM $tableName '
        'WHERE type = :type ORDER BY status ASC, id',
        {'type': type.value},
      );
      return result.rows.map(_fromRow).toList();
    });
  }

  @override
  Future<int> insertItem(ItemEntry entry) {
    return _run((conn) async {
      final result = await conn.execute(
        'INSERT INTO $tableName (type, name, status) '
        'VALUES (:type, :name, :status)',
        {
          'type': entry.type.value,
          'name': entry.name,
          'status': entry.status.value,
        },
      );
      return result.lastInsertID.toInt();
    });
  }

  /// 批量导入物品（不保留原 id），在一个事务中完成，用于把本机数据上传到网络。
  Future<void> importItems(List<ItemEntry> entries) {
    if (entries.isEmpty) return Future.value();
    return _run((conn) async {
      final params = <String, dynamic>{};
      final values = <String>[];
      for (var i = 0; i < entries.length; i++) {
        values.add('(:t$i, :n$i, :s$i)');
        params['t$i'] = entries[i].type.value;
        params['n$i'] = entries[i].name;
        params['s$i'] = entries[i].status.value;
      }
      await conn.transactional((tx) => tx.execute(
            'INSERT INTO $tableName (type, name, status) VALUES '
            '${values.join(', ')}',
            params,
          ));
    });
  }

  @override
  Future<int> deleteItem(int id) {
    return _run((conn) async {
      final result = await conn
          .execute('DELETE FROM $tableName WHERE id = :id', {'id': id});
      return result.affectedRows.toInt();
    });
  }

  @override
  Future<int> updateItem(ItemEntry entry) {
    return _run((conn) async {
      final result = await conn.execute(
        'UPDATE $tableName SET type = :type, name = :name, status = :status '
        'WHERE id = :id',
        {
          'id': entry.id,
          'type': entry.type.value,
          'name': entry.name,
          'status': entry.status.value,
        },
      );
      return result.affectedRows.toInt();
    });
  }

  @override
  Future<void> resetAllItems(bool isDone) {
    return _run((conn) async {
      await conn.execute(
        'UPDATE $tableName SET status = :status',
        {'status': isDone ? ItemStatus.done.value : ItemStatus.undone.value},
      );
    });
  }

  /// 断开连接，切换数据源时调用。
  Future<void> close() async {
    final conn = _connection;
    _connection = null;
    if (conn != null && conn.connected) {
      await conn.close();
    }
  }
}
