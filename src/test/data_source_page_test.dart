// 数据源配置页的界面测试，用假的网络数据源，不连接真实服务器。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/pages/data_source.dart';
import 'package:memo/services/config_store.dart';
import 'package:memo/services/data_source.dart';
import 'package:memo/services/item_repository.dart';
import 'package:memo/services/mysql_item_repository.dart';
import 'package:provider/provider.dart';

class MemoryConfigStore implements ConfigStore {
  final values = <String, String>{};

  @override
  Future<String?> getConfig(String key) async => values[key];

  @override
  Future<void> setConfig(String key, String value) async =>
      values[key] = value;
}

class FakeLocalRepository implements ItemRepository {
  @override
  Future<List<ItemEntry>> getItems() async => [];

  @override
  Future<List<ItemEntry>> getItemsByType(ItemType type) async => [];

  @override
  Future<int> insertItem(ItemEntry entry) async => 1;

  @override
  Future<int> deleteItem(int id) async => 1;

  @override
  Future<int> updateItem(ItemEntry entry) async => 1;

  @override
  Future<void> resetAllItems(bool isDone) async {}
}

class FakeRemoteRepository extends MySqlItemRepository {
  FakeRemoteRepository(super.config);

  @override
  Future<MySqlServerInfo> testConnection() async =>
      const MySqlServerInfo(version: '8.0.99', itemCount: 3);

  @override
  Future<void> close() async {}
}

void main() {
  late MemoryConfigStore store;
  late DataSourceService service;

  setUp(() {
    store = MemoryConfigStore();
    service = DataSourceService(
      local: FakeLocalRepository(),
      config: store,
      remoteFactory: FakeRemoteRepository.new,
    );
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: service,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DataSourcePage())),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('默认选中本机，选择网络后显示连接串输入框和测试按钮', (tester) async {
    await openPage(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('测试连接'), findsNothing);

    await tester.tap(find.text('网络'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
  });

  testWidgets('连接串格式错误时显示原因，且不能保存', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('网络'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'mysql://u:p@host');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.textContaining('连接失败：缺少数据库名'), findsOneWidget);
    expect(service.type, DataSourceType.local);
    expect(store.values['data_source'], isNull);
  });

  testWidgets('测试连接成功后保存，切换到网络并记住连接串', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('网络'));
    await tester.pump();
    await tester.enterText(
        find.byType(TextField), 'mysql://memo:pw@db.example.com/shop');
    await tester.tap(find.text('测试连接'));
    await tester.pumpAndSettle();
    expect(find.textContaining('连接成功：MySQL 8.0.99'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(service.type, DataSourceType.remote);
    expect(service.description, '网络（memo@db.example.com:3306/shop）');
    expect(store.values['data_source'], 'remote');
    expect(store.values['remote_url'], 'mysql://memo:pw@db.example.com/shop');
    // 保存后返回上一页
    expect(find.byType(DataSourcePage), findsNothing);
  });

  testWidgets('切回本机时保留之前填写的连接串', (tester) async {
    await service.useRemote('mysql://memo:pw@db.example.com/shop');
    await openPage(tester);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('本机'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(service.type, DataSourceType.local);
    expect(store.values['remote_url'], 'mysql://memo:pw@db.example.com/shop');
  });

  test('启动时读取保存的网络设置；连接串损坏时退回本机', () async {
    store.values['data_source'] = 'remote';
    store.values['remote_url'] = 'mysql://memo:pw@db.example.com/shop';
    await service.load();
    expect(service.type, DataSourceType.remote);

    final broken = DataSourceService(
        local: FakeLocalRepository(),
        config: MemoryConfigStore()
          ..values['data_source'] = 'remote'
          ..values['remote_url'] = 'not a url',
        remoteFactory: FakeRemoteRepository.new);
    await broken.load();
    expect(broken.type, DataSourceType.local);
  });
}
