package com.ahmadss.balokkosong

import android.graphics.Rect
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val systemUiChannel = "com.ahmadss.balokkosong/system_ui"
    private var gameplayModeEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemUiChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setGameplayGestureExclusion" -> {
                    setGameplayMode(call.arguments == true)
                    result.success(null)
                }
                "playCollisionHaptic" -> {
                    playCollisionHaptic()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && gameplayModeEnabled) {
            hideSystemNavigation()
            setGameplayGestureExclusion(true)
        }
    }

    private fun setGameplayMode(enabled: Boolean) {
        gameplayModeEnabled = enabled
        if (enabled) {
            hideSystemNavigation()
        } else {
            restoreSystemNavigation()
        }
        setGameplayGestureExclusion(enabled)
    }

    @Suppress("DEPRECATION")
    private fun hideSystemNavigation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.apply {
                systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                hide(WindowInsets.Type.systemBars())
            }
        } else {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN
        }
    }

    @Suppress("DEPRECATION")
    private fun restoreSystemNavigation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.systemBars())
            window.setDecorFitsSystemWindows(true)
        } else {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        }
    }

    @Suppress("DEPRECATION")
    private fun playCollisionHaptic() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(70, 255))
        } else {
            vibrator.vibrate(70)
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
