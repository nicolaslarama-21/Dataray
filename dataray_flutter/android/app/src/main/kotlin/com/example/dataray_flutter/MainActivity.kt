package com.example.dataray_flutter

import android.util.AtomicFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dataray/canvases")
            .setMethodCallHandler { call, result ->
                try {
                    val file = AtomicFile(File(filesDir, "laser_canvases.json"))
                    when (call.method) {
                        "read" -> result.success(if (file.baseFile.exists()) String(file.readFully(), Charsets.UTF_8) else "[]")
                        "write" -> {
                            val value = call.arguments as? String ?: throw IllegalArgumentException("JSON requerido")
                            val stream = file.startWrite()
                            try {
                                stream.write(value.toByteArray(Charsets.UTF_8))
                                file.finishWrite(stream)
                            } catch (e: Exception) { file.failWrite(stream); throw e }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) { result.error("CANVAS", e.message, null) }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dataray/settings")
            .setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences("dataray_settings", MODE_PRIVATE)
                when (call.method) {
                    "readTheme" -> result.success(preferences.getString("theme", null))
                    "writeTheme" -> {
                        val value = call.arguments as? String
                        if (value != "light" && value != "dark") {
                            result.error("SETTINGS", "Invalid theme", null)
                        } else {
                            preferences.edit().putString("theme", value).apply()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dataray/history")
            .setMethodCallHandler { call, result ->
                try {
                    val file = AtomicFile(File(filesDir, "test_history.json"))
                    when (call.method) {
                        "read" -> result.success(if (file.baseFile.exists())
                            String(file.readFully(), Charsets.UTF_8) else "[]")
                        "write" -> {
                            val value = call.arguments as? String
                                ?: throw IllegalArgumentException("JSON requerido")
                            val stream = file.startWrite()
                            try {
                                stream.write(value.toByteArray(Charsets.UTF_8))
                                file.finishWrite(stream)
                            } catch (e: Exception) {
                                file.failWrite(stream)
                                throw e
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("HISTORY", e.message, null)
                }
            }
    }
}


