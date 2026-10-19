import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'pages/add.dart';
import 'pages/data_source.dart';
import 'pages/home.dart';
import 'pages/remove.dart';
import 'pages/reset.dart';
import 'services/data_source.dart';
import 'services/database_helper.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows
  if (Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize the database (opened once and cached by DatabaseHelper)
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // 读取数据源设置（本机或网络），设置本身保存在本机数据库中
  final dataSource = DataSourceService(local: dbHelper, config: dbHelper);
  await dataSource.load();

  runApp(
    ChangeNotifierProvider<DataSourceService>.value(
      value: dataSource,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: child!,
        );
      },
      home: const HomePage(),
      routes: {
        '/add': (context) => const AddPage(),
        '/remove': (context) => const RemovePage(),
        '/reset': (context) => const ResetPage(),
        '/datasource': (context) => const DataSourcePage(),
      },
    );
  }
}
