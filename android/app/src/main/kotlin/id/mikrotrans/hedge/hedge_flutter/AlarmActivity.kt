package id.mikrotrans.hedge.hedge_flutter

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.window.OnBackInvokedDispatcher
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Native alarm surface, available even when the Flutter engine/process was not running. */
class AlarmActivity : Activity(), SharedPreferences.OnSharedPreferenceChangeListener {
    private val handler = Handler(Looper.getMainLooper())
    private val tick = object : Runnable {
        override fun run() {
            val events = AlarmEngine.visible(this@AlarmActivity)
            if (events.isEmpty()) { AlarmEngine.tick(this@AlarmActivity); finish(); return }
            render(events)
            handler.postDelayed(this, 250)
        }
    }
    private var currentKey: String? = null
    private lateinit var remaining: TextView
    private lateinit var countdown: TextView
    private lateinit var stageLabel: TextView
    private var dark = true
    private val amber = Color.rgb(255, 152, 0)
    private fun dp(n: Int) = (n * resources.displayMetrics.density).toInt()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { }
        }
        getSharedPreferences(AlarmEngine.PREFS, MODE_PRIVATE).registerOnSharedPreferenceChangeListener(this)
    }
    override fun onResume() { super.onResume(); handler.removeCallbacks(tick); tick.run() }
    override fun onPause() { handler.removeCallbacks(tick); super.onPause() }
    override fun onDestroy() {
        handler.removeCallbacks(tick)
        getSharedPreferences(AlarmEngine.PREFS, MODE_PRIVATE).unregisterOnSharedPreferenceChangeListener(this)
        super.onDestroy()
    }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); currentKey = null }
    override fun onSharedPreferenceChanged(p: SharedPreferences, key: String?) {
        if (key == AlarmEngine.STATE) { currentKey = null; handler.removeCallbacks(tick); handler.post(tick) }
    }
    @Deprecated("Alarm closes by action, OFF or configured timeout")
    override fun onBackPressed() { /* Avoid dismissing the alert accidentally. Home/system controls remain available. */ }
    private fun text(value: String, size: Float, color: Int, bold: Boolean = false): TextView = TextView(this).apply {
        text = value; textSize = size; setTextColor(color)
        typeface = try { Typeface.createFromAsset(assets,
            "flutter_assets/assets/fonts/roboto-${if (bold) "bold" else "regular"}.ttf") }
            catch (_: Exception) { if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT }
        setPadding(0, dp(4), 0, dp(4))
    }
    private fun shape(color: Int, border: Int? = null) = GradientDrawable().apply {
        setColor(color); cornerRadius = dp(16).toFloat()
        if (border != null) setStroke(dp(1), border)
    }
    private fun render(events: List<ActiveAlarm>) {
        val item = events.first(); val e = item.event
        val now = System.currentTimeMillis()
        val light = e.theme == "light" || (e.theme == "system" &&
            resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK != Configuration.UI_MODE_NIGHT_YES)
        if (currentKey != "${e.key}:${e.theme}:${events.size}") {
            currentKey = "${e.key}:${e.theme}:${events.size}"; dark = !light
            val bg = if (dark) Color.rgb(7, 11, 18) else Color.rgb(248, 250, 252)
            val surface = if (dark) Color.rgb(12, 16, 23) else Color.WHITE
            val ink = if (dark) Color.rgb(248, 250, 252) else Color.rgb(15, 23, 42)
            val muted = if (dark) Color.rgb(148, 163, 184) else Color.rgb(71, 85, 105)
            val accent = if (e.stage == "due") (if (dark) amber else Color.rgb(154, 71, 0))
                else (if (dark) Color.rgb(56, 189, 248) else Color.rgb(0, 107, 139))
            window.statusBarColor = bg; window.navigationBarColor = bg
            if (Build.VERSION.SDK_INT >= 30) {
                val flags = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                window.insetsController?.setSystemBarsAppearance(if (light) flags else 0, flags)
            } else window.decorView.systemUiVisibility = if (light) View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or
                (if (Build.VERSION.SDK_INT >= 26) View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR else 0) else 0
            val scroll = ScrollView(this).apply { setBackgroundColor(bg); isFillViewport = true }
            val root = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(24), dp(24), dp(24), dp(24))
            }
            scroll.setOnApplyWindowInsetsListener { _, insets ->
                if (Build.VERSION.SDK_INT >= 30) {
                    val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                    root.setPadding(dp(24) + bars.left, dp(24) + bars.top, dp(24) + bars.right, dp(24) + bars.bottom)
                } else root.setPadding(dp(24) + insets.systemWindowInsetLeft, dp(24) + insets.systemWindowInsetTop,
                    dp(24) + insets.systemWindowInsetRight, dp(24) + insets.systemWindowInsetBottom)
                insets
            }
            scroll.addView(root, ViewGroup.LayoutParams(-1, -1))
            root.addView(text("HEDGE", 24f, ink, true))
            root.addView(text("Headway Generator · By Mikrotrans Utara", 12f, muted))
            val panel = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL; setPadding(dp(20), dp(20), dp(20), dp(20))
                background = shape(surface, accent)
            }
            root.addView(panel, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(24); bottomMargin = dp(20) })
            stageLabel = text(if (e.stage == "prep") "BERSIAP BERANGKAT" else "WAKTU BERANGKAT", 13f, accent, true)
            panel.addView(stageLabel)
            panel.addView(text(e.unitNumber, 64f, ink, true).apply { contentDescription = "Nomor unit ${e.unitNumber}" })
            countdown = text("", 32f, accent, true); panel.addView(countdown)
            val time = SimpleDateFormat("HH:mm", Locale("id", "ID")).apply { timeZone = TimeZone.getTimeZone("Asia/Jakarta") }
            panel.addView(text("${time.format(Date(e.departureAt))} WIB", 18f, ink))
            panel.addView(text("${e.routeName} · Ritase ${e.round}", 14f, muted, true))
            if (events.size > 1) panel.addView(text("${events.size} alert aktif · alert berikutnya tampil setelah ini ditutup", 12f, muted))
            remaining = text("", 13f, muted); root.addView(remaining)
            root.addView(Button(this).apply {
                text = "Sudah Berangkat"; textSize = 18f; isAllCaps = false
                setTextColor(Color.rgb(7, 11, 18)); background = shape(amber)
                minHeight = dp(56); contentDescription = "Catat unit ${e.unitNumber} sudah berangkat"
                setOnClickListener {
                    try { AlarmEngine.complete(this@AlarmActivity, e); currentKey = null }
                    catch (error: Exception) { Toast.makeText(this@AlarmActivity, "Aktual belum tersimpan: ${error.message}", Toast.LENGTH_LONG).show() }
                }
            }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(16) })
            root.addView(text("Tombol ini mencatat keberangkatan aktual. Menutup otomatis tidak mencatat aktual.", 12f, muted))
            root.addView(Button(this).apply {
                text = "Matikan alarm rute"; textSize = 14f; isAllCaps = false
                setTextColor(ink); background = shape(surface, muted); minHeight = dp(48)
                setOnClickListener {
                    try { AlarmEngine.disableRoute(this@AlarmActivity, e.routeId); currentKey = null }
                    catch (error: Exception) { Toast.makeText(this@AlarmActivity, "Alarm belum dimatikan: ${error.message}", Toast.LENGTH_LONG).show() }
                }
            }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(16) })
            setContentView(scroll)
            scroll.requestApplyInsets()
        }
        val secs = ((e.departureAt - now + 999) / 1000).coerceAtLeast(0)
        countdown.text = if (secs == 0L) "00:00" else "%02d:%02d".format(secs / 60, secs % 60)
        stageLabel.text = if (secs == 0L) "WAKTU BERANGKAT" else "BERSIAP BERANGKAT"
        remaining.text = "Menutup otomatis dalam ${((item.expiresAt - now + 999) / 1000).coerceAtLeast(0)} detik"
    }
}