package com.example.nabu_cleaner

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_CHANNEL = "nabu_cleaner/storage"
        private const val METHOD_GET_STORAGE_OVERVIEW = "getStorageOverview"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_STORAGE_OVERVIEW -> {
                    try {
                        val stat = StatFs(Environment.getDataDirectory().absolutePath)
                        val totalBytes = stat.totalBytes
                        val availableBytes = stat.availableBytes
                        val usedBytes = totalBytes - availableBytes

                        result.success(
                            mapOf(
                                "totalBytes" to totalBytes,
                                "availableBytes" to availableBytes,
                                "usedBytes" to usedBytes
                            )
                        )
                    } catch (e: Exception) {
                        result.error(
                            "STORAGE_READ_ERROR",
                            "Unable to read device storage overview.",
                            e.localizedMessage
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
