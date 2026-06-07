package com.example.olmeg_connect

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "paymob_sdk_flutter"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "payWithPaymob" -> result.error(
                    "paymob_sdk_missing",
                    "Paymob Android SDK is not installed yet; falling back to hosted checkout.",
                    null
                )
                else -> result.notImplemented()
            }
        }
    }
}
