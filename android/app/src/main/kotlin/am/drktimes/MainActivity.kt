package am.drktimes

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** Volume keys are consumed only while a session is awaiting Next. */
    private var armed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "am.drktimes/volume_keys",
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setArmed" -> {
                        armed = call.argument<Boolean>("armed") ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun isVolumeKey(code: Int) =
        code == KeyEvent.KEYCODE_VOLUME_UP || code == KeyEvent.KEYCODE_VOLUME_DOWN

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (armed && isVolumeKey(keyCode)) {
            if (event?.repeatCount == 0) {
                val key = if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
                channel?.invokeMethod("volumeKey", mapOf("key" to key))
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (armed && isVolumeKey(keyCode)) return true
        return super.onKeyUp(keyCode, event)
    }
}
