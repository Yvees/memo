/// 键值形式的 App 设置存储。
abstract class ConfigStore {
  Future<String?> getConfig(String key);

  Future<void> setConfig(String key, String value);
}
