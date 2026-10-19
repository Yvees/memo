enum ItemStatus {
  undone(0),
  done(1);

  final int value;
  const ItemStatus(this.value);
}

enum ItemType {
  home(0, '日用'),
  food(1, '食物'),
  fruit(2, '蔬果'),
  meat(3, '肉类'),
  drink(4, '饮料'),
  baby(5, '婴儿');

  final int value;
  final String label;
  const ItemType(this.value, this.label);
}

class ItemEntry {
  int? id;
  ItemType type;
  String name;
  ItemStatus status;

  ItemEntry({
    this.id,
    required this.type,
    required this.name,
    this.status = ItemStatus.undone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'name': name,
      'status': status.value,
    };
  }

  factory ItemEntry.fromMap(Map<String, dynamic> map) {
    return ItemEntry(
      id: map['id'],
      type: ItemType.values.firstWhere((type) => type.value == map['type']),
      name: map['name'],
      status: ItemStatus.values
          .firstWhere((status) => status.value == map['status']),
    );
  }
}
