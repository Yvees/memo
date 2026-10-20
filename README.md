# Memo · 家庭购物清单

一个用 Flutter 编写的安卓购物清单 App。预置了约 100 种家里常买的东西，出门前把要买的打开，买完关掉；可以把数据放在远程 MySQL 上让全家共享，也可以把要买的东西按分类打印到 A4 纸上带去超市。

## 功能

- **分类清单**：日用、食物、蔬果、肉类、饮料、婴儿 6 个分类，首次安装预置 108 项常买物品。
- **开关标记**：开关打开表示"需要买"，关闭表示"已买 / 不需要"；未买的排在前面。
- **管理物品**：右上角菜单可添加、删除物品，或一键把所有物品标记为已完成 / 未完成。
- **数据源配置**：
  - **本机**（默认）：数据保存在手机上的 SQLite 数据库。
  - **网络**：数据保存在远程 MySQL，多台手机连同一个库即可共享同一份清单，下拉刷新获取别人的改动。
  - 提供"测试连接"，首次连接自动建表；切换到空的网络库时可把本机数据一并上传。
- **打印清单**：只打印需要购买的物品，按分类排在 A4 纸上（每行 4 列，每项前有方框，可手写打勾）。App 内先预览，再通过安卓系统打印界面选择局域网打印机，默认 A4、黑白、双面。

## 使用说明

### 网络数据源

右上角菜单 → **数据源配置** → 选择"网络"，填写连接串：

```
mysql://用户名:密码@主机:端口/数据库名
```

| 部分 | 说明 |
|---|---|
| 端口 | 可省略，默认 `3306` |
| SSL | 默认开启（MySQL 8 默认的 `caching_sha2_password` 认证要求 SSL）；服务器未开启 SSL 时在末尾加 `?ssl=false` |
| 特殊字符 | 用户名或密码含 `@ : / ? #` 等字符时需 URL 编码，如 `@` 写作 `%40` |

- 数据库需要事先创建好；表 `memo_item` 会在第一次连接时自动创建（`utf8mb4`）。
- 保存前会先测试连接，连不上不会切换。
- 切回"本机"时会保留上次填写的连接串。
- 网络异常时列表会显示原因和"重试"按钮，也可以随时切回本机。

示例：

```
mysql://memo_app:your-password@192.168.1.10:3306/memo
```

### 打印

右上角菜单 → **打印清单** → 预览确认 → **打印**。系统打印界面会列出手机打印服务发现的局域网打印机。如果找不到打印机，请在手机"设置 → 打印"中开启默认打印服务，或安装打印机厂商的打印插件。

## 开发

### 环境要求

只需要命令行编译环境，不需要 Android Studio：

| 组件 | 版本 |
|---|---|
| Flutter | 3.24.5（Dart 3.5） |
| JDK | 17 |
| Android SDK | platform 34、build-tools 34.0.0、platform-tools |

Gradle 8.3、Android Gradle Plugin 8.1.4、Kotlin 1.9.24 会在首次构建时自动下载。

安装好后把 Flutter 指向 SDK 和 JDK，并接受 Android SDK 许可：

```bash
flutter config --android-sdk <Android SDK 路径> --jdk-dir <JDK 17 路径>
flutter doctor --android-licenses
flutter doctor
```

### 编译

```bash
cd src
flutter pub get
flutter build apk --release
```

生成的 APK 位于 `src/build/app/outputs/flutter-apk/app-release.apk`。

### 正式签名

未配置时 release 包使用 debug 签名，仅供自己安装测试。正式发布前：

1. 生成密钥库（务必妥善备份，丢失后将无法再发布更新）：

   ```bash
   keytool -genkey -v -keystore memo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias memo
   ```

2. 参照 [`src/android/key.properties.example`](src/android/key.properties.example) 在同目录创建 `key.properties`，填入密钥库路径和密码。

`key.properties`、`*.jks`、`*.keystore` 已在 `.gitignore` 中，**切勿提交**。

### 测试

```bash
cd src
flutter test
```

连接真实 MySQL 的集成测试默认跳过。需要时通过环境变量指定测试库，测试使用独立的 `memo_item_test` 表，结束后自动删除，不影响正式数据：

```bash
MEMO_TEST_MYSQL_URL='mysql://用户名:密码@主机:端口/数据库名' flutter test
```

Windows PowerShell 下：

```powershell
$env:MEMO_TEST_MYSQL_URL='mysql://用户名:密码@主机:端口/数据库名'; flutter test
```

### 项目结构

```
src/
├── lib/
│   ├── main.dart                     入口：初始化本机数据库、读取数据源设置
│   ├── models/item_entry.dart        物品模型、分类与状态枚举
│   ├── pages/                        首页、添加、删除、重置、数据源配置、打印页面
│   ├── widgets/item_list_view.dart   首页两列物品列表（下拉刷新、错误重试）
│   ├── services/
│   │   ├── item_repository.dart      数据源接口
│   │   ├── database_helper.dart      本机 SQLite 实现，兼存 App 设置（config 表）
│   │   ├── mysql_item_repository.dart  MySQL 实现与连接串解析
│   │   ├── data_source.dart          当前数据源的切换与持久化
│   │   ├── data_source_errors.dart   异常 → 中文提示
│   │   └── page_printer.dart         打印通道（Dart 端）
│   └── print/                        A4 分页排版与页面渲染
├── android/app/src/main/kotlin/…/
│   ├── MainActivity.kt               注册打印通道
│   └── PageImagePrinter.kt           调用安卓系统打印框架
└── test/                             单元测试、界面测试、MySQL 集成测试
```

### 开发注意事项

- **避免引入带 Windows/Linux 原生实现的插件**：这类插件（如 `printing`、`shared_preferences`、`flutter_secure_storage`）在 `flutter pub get` 时需要创建符号链接，未开启 Windows 开发者模式时会失败。因此打印通道和设置存储都是自行实现的。确需使用时，请先开启开发者模式。
- **本机数据库升级**：表结构变更时递增 `DatabaseHelper._dbVersion`，并在 `_upgradeDb` 中按版本逐级补齐，保证老用户数据不丢失。
- **项目放在网络盘（SMB）上编译时**：
  - 第二次 release 构建报 `Cannot invoke "java.io.File.getAbsoluteFile()" because "dir" is null`：删除 `src/build/app/intermediates/flutter/release/flutter_build.d` 或执行 `flutter clean` 后重试。
  - 报 `classes.dex` 被占用：执行 `src/android/gradlew --stop` 后重试。
  - 把项目放在本地磁盘上编译不会遇到以上问题。

## 安全提示

- 网络数据源的连接串（含密码）以明文保存在 App 的私有存储中。
- 请为本应用单独创建一个只拥有该数据库权限的 MySQL 账号，不要使用 root。
- 手机直连数据库需要把 MySQL 端口开放给手机所在网络，请做好访问限制。如需给更多人共享，建议在服务器上加一层 API。

## 许可证

[GPL-3.0](LICENSE)
