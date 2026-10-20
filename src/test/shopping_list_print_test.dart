import 'package:flutter_test/flutter_test.dart';
import 'package:memo/models/item_entry.dart';
import 'package:memo/print/shopping_list_layout.dart';
import 'package:memo/print/shopping_list_renderer.dart';

List<ItemEntry> items(ItemType type, int count,
        {ItemStatus status = ItemStatus.undone, String prefix = ''}) =>
    List.generate(
        count,
        (i) => ItemEntry(
            type: type, name: '$prefix${type.name}$i', status: status));

void main() {
  group('ShoppingListLayout', () {
    test('只包含需要购买的物品，按分类顺序分组并跳过空分类', () {
      final layout = ShoppingListLayout.fromItems([
        ...items(ItemType.drink, 2),
        ...items(ItemType.home, 1),
        ...items(ItemType.home, 3, status: ItemStatus.done, prefix: 'x'),
        ...items(ItemType.baby, 1, status: ItemStatus.done),
      ]);
      expect(layout.categories.map((c) => c.type),
          [ItemType.home, ItemType.drink]);
      expect(layout.itemCount, 3);
      expect(layout.pages, hasLength(1));
    });

    test('没有需要购买的物品时没有页面', () {
      final layout = ShoppingListLayout.fromItems(
          items(ItemType.food, 5, status: ItemStatus.done));
      expect(layout.itemCount, 0);
      expect(layout.pages, isEmpty);
    });

    test('物品多时分页：每页不超出可用高度，所有物品恰好出现一次，跨页分类标注续', () {
      final all = [
        for (final type in ItemType.values) ...items(type, 40),
      ];
      final layout = ShoppingListLayout.fromItems(all);
      expect(layout.pages.length, greaterThan(1));

      for (var i = 0; i < layout.pages.length; i++) {
        final used = layout.pages[i].blocks
            .fold<double>(0, (sum, block) => sum + block.height);
        final available =
            i == 0 ? PrintMetrics.firstPageBody : PrintMetrics.otherPageBody;
        expect(used, lessThanOrEqualTo(available + 1e-9),
            reason: '第 ${i + 1} 页');
        expect(layout.pages[i].blocks, isNotEmpty);
      }

      final printed = [
        for (final page in layout.pages)
          for (final block in page.blocks) ...block.names,
      ];
      expect(printed, all.map((e) => e.name).toList());

      // 每个分类只有第一块不是"续"
      for (final type in ItemType.values) {
        final blocks = [
          for (final page in layout.pages)
            ...page.blocks.where((b) => b.type == type),
        ];
        expect(blocks.first.continued, isFalse);
        expect(blocks.skip(1).every((b) => b.continued), isTrue);
        expect(blocks.every((b) => b.categoryTotal == 40), isTrue);
      }
    });
  });

  testWidgets('渲染为 200 DPI 的 A4 PNG', (tester) async {
    final layout = ShoppingListLayout.fromItems([
      for (final type in ItemType.values) ...items(type, 40),
    ]);
    final renderer = ShoppingListRenderer(layout, date: DateTime(2026, 10, 20));
    final pages = await tester.runAsync(renderer.renderAll);

    expect(pages, hasLength(layout.pages.length));
    for (final png in pages!) {
      // PNG 文件头和 IHDR 中的宽高
      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      final data = png.buffer.asByteData(png.offsetInBytes);
      expect(data.getUint32(16), 1654); // 210mm @ 200dpi
      expect(data.getUint32(20), 2339); // 297mm @ 200dpi
    }
  });
}
