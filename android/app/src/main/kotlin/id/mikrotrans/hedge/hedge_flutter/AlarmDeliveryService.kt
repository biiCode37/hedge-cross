package id.mikrotrans.hedge.hedge_flutter

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import android.provider.Settings
import java.lang.ref.WeakReference

/** Runs only for an active alarm/preview; the schedule remains in AlarmManager. */
class AlarmDeliveryService : Service() {
    companion object {
        private const val NOTIFICATION = 31002
        private const val CHANNEL = "hedge_alarm_delivery_v1"
        private var running: WeakReference<AlarmDeliveryService>? = null
        fun refreshIfRunning(): Boolean {
            val service = running?.get() ?: return false
            service.handler.post { service.refresh() }
            return true
        }
        fun sync(context: Context, preview: Boolean = false) {
            if (!preview && refreshIfRunning()) return
            val events = AlarmEngine.current(context)
            if (!preview && events.none { it.event.sound || (it.event.fullScreen && Settings.canDrawOverlays(context)) }) return
            val intent = Intent(context, AlarmDeliveryService::class.java).putExtra("preview", preview)
            try {
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
            } catch (error: RuntimeException) {
                AlarmEngine.deliveryIssue(context, "Android belum mengizinkan layanan alarm: ${error.message}")
            }
        }
        fun stopPreview() { running?.get()?.let { it.handler.post { it.preview = null; it.refresh() } } }
    }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var overlay: AlarmOverlay
    private var speech: AlarmSpeechPlayer? = null
    private var preview: ActiveAlarm? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var awakeUntil = 0L
    private var foregroundTypes = -1
    private val tick = Runnable { refresh() }
    override fun onCreate() {
        super.onCreate(); running = WeakReference(this); overlay = AlarmOverlay(this)
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.getBooleanExtra("preview", false) == true) {
            val now = System.currentTimeMillis()
            preview = ActiveAlarm(AlarmSpec("preview:$now", "preview", "preview", "preview", "JAK.115", "1865",
                "due", now, now, 1, 20, false, false, true, false, "dark"), now)
        }
        refresh()
        return START_STICKY
    }
    private fun foreground(events: List<ActiveAlarm>): Boolean {
        val types = if (Build.VERSION.SDK_INT >= 34) {
            (if (events.any { it.event.sound }) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK else 0) or
                (if (events.any { it.event.fullScreen }) ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0)
        } else if (Build.VERSION.SDK_INT >= 29 && events.any { it.event.sound }) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK else 0
        if (foregroundTypes == types) return true
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL,
            "Layanan alert HEDGE", NotificationManager.IMPORTANCE_LOW).apply { setSound(null, null); enableVibration(false) })
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        val open = PendingIntent.getActivity(this, NOTIFICATION, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = builder.setSmallIcon(R.drawable.ic_stat_hedge).setContentTitle("HEDGE · Alarm aktif")
            .setContentText("Alert dan suara mengikuti pengaturan rute.").setOngoing(true).setOnlyAlertOnce(true)
            .setContentIntent(open).setCategory(Notification.CATEGORY_SERVICE).build()
        return try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(NOTIFICATION, notification, types) else startForeground(NOTIFICATION, notification)
            foregroundTypes = types; true
        } catch (error: RuntimeException) {
            AlarmEngine.deliveryIssue(this, "Layanan alarm tidak dapat aktif: ${error.message}")
            stopSelf(); false
        }
    }
    private fun refresh() {
        handler.removeCallbacks(tick)
        val now = System.currentTimeMillis()
        val alarms = AlarmEngine.current(this)
        val test = preview?.takeIf { it.expiresAt > now && alarms.none { alarm -> alarm.event.sound } }
        preview = test
        val events = alarms + listOfNotNull(test)
        if (events.none { it.event.sound || (it.event.fullScreen && Settings.canDrawOverlays(this)) }) {
            overlay.close(); speech?.close(); speech = null
            stopForeground(STOP_FOREGROUND_REMOVE); stopSelf(); return
        }
        if (!foreground(events)) return
        val latestExpiry = events.maxOf { it.expiresAt }
        if (latestExpiry > awakeUntil) {
            if (wakeLock == null) wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "HEDGE:activeAlarm").apply { setReferenceCounted(false) }
            wakeLock?.acquire((latestExpiry - now + 1000).coerceIn(1000, 301000)); awakeUntil = latestExpiry
        }
        overlay.update(AlarmTimeline.visible(alarms, now))
        if (events.any { it.event.sound }) {
            if (speech == null) speech = AlarmSpeechPlayer(this)
            speech?.update(events)
        } else { speech?.close(); speech = null }
        handler.postDelayed(tick, 250)
    }
    override fun onDestroy() {
        if (running?.get() === this) running = null
        handler.removeCallbacksAndMessages(null)
        overlay.close(); speech?.close(); speech = null
        wakeLock?.let { if (it.isHeld) it.release() }; wakeLock = null
        super.onDestroy()
    }
}
