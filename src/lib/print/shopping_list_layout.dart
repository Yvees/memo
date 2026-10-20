import '../models/item_entry.dart';

/// A4 打印排版尺寸，单位：毫米。
class PrintMetrics {
  static const pageWidth = 210.0;
  static const pageHeight = 297.0;
  static const margin = 12.0;

  /// 第一页顶部的标题和日期区域
  static const headerHeight = 18.0;

  /// 每页底部的页码区域
  static const footerHeight = 6.0;

  /// 分类标题行
  static const categoryHeight = 8.0;

  /// 物品行，每行 [columns] 个物品
  static const rowHeight = 6.5;
  static const columns = 4;

  /// 分类之间的间距
  static const categoryGap = 2.5;

  static const contentWidth = pageWidth - 2 * margin;

  /// 第一页（有标题）和后续页可用于分类的高度
  static const firstPageBody =
      pageHeight - 2 * margin - headerHeight - footerHeight;
  static const otherPageBody = pageHeight - 2 * margin - footerHeight;
}

/// 一个分类下需要购买的物品名称。
class PrintCategory {
  const PrintCategory(this.type, this.names);

  final ItemType type;
  final List<String> names;
}

/// 页面上的一个分类块。分类跨页时拆成多块，后续块 [continued] 为 true。
class PrintBlock {
  const PrintBlock({
    required this.type,
    required this.names,
    required this.continued,
    required this.categoryTotal,
  });

  final ItemType type;
  final List<String> names;
  final bool continued;

  /// 该分类的物品总数（标题中显示）
  final int categoryTotal;

  int get rows =>
      (names.length + PrintMetrics.columns - 1) ~/ PrintMetrics.columns;

  double get height =>
      PrintMetrics.categoryHeight +
      rows * PrintMetrics.rowHeight +
      PrintMetrics.categoryGap;
}

class PrintPageLayout {
  const PrintPageLayout(this.blocks);

  final List<PrintBlock> blocks;
}

/// 购物清单的 A4 分页结果：只包含需要购买（未完成）的物品，按分类分组。
class ShoppingListLayout {
  ShoppingListLayout._(this.categories, this.pages);

  final List<PrintCategory> categories;
  final List<PrintPageLayout> pages;

  int get itemCount =>
      categories.fold(0, (sum, category) => sum + category.names.length);

  factory ShoppingListLayout.fromItems(List<ItemEntry> items) {
    // 按分类枚举顺序分组，跳过已购买的物品和空分类，分类内保持原有顺序
    final categories = <PrintCategory>[
      for (final type in ItemType.values)
        PrintCategory(type, [
          for (final item in items)
            if (item.type == type && item.status == ItemStatus.undone)
              item.name,
        ]),
    ].where((c) => c.names.isNotEmpty).toList();
    return ShoppingListLayout._(categories, _paginate(categories));
  }

  static List<PrintPageLayout> _paginate(List<PrintCategory> categories) {
    final pages = <PrintPageLayout>[];
    var blocks = <PrintBlock>[];
    var remaining = PrintMetrics.firstPageBody;

    void newPage() {
      pages.add(PrintPageLayout(blocks));
      blocks = [];
      remaining = PrintMetrics.otherPageBody;
    }

    for (final category in categories) {
      var start = 0;
      while (start < category.names.length) {
        final rowsThatFit = ((remaining -
                    PrintMetrics.categoryHeight -
                    PrintMetrics.categoryGap) /
                PrintMetrics.rowHeight)
            .floor();
        // 本页连标题加一行物品都放不下时换页，避免分类标题孤零零留在页尾
        if (rowsThatFit < 1 && blocks.isNotEmpty) {
          newPage();
          continue;
        }
        final take = (category.names.length - start).clamp(
            1, (rowsThatFit < 1 ? 1 : rowsThatFit) * PrintMetrics.columns);
        final block = PrintBlock(
          type: category.type,
          names: category.names.sublist(start, start + take),
          continued: start > 0,
          categoryTotal: category.names.length,
        );
        blocks.add(block);
        remaining -= block.height;
        start += take;
        if (start < category.names.length) newPage();
      }
    }
    if (blocks.isNotEmpty) pages.add(PrintPageLayout(blocks));
    return pages;
  }
}
