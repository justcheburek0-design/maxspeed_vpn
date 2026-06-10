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
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val packages = pm.getInstalledPackages(0)
                        val apps = packages.map { info ->
                            mapOf(
                                "package" to info.packageName,
                                "name" to pm.getApplicationLabel(info.applicationInfo!!).toString()
                            )
                        }
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("APPS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
