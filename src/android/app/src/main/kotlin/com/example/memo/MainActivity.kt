package com.example.memo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 打印通道：Dart 端见 lib/services/page_printer.dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "memo/print")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "printPages" -> {
                        val jobName = call.argument<String>("jobName") ?: "购物清单"
                        val pages = call.argument<List<ByteArray>>("pages")
                        if (pages.isNullOrEmpty()) {
                            result.error("no_pages", "没有可打印的页面", null)
                        } else {
                            try {
                                PageImagePrinter(this).print(jobName, pages)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("print_failed", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
