import 'package:flutter/foundation.dart';

import 'item_repository.dart';

/// 管理当前使用的数据源，页面通过它拿到 [repository] 读写数据。
class DataSourceService extends ChangeNotifier {
  DataSourceService({required ItemRepository local}) : _local = local;

  final ItemRepository _local;

  ItemRepository get repository => _local;
}
