package id.mikrotrans.hedge.hedge_flutter

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {
    companion object { var foreground: WeakReference<MainActivity>? = null }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.mikrotrans.hedge/alarms")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "replace" -> result.success(AlarmEngine.replace(this, JSONObject(call.arguments as String)))
                        "testSpeech" -> { AlarmEngine.deliveryIssue(this, ""); AlarmDeliveryService.sync(this, preview = true); result.success(null) }
                        "stopSpeechTest" -> { AlarmDeliveryService.stopPreview(); result.success(null) }
                        "status" -> result.success(AlarmEngine.status(this))
                        "readActions" -> result.success(AlarmEngine.pendingActions(this))
                        "acceptActions" -> {
                            AlarmEngine.acceptActions(this, (call.arguments as List<*>).filterIsInstance<String>().toSet())
                            result.success(null)
                        }
                        "openPermission" -> { AlarmEngine.permissionSettings(this, call.arguments as String); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) { result.error("HEDGE_ALARM", e.message, null) }
            }
    }
    override fun onResume() {
        super.onResume(); foreground = WeakReference(this)
        AlarmEngine.openWhenForeground(this)
        AlarmDeliveryService.sync(this)
    }
    override fun onPause() {
        if (foreground?.get() === this) foreground = null
        super.onPause()
    }
}