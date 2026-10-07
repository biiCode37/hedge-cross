package id.mikrotrans.hedge.hedge_flutter

import android.app.*
import android.content.*
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

/** Durable native queue. No Dart isolate or running Flutter Activity is needed at trigger time. */
object AlarmEngine {
    const val PREFS = "hedge_native_alarms_v1"
    const val STATE = "state"
    private const val TICK_REQUEST = 31001
    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun load(c: Context) = JSONObject(prefs(c).getString(STATE, "{}") ?: "{}")
    private fun save(c: Context, s: JSONObject) {
        check(prefs(c).edit().putString(STATE, s.toString()).commit()) { "Antrean alarm belum tersimpan" }
    }
    private fun strings(a: JSONArray?): MutableSet<String> = mutableSetOf<String>().apply {
        if (a != null) for (i in 0 until a.length()) add(a.getString(i))
    }
    private fun objects(a: JSONArray?): List<JSONObject> = if (a == null) emptyList()
        else (0 until a.length()).map { a.getJSONObject(it) }
    private fun spec(j: JSONObject) = AlarmSpec(j.getString("key"), j.getString("routeId"),
        j.getString("revisionId"), j.getString("departureId"), j.getString("routeName"),
        j.getString("unitNumber"), j.getString("stage"), j.getLong("at"), j.getLong("departureAt"),
        j.getInt("round"), j.getInt("durationSeconds").coerceIn(1, 300),
        j.optBoolean("banner", true), j.optBoolean("fullScreen", true),
        j.optBoolean("sound", true), j.optBoolean("vibration", true), j.optString("theme", "dark"))
    private fun json(e: AlarmSpec) = JSONObject().put("key", e.key).put("routeId", e.routeId)
        .put("revisionId", e.revisionId).put("departureId", e.departureId)
        .put("routeName", e.routeName).put("unitNumber", e.unitNumber).put("stage", e.stage)
        .put("at", e.at).put("departureAt", e.departureAt).put("round", e.round)
        .put("durationSeconds", e.durationSeconds).put("banner", e.banner).put("fullScreen", e.fullScreen)
        .put("sound", e.sound).put("vibration", e.vibration).put("theme", e.theme)
    private fun plan(s: JSONObject) = objects(s.optJSONArray("plan")).map(::spec)
    private fun active(s: JSONObject) = objects(s.optJSONArray("active")).map {
        ActiveAlarm(spec(it.getJSONObject("event")), it.getLong("shownAt"))
    }
    private fun putActive(s: JSONObject, a: List<ActiveAlarm>) { s.put("active", JSONArray(a.map {
        JSONObject().put("event", json(it.event)).put("shownAt", it.shownAt)
    })) }
    private fun manager(c: Context) = c.getSystemService(NotificationManager::class.java)
    private fun alarmManager(c: Context) = c.getSystemService(AlarmManager::class.java)
    private fun cancel(c: Context, e: AlarmSpec) { manager(c).cancel("hedge:${e.key}", 1) }
    fun canExact(c: Context) = Build.VERSION.SDK_INT < 31 || alarmManager(c).canScheduleExactAlarms()
    fun canFullScreen(c: Context) = Build.VERSION.SDK_INT < 34 || manager(c).canUseFullScreenIntent()
    private fun tickIntent(c: Context) = PendingIntent.getBroadcast(c, TICK_REQUEST,
        Intent(c, AlarmReceiver::class.java).setAction("hedge.alarm.TICK"),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun activityIntent(c: Context, key: String, fullScreen: Boolean = true): PendingIntent {
        val i = Intent(c, if (fullScreen) AlarmActivity::class.java else MainActivity::class.java).setAction("hedge.alarm.OPEN.$key")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val options = if (Build.VERSION.SDK_INT >= 35) ActivityOptions.makeBasic().apply {
            setPendingIntentCreatorBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
        }.toBundle() else null
        return PendingIntent.getActivity(c, 0, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE, options)
    }
    private fun rearm(c: Context, s: JSONObject, force: Boolean = false) {
        val now = System.currentTimeMillis()
        val next = AlarmTimeline.next(plan(s), active(s), strings(s.optJSONArray("delivered")),
            strings(s.optJSONArray("completed")), strings(s.optJSONArray("disabled")), now)
        val exact = canExact(c)
        if (!force && s.optLong("scheduledAt", 0) == (next ?: 0) && s.optBoolean("exact") == exact) return
        val am = alarmManager(c)
        am.cancel(tickIntent(c))
        s.put("scheduledAt", next ?: 0).put("exact", exact)
        save(c, s)
        if (next == null) return
        try {
            if (exact) {
                val show = PendingIntent.getActivity(c, TICK_REQUEST,
                    Intent(c, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                am.setAlarmClock(AlarmManager.AlarmClockInfo(next, show), tickIntent(c))
            } else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, tickIntent(c))
        } catch (e: SecurityException) {
            s.put("exact", false).put("lastError", "Izin alarm tepat dicabut")
            save(c, s)
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, tickIntent(c))
        }
    }
    @Synchronized fun replace(c: Context, payload: JSONObject): Map<String, Any> {
        val s = load(c)
        val routes = objects(payload.optJSONArray("routes")).associateBy { it.getString("id") }
        val disabled = strings(s.optJSONArray("disabled"))
        val pendingOff = objects(s.optJSONArray("actions")).filter { it.optString("kind") == "disableAlarm" }
            .map { it.getString("routeId") }.toSet()
        // A stale queued Flutter snapshot must not undo native OFF before SQLite confirms it.
        val off = AlarmTimeline.reconcileOff(disabled, strings(s.optJSONArray("confirmedOff")), pendingOff,
            routes.mapValues { it.value.optBoolean("enabled", false) })
        disabled.clear(); disabled.addAll(off.disabled)
        s.put("confirmedOff", JSONArray(off.confirmed.toList()))
        s.put("disabled", JSONArray(disabled.toList()))
        val kept = active(s).mapNotNull { a ->
            val r = routes[a.event.routeId]
            val stageEnabled = r?.optBoolean(if (a.event.stage == "prep") "preparation" else "departure", false) == true
            val valid = r != null && r.optBoolean("enabled", false) && stageEnabled &&
                a.event.departureId in strings(r.optJSONArray("departures")) && a.event.routeId !in disabled
            if (!valid) { cancel(c, a.event); null } else a.copy(event = a.event.copy(
                fullScreen = r!!.optBoolean("fullScreen"), banner = r.optBoolean("banner"),
                sound = r.optBoolean("sound", true), vibration = r.optBoolean("vibration", true), durationSeconds = r.optInt("durationSeconds", 8).coerceIn(1, 300), theme = payload.optString("theme", "dark")))
        }
        putActive(s, kept)
        s.put("plan", payload.getJSONArray("events"))
        // Completed IDs stay until the pending action is accepted by SQLite.
        val keepKeys = plan(s).map { it.key }.toSet() + kept.map { it.event.key }
        s.put("delivered", JSONArray(strings(s.optJSONArray("delivered")).filter { it in keepKeys }))
        s.put("spoken", JSONArray(strings(s.optJSONArray("spoken")).filter { it in keepKeys }))
        val unaccepted = objects(s.optJSONArray("actions")).filter { it.optString("kind") == "departed" }.map { it.optString("departureId") }.toSet()
        val actualInSQLite = strings(payload.optJSONArray("actual"))
        s.put("completed", JSONArray(AlarmTimeline.retainCompleted(strings(s.optJSONArray("completed")), unaccepted, actualInSQLite).toList()))
        save(c, s)
        tick(c, reboot = true)
        return status(c)
    }
    @Synchronized fun tick(c: Context, reboot: Boolean = false) {
        val s = load(c)
        val now = System.currentTimeMillis()
        val disabled = strings(s.optJSONArray("disabled"))
        val completed = strings(s.optJSONArray("completed"))
        val delivered = strings(s.optJSONArray("delivered"))
        val current = active(s).filter { a ->
            val keep = a.expiresAt > now && a.event.routeId !in disabled && a.event.departureId !in completed
            if (!keep) cancel(c, a.event)
            keep
        }.toMutableList()
        val due = AlarmTimeline.due(plan(s), delivered, completed, disabled, now)
        val toShow = mutableListOf<ActiveAlarm>()
        for (event in due) {
            delivered.add(event.key)
            // Never replay historical alarms after a reboot, clock jump or prolonged delayed delivery.
            if (!AlarmTimeline.canSurface(event, now)) continue
            if (event.stage == "due") {
                val oldPrep = current.filter { it.event.departureId == event.departureId && it.event.stage == "prep" }
                oldPrep.forEach { cancel(c, it.event) }
                current.removeAll(oldPrep.toSet())
            }
            val item = ActiveAlarm(event, now)
            current.add(item); toShow.add(item)
        }
        putActive(s, current)
        s.put("delivered", JSONArray(delivered.toList()))
        // The pending OS alarm just fired; it must be recreated even when the next timestamp happens to match.
        if (reboot) s.put("scheduledAt", 0)
        save(c, s)
        for (item in toShow) show(c, item)
        rearm(c, s, reboot)
        if (toShow.any { it.event.fullScreen }) openWhenForeground(c)
        AlarmDeliveryService.sync(c)
    }
    private fun show(c: Context, a: ActiveAlarm) {
        val e = a.event
        if (!manager(c).areNotificationsEnabled()) return
        val channelId = "hedge_alarm_v4_${if (e.fullScreen) "full" else "banner"}_${if (e.sound) "sound" else "silent"}_${if (e.vibration) "vibrate" else "still"}"
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(channelId, if (e.fullScreen) "Alert keberangkatan layar penuh" else "Banner keberangkatan",
                NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Pengingat dispatcher HEDGE; peringatan suara dikelola terpadu oleh pemutar audio."
                setSound(null, null)
                enableVibration(e.vibration); lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager(c).createNotificationChannel(channel)
        }
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, channelId) else Notification.Builder(c)
        val open = activityIntent(c, e.key, e.fullScreen)
        builder.setSmallIcon(R.drawable.ic_stat_hedge).setColor(0xFFFF9800.toInt())
            .setContentTitle("${e.routeName} · Unit ${e.unitNumber}")
            .setContentText(if (e.stage == "prep") "Bersiap · keberangkatan segera" else "Waktu berangkat · Ritase ${e.round}")
            .setCategory(Notification.CATEGORY_ALARM).setPriority(Notification.PRIORITY_MAX)
            .setVisibility(Notification.VISIBILITY_PUBLIC).setContentIntent(open)
            .setOngoing(e.fullScreen).setAutoCancel(!e.fullScreen).setOnlyAlertOnce(true)
        if (e.fullScreen && canFullScreen(c)) builder.setFullScreenIntent(open, true)
        if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(e.durationSeconds * 1000L)
        else {
            if (e.vibration) builder.setVibrate(longArrayOf(0, 300, 150, 300))
        }
        try { manager(c).notify("hedge:${e.key}", 1, builder.build()) }
        catch (_: SecurityException) { /* OS permission revoked; foreground Activity still works. */ }
    }
    @Synchronized fun visible(c: Context): List<ActiveAlarm> = AlarmTimeline.visible(current(c), System.currentTimeMillis())
    fun openWhenForeground(c: Context) {
        val activity = MainActivity.foreground?.get() ?: return
        if (visible(c).isNotEmpty() && !activity.isFinishing) activity.startActivity(Intent(c, AlarmActivity::class.java))
    }
    @Synchronized fun complete(c: Context, event: AlarmSpec) {
        val s = load(c)
        val completed = strings(s.optJSONArray("completed"))
        if (completed.add(event.departureId)) {
            val actions = s.optJSONArray("actions") ?: JSONArray()
            actions.put(JSONObject().put("id", UUID.randomUUID().toString()).put("kind", "departed")
                .put("routeId", event.routeId).put("departureId", event.departureId)
                .put("revisionId", event.revisionId).put("at", Instant.now().toString()))
            s.put("actions", actions).put("completed", JSONArray(completed.toList()))
        }
        val removed = active(s).filter { it.event.departureId == event.departureId }
        putActive(s, active(s).filter { it.event.departureId != event.departureId })
        save(c, s); removed.forEach { cancel(c, it.event) }; rearm(c, s, true)
        AlarmDeliveryService.refreshIfRunning()
    }
    @Synchronized fun disableRoute(c: Context, routeId: String) {
        val s = load(c)
        val disabled = strings(s.optJSONArray("disabled"))
        disabled.add(routeId)
        val actions = s.optJSONArray("actions") ?: JSONArray()
        actions.put(JSONObject().put("id", UUID.randomUUID().toString()).put("kind", "disableAlarm")
            .put("routeId", routeId).put("at", Instant.now().toString()))
        s.put("disabled", JSONArray(disabled.toList())).put("actions", actions)
        val removed = active(s).filter { it.event.routeId == routeId }
        putActive(s, active(s).filter { it.event.routeId != routeId })
        save(c, s); removed.forEach { cancel(c, it.event) }; rearm(c, s, true)
        AlarmDeliveryService.refreshIfRunning()
    }
    @Synchronized fun pendingActions(c: Context): String = (load(c).optJSONArray("actions") ?: JSONArray()).toString()
    @Synchronized fun acceptActions(c: Context, ids: Set<String>) {
        val s = load(c)
        s.put("actions", JSONArray(objects(s.optJSONArray("actions")).filter { it.getString("id") !in ids }))
        save(c, s)
    }
    private var snapshotRaw: String? = null
    private var snapshotActive = emptyList<ActiveAlarm>()
    private var snapshotSpoken = emptySet<String>()
    private fun readPresentationSnapshot(c: Context) {
        val raw = prefs(c).getString(STATE, "{}") ?: "{}"
        if (raw != snapshotRaw) {
            val state = JSONObject(raw)
            snapshotActive = active(state)
            snapshotSpoken = strings(state.optJSONArray("spoken"))
            snapshotRaw = raw
        }
    }
    @Synchronized fun current(c: Context): List<ActiveAlarm> {
        readPresentationSnapshot(c)
        return snapshotActive.filter { it.expiresAt > System.currentTimeMillis() }
    }
    @Synchronized fun spoken(c: Context): Set<String> { readPresentationSnapshot(c); return snapshotSpoken }
    @Synchronized fun markSpoken(c: Context, key: String) {
        val s = load(c)
        val spoken = strings(s.optJSONArray("spoken"))
        if (spoken.add(key)) { s.put("spoken", JSONArray(spoken.toList())); save(c, s) }
    }
    private fun diagnostics(c: Context) = c.getSharedPreferences("hedge_alarm_diagnostics", Context.MODE_PRIVATE)
    fun deliveryIssue(c: Context, message: String) {
        if (diagnostics(c).getString("issue", "") != message) diagnostics(c).edit().putString("issue", message).apply()
    }
    fun speechStatus(c: Context, status: String, voice: String) {
        diagnostics(c).edit().putString("speechStatus", status).putString("voice", voice).apply()
    }
    @Synchronized fun status(c: Context): Map<String, Any> {
        val s = load(c)
        val delivered = strings(s.optJSONArray("delivered"))
        val completed = strings(s.optJSONArray("completed"))
        val disabled = strings(s.optJSONArray("disabled"))
        val restricted = if (Build.VERSION.SDK_INT >= 26) manager(c).notificationChannels.count {
            it.id.startsWith("hedge_alarm_v4_") && it.importance < NotificationManager.IMPORTANCE_HIGH
        } else 0
        val audioManager = c.getSystemService(AudioManager::class.java)
        val streamVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val streamVolMax = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        return mapOf("overlay" to Settings.canDrawOverlays(c), "speechStatus" to (diagnostics(c).getString("speechStatus", "Belum diuji") ?: ""),
            "voice" to (diagnostics(c).getString("voice", "") ?: ""), "audioIssue" to (diagnostics(c).getString("issue", "") ?: ""),
            "alarmVolume" to streamVol, "alarmVolumeMax" to streamVolMax,
            "restrictedChannels" to restricted, "notifications" to manager(c).areNotificationsEnabled(), "exact" to canExact(c),
            "fullScreen" to canFullScreen(c), "pending" to plan(s).count {
                it.key !in delivered && it.departureId !in completed && it.routeId !in disabled && it.at > System.currentTimeMillis()
            })
    }
    fun permissionSettings(activity: Activity, kind: String) {
        val data = Uri.parse("package:${activity.packageName}")
        val intent = when (kind) {
            "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, data)
            "tts" -> Intent("com.android.settings.TTS_SETTINGS")
            "sound" -> Intent(Settings.ACTION_SOUND_SETTINGS)
            "exact" -> if (Build.VERSION.SDK_INT >= 31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, data) else null
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, data) else null
            else -> if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, data)
        }
        if (intent != null) activity.startActivity(intent)
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val boot = intent.action != "hedge.alarm.TICK"
        AlarmEngine.tick(context, reboot = boot)
    }
}