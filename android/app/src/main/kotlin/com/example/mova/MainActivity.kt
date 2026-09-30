package com.example.mova

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.mova/app_lifecycle",
        ).setMethodCallHandler { call, result ->
            if (call.method == "moveTaskToBack") {
                result.success(moveTaskToBack(true))
            } else {
                result.notImplemented()
            }
        }
    }
}
