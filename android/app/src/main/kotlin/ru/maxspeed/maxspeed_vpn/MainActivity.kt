package ru.maxspeed.maxspeed_vpn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "maxspeed.vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    result.success(true)
                }
                "disconnect" -> {
                    result.success(true)
                }
                "status" -> {
                    result.success("disconnected")
                }
                else -> result.notImplemented()
            }
        }
    }
}
