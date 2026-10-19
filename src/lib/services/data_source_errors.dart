import 'dart:async';
import 'dart:io';

import 'package:mysql_client/exception.dart';

/// 把访问数据源时的异常转换成给用户看的中文说明。
String describeDataSourceError(Object error) {
  if (error is FormatException) {
    return error.message;
  }
  if (error is TimeoutException) {
    return '连接超时，请检查主机地址、端口、网络及服务器防火墙';
  }
  if (error is HandshakeException || error is TlsException) {
    return 'SSL 连接失败，如服务器未开启 SSL，请在连接串末尾加 ?ssl=false';
  }
  if (error is SocketException) {
    return '无法连接到服务器（${error.osError?.message ?? error.message}），'
        '请检查主机地址、端口和网络';
  }
  if (error is MySQLServerException) {
    switch (error.errorCode) {
      case 1045:
        return '用户名或密码错误';
      case 1049:
        return '数据库不存在，请先在服务器上创建';
      case 1044:
      case 1142:
        return '该账号没有访问或建表的权限';
      default:
        return 'MySQL 错误 ${error.errorCode}：${error.message}';
    }
  }
  if (error is MySQLClientException) {
    final message = error.message;
    if (message.contains('does not support SSL')) {
      return '服务器未开启 SSL，请在连接串末尾加 ?ssl=false';
    }
    if (message.contains('caching_sha2_password')) {
      return '该账号使用 caching_sha2_password 认证，必须启用 SSL'
          '（去掉连接串中的 ?ssl=false）';
    }
    return message;
  }
  return error.toString();
}
