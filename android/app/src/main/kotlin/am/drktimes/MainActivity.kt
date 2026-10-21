package am.drktimes

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var intake: MethodChannel? = null

    /** A shared/opened file that arrived before Dart was listening. */
    private var pendingFile: Map<String, Any>? = null
    private var intakeReady = false

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

        intake = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "am.drktimes/intake",
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> {
                        intakeReady = true
                        pendingFile?.let { ch.invokeMethod("incomingFile", it) }
                        pendingFile = null
                        result.success(null)
                    }
                    "readContent" -> {
                        val uri = Uri.parse(call.argument<String>("uri"))
                        val file = readUri(uri)
                        if (file == null) result.success(null) else result.success(file)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShareIntent(intent)
    }

    /** ACTION_SEND carries its file in EXTRA_STREAM; app_links does not see it. */
    private fun handleShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        val uri: Uri = (if (android.os.Build.VERSION.SDK_INT >= 33)
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else
            @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)) ?: return
        val file = readUri(uri) ?: return
        if (intakeReady) intake?.invokeMethod("incomingFile", file) else pendingFile = file
    }

    private fun readUri(uri: Uri): Map<String, Any>? = try {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
        var name = "shared.drktimes"
        contentResolver.query(uri, null, null, null, null)?.use { c ->
            val i = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (i >= 0 && c.moveToFirst()) name = c.getString(i)
        }
        if (bytes == null) null else mapOf("name" to name, "bytes" to bytes.toList().map { it.toInt() and 0xff })
    } catch (e: Exception) {
        null
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
