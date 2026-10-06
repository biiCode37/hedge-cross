package id.mikrotrans.hedge.hedge_flutter

import android.app.KeyguardManager
import android.content.Context
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.ContextThemeWrapper
import android.view.Display
import android.view.WindowManager

class AlarmOverlay(private val context: Context) {
    private var surface: AlarmSurface? = null
    private var manager: WindowManager? = null
    fun update(events: List<ActiveAlarm>) {
        val locked = context.getSystemService(KeyguardManager::class.java).isKeyguardLocked
        val interactive = context.getSystemService(PowerManager::class.java).isInteractive
        val ownScreen = MainActivity.foreground?.get() != null || AlarmActivity.foreground?.get() != null
        if (events.isEmpty() || locked || !interactive || ownScreen || !Settings.canDrawOverlays(context)) { close(); return }
        try {
            if (surface == null) {
                val type = if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    else WindowManager.LayoutParams.TYPE_PHONE
                val display = context.getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY)
                val displayContext = if (display != null) context.createDisplayContext(display) else context
                val windowContext = if (Build.VERSION.SDK_INT >= 30) displayContext.createWindowContext(type, null) else displayContext
                val themed = ContextThemeWrapper(windowContext, R.style.HedgeAlarmTheme)
                val wm = windowContext.getSystemService(WindowManager::class.java)
                val view = AlarmSurface(themed)
                val params = WindowManager.LayoutParams(-1, -1, type,
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.OPAQUE).apply { title = "HEDGE — Alert keberangkatan" }
                view.render(events)
                wm.addView(view, params)
                manager = wm; surface = view
            } else surface?.render(events)
        } catch (error: RuntimeException) {
            close(); AlarmEngine.deliveryIssue(context, "Alert di atas aplikasi lain gagal: ${error.message}")
        }
    }
    fun close() {
        val view = surface
        surface = null
        if (view != null) try { manager?.removeViewImmediate(view) } catch (_: IllegalArgumentException) { }
        manager = null
    }
}
