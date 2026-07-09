package com.example.eazy_store

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.eazy_store/sound"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playBeep") {
                try {
                    toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Cannot play tone", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        super.onDestroy()
    }
}
