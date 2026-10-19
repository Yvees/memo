import 'package:flutter_test/flutter_test.dart';
import 'package:memo/services/mysql_item_repository.dart';

void main() {
  group('MySqlConfig.parse', () {
    test('解析完整连接串', () {
      final c = MySqlConfig.parse('mysql://memo:secret@db.example.com:3307/shop');
      expect(c.host, 'db.example.com');
      expect(c.port, 3307);
      expect(c.user, 'memo');
      expect(c.password, 'secret');
      expect(c.database, 'shop');
      expect(c.ssl, isTrue);
      expect(c.displayName, 'memo@db.example.com:3307/shop');
    });

    test('端口默认 3306，首尾空格忽略', () {
      final c = MySqlConfig.parse('  mysql://memo:secret@192.168.1.10/shop  ');
      expect(c.host, '192.168.1.10');
      expect(c.port, 3306);
    });

    test('ssl=false 关闭 SSL', () {
      expect(MySqlConfig.parse('mysql://u:p@h/db?ssl=false').ssl, isFalse);
      expect(MySqlConfig.parse('mysql://u:p@h/db?ssl=true').ssl, isTrue);
    });

    test('用户名和密码支持 URL 编码的特殊字符', () {
      final c = MySqlConfig.parse('mysql://memo:p%40ss%3Aw%2Frd@h/db');
      expect(c.password, 'p@ss:w/rd');
    });

    test('允许空密码', () {
      final c = MySqlConfig.parse('mysql://memo@h/db');
      expect(c.user, 'memo');
      expect(c.password, '');
    });

    void expectError(String url, String messagePart) {
      expect(
        () => MySqlConfig.parse(url),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains(messagePart))),
      );
    }

    test('格式错误时给出中文提示', () {
      expectError('', '请填写连接串');
      expectError('http://u:p@h/db', 'mysql://');
      expectError('mysql://u:p@/db', '主机');
      expectError('mysql://h/db', '用户名');
      expectError('mysql://u:p@h', '数据库名');
      expectError('mysql://u:p@h/db/extra', '数据库名');
      expectError('mysql://u:p@h/db?ssl=maybe', 'ssl');
    });
  });
}
