package id.mikrotrans.hedge.hedge_flutter

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Circular HUD Dial Gauge View replicating the Cyber-Transit clock dial in native Android. */
class CyberDialGaugeView(context: Context) : View(context) {
    var stage: String = "due"
    var countdownText: String = "00:00"
    var accentColor: Int = Color.rgb(255, 152, 0)
    var isDark: Boolean = true
    var timeoutProgress: Float = 1.0f

    private fun dp(n: Float) = n * resources.displayMetrics.density
    private fun sp(n: Float) = n * resources.displayMetrics.scaledDensity

    private val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val size = dp(200f).toInt()
        setMeasuredDimension(size, size)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val cx = width / 2f
        val cy = height / 2f
        val radius = (width / 2f) - dp(10f)

        // Outer glow/track circle
        trackPaint.color = accentColor
        trackPaint.alpha = if (isDark) 45 else 30
        trackPaint.strokeWidth = dp(12f)
        canvas.drawCircle(cx, cy, radius - dp(2f), trackPaint)

        // Inner solid circular background
        fillPaint.color = if (isDark) Color.rgb(10, 15, 24) else Color.rgb(241, 245, 249)
        canvas.drawCircle(cx, cy, radius - dp(8f), fillPaint)

        // 12 Radar ticks
        trackPaint.alpha = if (isDark) 70 else 50
        trackPaint.strokeWidth = dp(1.5f)
        for (i in 0 until 12) {
            val angle = Math.toRadians((i * 30).toDouble())
            val rIn = radius - dp(14f)
            val rOut = radius - dp(8f)
            val x1 = cx + (rIn * Math.cos(angle)).toFloat()
            val y1 = cy + (rIn * Math.sin(angle)).toFloat()
            val x2 = cx + (rOut * Math.cos(angle)).toFloat()
            val y2 = cy + (rOut * Math.sin(angle)).toFloat()
            canvas.drawLine(x1, y1, x2, y2, trackPaint)
        }

        // Concentric inner ring
        trackPaint.alpha = if (isDark) 60 else 40
        trackPaint.strokeWidth = dp(1f)
        canvas.drawCircle(cx, cy, radius - dp(16f), trackPaint)

        // Main accent circle ring
        trackPaint.alpha = if (isDark) 210 else 230
        trackPaint.strokeWidth = dp(2.5f)
        canvas.drawCircle(cx, cy, radius - dp(8f), trackPaint)

        // Timeout progress arc
        if (timeoutProgress in 0f..1f) {
            trackPaint.alpha = 255
            trackPaint.strokeWidth = dp(3.5f)
            val sweep = 360f * timeoutProgress
            val oval = android.graphics.RectF(cx - radius + dp(8f), cy - radius + dp(8f), cx + radius - dp(8f), cy + radius - dp(8f))
            canvas.drawArc(oval, -90f, sweep, false, trackPaint)
        }

        // Top notch marker
        fillPaint.color = accentColor
        canvas.drawCircle(cx, cy - radius + dp(8f), dp(3.5f), fillPaint)

        // Center stage label text ("Waktu berangkat" / "Bersiap berangkat")
        textPaint.color = if (isDark) Color.rgb(148, 163, 184) else Color.rgb(100, 116, 139)
        textPaint.textSize = sp(11.5f)
        textPaint.typeface = Typeface.DEFAULT_BOLD
        val label = if (stage == "prep") "Bersiap berangkat" else "Waktu berangkat"
        canvas.drawText(label, cx, cy - dp(10f), textPaint)

        // Big countdown text
        textPaint.color = accentColor
        textPaint.textSize = sp(32f)
        textPaint.typeface = Typeface.DEFAULT_BOLD
        canvas.drawText(countdownText, cx, cy + dp(22f), textPaint)
    }
}

/** Shared Cyber-Transit HUD presentation for lock-screen Activity and permitted overlay. */
class AlarmSurface(context: Context, private val onSurfaceChanged: () -> Unit = {}) : ScrollView(context) {
    private var currentKey: String? = null
    private lateinit var remaining: TextView
    private lateinit var dialGauge: CyberDialGaugeView
    private lateinit var stageBadge: TextView
    private var dark = true
    val lightTheme get() = !dark
    val surfaceColor get() = if (dark) Color.rgb(7, 11, 18) else Color.rgb(248, 250, 252)
    private val amber = Color.rgb(255, 152, 0)
    private val amberDark = Color.rgb(255, 109, 0)
    private val cyan = Color.rgb(56, 189, 248)
    private fun dp(n: Int) = (n * resources.displayMetrics.density).toInt()
    private fun text(value: String, size: Float, color: Int, bold: Boolean = false): TextView = TextView(context).apply {
        text = value; textSize = size; setTextColor(color)
        typeface = try { Typeface.createFromAsset(context.assets,
            "flutter_assets/assets/fonts/roboto-${if (bold) "bold" else "regular"}.ttf") }
            catch (_: Exception) { if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT }
        setPadding(0, dp(2), 0, dp(2))
    }
    private fun shape(color: Int, border: Int? = null, radiusDp: Float = 16f) = GradientDrawable().apply {
        setColor(color); cornerRadius = dp(radiusDp.toInt()).toFloat()
        if (border != null) setStroke(dp(1), border)
    }
    private fun gradient(c1: Int, c2: Int, radiusDp: Float = 12f) = GradientDrawable(
        GradientDrawable.Orientation.LEFT_RIGHT, intArrayOf(c1, c2)
    ).apply {
        cornerRadius = dp(radiusDp.toInt()).toFloat()
    }

    fun render(events: List<ActiveAlarm>) {
        val item = events.first(); val e = item.event
        val now = System.currentTimeMillis()
        val light = e.theme == "light" || (e.theme == "system" &&
            resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK != Configuration.UI_MODE_NIGHT_YES)
        if (currentKey != "${e.key}:$light:${events.size}:${resources.configuration.fontScale}") {
            currentKey = "${e.key}:$light:${events.size}:${resources.configuration.fontScale}"; dark = !light
            val bg = if (dark) Color.rgb(7, 11, 18) else Color.rgb(248, 250, 252)
            val surface = if (dark) Color.rgb(10, 15, 24) else Color.WHITE
            val ink = if (dark) Color.rgb(248, 250, 252) else Color.rgb(15, 23, 42)
            val muted = if (dark) Color.rgb(148, 163, 184) else Color.rgb(100, 116, 139)
            val isDue = e.stage == "due"
            val accent = if (isDue) (if (dark) amber else Color.rgb(217, 119, 6))
                else (if (dark) cyan else Color.rgb(2, 132, 199))

            val scroll = this.apply { setBackgroundColor(bg); isFillViewport = true }
            val root = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                setPadding(dp(20), dp(16), dp(20), dp(20))
            }
            scroll.setOnApplyWindowInsetsListener { _, insets ->
                if (Build.VERSION.SDK_INT >= 30) {
                    val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                    root.setPadding(dp(20) + bars.left, dp(16) + bars.top, dp(20) + bars.right, dp(20) + bars.bottom)
                } else root.setPadding(dp(20) + insets.systemWindowInsetLeft, dp(16) + insets.systemWindowInsetTop,
                    dp(20) + insets.systemWindowInsetRight, dp(20) + insets.systemWindowInsetBottom)
                insets
            }
            scroll.removeAllViews(); scroll.addView(root, ViewGroup.LayoutParams(-1, -2))

            // --- HEADER ---
            val headerRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }
            val dot = View(context).apply {
                background = GradientDrawable().apply {
                    setColor(accent); shape = GradientDrawable.OVAL
                }
            }
            headerRow.addView(dot, LinearLayout.LayoutParams(dp(8), dp(8)).apply { rightMargin = dp(8) })
            headerRow.addView(text("HEDGE", 20f, ink, true).apply {
                letterSpacing = 0.1f
            }, LinearLayout.LayoutParams(0, -2, 1f))
            if (events.size > 1) {
                val multiBadge = text("${events.size} alert aktif", 10f, amber, true).apply {
                    background = shape(Color.argb(45, 255, 152, 0), null, 6f)
                    setPadding(dp(8), dp(2), dp(8), dp(2))
                }
                headerRow.addView(multiBadge, LinearLayout.LayoutParams(-2, -2))
            }
            root.addView(headerRow, LinearLayout.LayoutParams(-1, -2))

            val subtitle = text("Headway Generator · By Mikrotrans Utara", 11f, muted)
            root.addView(subtitle, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(2) })

            // Neon accent gauge bar
            val neonBar = View(context).apply {
                background = GradientDrawable().apply {
                    setColor(accent); cornerRadius = dp(2).toFloat()
                }
            }
            root.addView(neonBar, LinearLayout.LayoutParams(-1, dp(3)).apply { topMargin = dp(8); bottomMargin = dp(16) })

            // --- CYBERPUNK HUD CARD ---
            val panel = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                setPadding(dp(20), dp(18), dp(20), dp(18))
                background = GradientDrawable().apply {
                    setColor(surface); cornerRadius = dp(20).toFloat()
                    setStroke(dp(2), accent)
                }
            }
            root.addView(panel, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(14) })

            // Capsule status badge
            stageBadge = text(if (isDue) "● WAKTU BERANGKAT" else "● BERSIAP BERANGKAT", 12f, accent, true).apply {
                background = shape(if (dark) Color.rgb(6, 11, 18) else Color.rgb(254, 243, 199), accent, 14f)
                setPadding(dp(14), dp(4), dp(14), dp(4))
                gravity = Gravity.CENTER
            }
            panel.addView(stageBadge, LinearLayout.LayoutParams(-2, -2))

            // Big Hero Unit Number
            val unitView = text(e.unitNumber, 64f, ink, true).apply {
                gravity = Gravity.CENTER
                contentDescription = "Nomor unit ${e.unitNumber}"
            }
            panel.addView(unitView, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(4); bottomMargin = dp(4) })

            // Circular HUD Dial Gauge View
            dialGauge = CyberDialGaugeView(context).apply {
                this.stage = e.stage
                this.accentColor = accent
                this.isDark = dark
            }
            panel.addView(dialGauge, LinearLayout.LayoutParams(dp(200), dp(200)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dp(4); bottomMargin = dp(8)
            })

            // 3 Live Mission Telemetry Cards
            val telemetryRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            fun createBox(label: String, value: String): View {
                return LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setPadding(dp(6), dp(6), dp(6), dp(6))
                    background = shape(if (dark) Color.rgb(12, 16, 23) else Color.rgb(241, 245, 249),
                        if (dark) Color.rgb(30, 41, 59) else Color.rgb(226, 232, 240), 8f)
                    addView(text(label, 9.5f, muted, true).apply { gravity = Gravity.CENTER })
                    addView(text(value, 11.5f, ink, true).apply { gravity = Gravity.CENTER })
                }
            }
            val time = SimpleDateFormat("HH:mm", Locale("id", "ID")).apply { timeZone = TimeZone.getTimeZone("Asia/Jakarta") }
            val timeBox = createBox("JADWAL", "${time.format(Date(e.departureAt))} WIB")
            val routeBox = createBox("RUTE", e.routeName)
            val roundBox = createBox("PUTARAN", "RITASE ${e.round}")
            telemetryRow.addView(timeBox, LinearLayout.LayoutParams(0, -2, 1f).apply { rightMargin = dp(6) })
            telemetryRow.addView(routeBox, LinearLayout.LayoutParams(0, -2, 1f).apply { rightMargin = dp(6) })
            telemetryRow.addView(roundBox, LinearLayout.LayoutParams(0, -2, 1f))
            panel.addView(telemetryRow, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(6) })

            // --- TIMEOUT PILL ---
            remaining = text("", 12f, muted, true).apply {
                background = shape(if (dark) Color.rgb(12, 16, 23) else Color.rgb(241, 245, 249),
                    if (dark) Color.rgb(30, 41, 59) else Color.rgb(226, 232, 240), 10f)
                setPadding(dp(12), dp(8), dp(12), dp(8))
                gravity = Gravity.CENTER
            }
            root.addView(remaining, LinearLayout.LayoutParams(-1, -2))

            val note = text("Sudah Berangkat mencatat aktual. Timeout hanya menutup alert.", 11f, muted).apply {
                gravity = Gravity.CENTER
            }
            root.addView(note, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(6); bottomMargin = dp(16) })

            // --- ACTION BUTTONS (Stacked Thumb-Friendly) ---
            val btnDepart = Button(context).apply {
                text = "✓ Sudah Berangkat"
                textSize = 16f
                isAllCaps = false
                setTextColor(Color.BLACK)
                typeface = Typeface.DEFAULT_BOLD
                background = gradient(amber, amberDark, 12f)
                minHeight = dp(52)
                contentDescription = "Catat unit ${e.unitNumber} sudah berangkat"
                setOnClickListener {
                    try { AlarmEngine.complete(context, e); currentKey = null }
                    catch (error: Exception) { Toast.makeText(context, "Aktual belum tersimpan: ${error.message}", Toast.LENGTH_LONG).show() }
                }
            }
            root.addView(btnDepart, LinearLayout.LayoutParams(-1, -2))

            val btnDismiss = Button(context).apply {
                text = "✕ Tutup Alert"
                textSize = 14f
                isAllCaps = false
                setTextColor(ink)
                typeface = Typeface.DEFAULT_BOLD
                background = shape(if (dark) Color.rgb(12, 16, 23) else Color.rgb(241, 245, 249),
                    if (dark) Color.rgb(51, 65, 85) else Color.rgb(203, 213, 225), 12f)
                minHeight = dp(46)
                setOnClickListener {
                    if (context is Activity) (context as Activity).finish()
                }
            }
            root.addView(btnDismiss, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })

            val btnRouteOff = Button(context).apply {
                text = "Matikan alarm rute"
                textSize = 13f
                isAllCaps = false
                setTextColor(muted)
                background = shape(Color.TRANSPARENT, if (dark) Color.rgb(30, 41, 59) else Color.rgb(226, 232, 240), 12f)
                minHeight = dp(40)
                setOnClickListener {
                    try { AlarmEngine.disableRoute(context, e.routeId); currentKey = null }
                    catch (error: Exception) { Toast.makeText(context, "Alarm belum dimatikan: ${error.message}", Toast.LENGTH_LONG).show() }
                }
            }
            root.addView(btnRouteOff, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })

            onSurfaceChanged()
            scroll.requestApplyInsets()
        }

        val diffSecs = (now - e.departureAt) / 1000
        val countdownText = if (e.stage == "due" && diffSecs > 0) {
            "+%02d:%02d".format(diffSecs / 60, diffSecs % 60)
        } else {
            val left = ((e.departureAt - now + 999) / 1000).coerceAtLeast(0)
            "%02d:%02d".format(left / 60, left % 60)
        }
        val totalSpan = (item.expiresAt - item.event.at).toFloat().coerceAtLeast(1000f)
        val leftSpan = (item.expiresAt - now).toFloat().coerceAtLeast(0f)
        dialGauge.timeoutProgress = (leftSpan / totalSpan).coerceIn(0f, 1f)
        dialGauge.stage = if (diffSecs >= 0 || e.stage == "due") "due" else "prep"
        dialGauge.countdownText = countdownText
        dialGauge.invalidate()

        stageBadge.text = if (diffSecs >= 0 || e.stage == "due") "● WAKTU BERANGKAT" else "● BERSIAP BERANGKAT"
        remaining.text = "Menutup otomatis dalam ${((item.expiresAt - now + 999) / 1000).coerceAtLeast(0)} detik"
    }
}