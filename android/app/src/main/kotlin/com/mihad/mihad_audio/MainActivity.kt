package com.mihad.mihad_audio

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mihad_audio/export_foreground",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startExport" -> {
                    ensureNotificationPermission()
                    ExportForegroundService.start(this)
                    result.success(null)
                }
                "updateExport" -> {
                    val progress = (call.argument<Int>("progress") ?: 0).coerceIn(0, 100)
                    ExportForegroundService.update(this, progress)
                    result.success(null)
                }
                "finishExport" -> {
                    val status = call.argument<String>("status") ?: "complete"
                    ExportForegroundService.finish(this, status)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 3201)
        }
    }
}
