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
  FakeLocalRepository([this.items = const []]);

  final List<ItemEntry> items;

  @override
  Future<List<ItemEntry>> getItems() async => items;

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

/// 假的网络数据库：[remoteItemCount] 为远端现有条数，[uploaded] 记录导入的数据
int remoteItemCount = 3;
final uploaded = <ItemEntry>[];

class FakeRemoteRepository extends MySqlItemRepository {
  FakeRemoteRepository(super.config);

  @override
  Future<MySqlServerInfo> testConnection() async =>
      MySqlServerInfo(version: '8.0.99', itemCount: remoteItemCount);

  @override
  Future<void> importItems(List<ItemEntry> entries) async =>
      uploaded.addAll(entries);

  @override
  Future<void> close() async {}
}

void main() {
  late MemoryConfigStore store;
  late DataSourceService service;
  final localItems = [
    ItemEntry(id: 1, type: ItemType.food, name: '鸡蛋'),
    ItemEntry(id: 2, type: ItemType.drink, name: '牛奶'),
  ];

  setUp(() {
    remoteItemCount = 3;
    uploaded.clear();
    store = MemoryConfigStore();
    service = DataSourceService(
      local: FakeLocalRepository(localItems),
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

  Future<void> saveRemoteWithEmptyServer(WidgetTester tester) async {
    remoteItemCount = 0;
    await openPage(tester);
    await tester.tap(find.text('网络'));
    await tester.pump();
    await tester.enterText(
        find.byType(TextField), 'mysql://memo:pw@db.example.com/shop');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('上传本机数据？'), findsOneWidget);
    expect(find.textContaining('本机的 2 条数据'), findsOneWidget);
  }

  testWidgets('网络数据库为空时询问上传，选择上传后导入本机数据并切换', (tester) async {
    await saveRemoteWithEmptyServer(tester);
    await tester.tap(find.text('上传'));
    await tester.pumpAndSettle();
    expect(uploaded.map((e) => e.name), ['鸡蛋', '牛奶']);
    expect(service.type, DataSourceType.remote);
  });

  testWidgets('选择不上传时直接切换，不导入数据', (tester) async {
    await saveRemoteWithEmptyServer(tester);
    await tester.tap(find.text('不上传'));
    await tester.pumpAndSettle();
    expect(uploaded, isEmpty);
    expect(service.type, DataSourceType.remote);
  });

  testWidgets('选择取消时不保存，仍为本机', (tester) async {
    await saveRemoteWithEmptyServer(tester);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(uploaded, isEmpty);
    expect(service.type, DataSourceType.local);
    expect(find.byType(DataSourcePage), findsOneWidget);
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
