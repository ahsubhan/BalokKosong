package com.ahmadss.balokkosong

import android.graphics.Rect
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val systemUiChannel = "com.ahmadss.balokkosong/system_ui"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemUiChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "setGameplayGestureExclusion") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            setGameplayGestureExclusion(call.arguments == true)
            result.success(null)
        }
    }

    private fun setGameplayGestureExclusion(enabled: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val view = window.decorView
        view.post {
            if (!enabled || view.width == 0 || view.height == 0) {
                view.systemGestureExclusionRects = emptyList()
                return@post
            }
            val edgeWidth = (32 * resources.displayMetrics.density).toInt()
            view.systemGestureExclusionRects = listOf(
                Rect(0, 0, edgeWidth, view.height),
                Rect(view.width - edgeWidth, 0, view.width, view.height),
            )
        }
    }
}
