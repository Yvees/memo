import 'package:flutter/material.dart';
import '../models/item_entry.dart';
import '../services/database_helper.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  AddPageState createState() => AddPageState();
}

class AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  ItemType _selectedType = ItemType.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增项目'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: '名称',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.lightGreen[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入名称';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ItemType>(
                decoration: InputDecoration(
                  labelText: '类别',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.lightGreen[50],
                ),
                value: _selectedType,
                items: ItemType.values.map((ItemType type) {
                  return DropdownMenuItem<ItemType>(
                    value: type,
                    child: Text(_getItemTypeName(type)),
                  );
                }).toList(),
                onChanged: (ItemType? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  onPressed: _submitForm,
                  child: const Text('保存', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // 创建新的ItemEntry对象
      ItemEntry newItem = ItemEntry(
        type: _selectedType,
        name: _name,
      );
      // 将newItem保存到数据库
      await DatabaseHelper().insertItem(newItem);
      if (mounted) {
        Navigator.pop(context, newItem);
      }
    }
  }

  String _getItemTypeName(ItemType type) {
    switch (type) {
      case ItemType.home:
        return '日用';
      case ItemType.food:
        return '食物';
      case ItemType.fruit:
        return '蔬果';
      case ItemType.meat:
        return '肉类';
      case ItemType.drink:
        return '饮料';
      case ItemType.baby:
        return '婴儿';
    }
  }
}
