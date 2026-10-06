package id.mikrotrans.hedge.hedge_flutter

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowInsetsController
import android.view.WindowManager
import android.window.OnBackInvokedDispatcher
import java.lang.ref.WeakReference

class AlarmActivity : Activity() {
    companion object { var foreground: WeakReference<AlarmActivity>? = null }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var surface: AlarmSurface
    private val tick = object : Runnable {
        override fun run() {
            val events = AlarmEngine.visible(this@AlarmActivity)
            if (events.isEmpty()) { finish(); return }
            surface.render(events)
            window.statusBarColor = surface.surfaceColor; window.navigationBarColor = surface.surfaceColor
            if (Build.VERSION.SDK_INT >= 30) {
                val flags = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                window.insetsController?.setSystemBarsAppearance(if (surface.lightTheme) flags else 0, flags)
            } else window.decorView.systemUiVisibility = if (surface.lightTheme) View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or
                (if (Build.VERSION.SDK_INT >= 26) View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR else 0) else 0
            handler.postDelayed(this, 250)
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        if (Build.VERSION.SDK_INT >= 33) onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { }
        surface = AlarmSurface(this)
        setContentView(surface)
    }
    override fun onResume() {
        super.onResume(); foreground = WeakReference(this)
        AlarmDeliveryService.sync(this)
        handler.removeCallbacks(tick); tick.run()
    }
    override fun onPause() {
        if (foreground?.get() === this) foreground = null
        handler.removeCallbacks(tick); super.onPause()
    }
    override fun onDestroy() { handler.removeCallbacks(tick); super.onDestroy() }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent) }
    @Deprecated("Alarm closes by action, OFF or configured timeout")
    override fun onBackPressed() { /* Home and system controls remain available. */ }
}
