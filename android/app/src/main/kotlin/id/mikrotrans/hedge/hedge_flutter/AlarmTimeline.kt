package id.mikrotrans.hedge.hedge_flutter

data class AlarmSpec(
    val key: String, val routeId: String, val revisionId: String, val departureId: String,
    val routeName: String, val unitNumber: String, val stage: String,
    val at: Long, val departureAt: Long, val round: Int, val durationSeconds: Int,
    val banner: Boolean, val fullScreen: Boolean, val sound: Boolean,
    val vibration: Boolean, val theme: String
)
data class ActiveAlarm(val event: AlarmSpec, val shownAt: Long) {
    val expiresAt: Long get() = shownAt + event.durationSeconds.coerceIn(1, 300) * 1000L
}
data class AlarmOffState(val disabled: Set<String>, val confirmed: Set<String>)
object AlarmTimeline {
    // Display duration and delivery freshness are separate: a one-second alert may arrive two seconds late.
    fun canSurface(e: AlarmSpec, now: Long): Boolean = now >= e.at &&
        if (e.stage == "prep") now < e.departureAt else now - e.at < 60000L
    fun reconcileOff(disabled: Set<String>, confirmed: Set<String>, pendingOff: Set<String>, enabled: Map<String, Boolean>): AlarmOffState {
        val nextConfirmed = (confirmed + disabled.filter { enabled[it] == false }).toMutableSet()
        val nextDisabled = disabled.filterNot { it !in pendingOff && it in nextConfirmed && enabled[it] == true }.toSet()
        nextConfirmed.retainAll(nextDisabled)
        return AlarmOffState(nextDisabled, nextConfirmed)
    }
    fun retainCompleted(completed: Set<String>, unaccepted: Set<String>, actualInSQLite: Set<String>): Set<String> =
        completed.filter { it in unaccepted || it !in actualInSQLite }.toSet()
    fun due(plan: List<AlarmSpec>, delivered: Set<String>, completed: Set<String>,
            disabled: Set<String>, now: Long): List<AlarmSpec> = plan
        .filter { it.at <= now && it.key !in delivered && it.departureId !in completed && it.routeId !in disabled }
        .sortedWith(compareBy<AlarmSpec> { it.at }.thenBy { it.key })
    fun next(plan: List<AlarmSpec>, active: List<ActiveAlarm>, delivered: Set<String>,
             completed: Set<String>, disabled: Set<String>, now: Long): Long? =
        (plan.filter { it.at > now && it.key !in delivered && it.departureId !in completed && it.routeId !in disabled }
            .map { it.at } + active.filter { it.expiresAt > now }.map { it.expiresAt }).minOrNull()
    fun visible(active: List<ActiveAlarm>, now: Long): List<ActiveAlarm> = active
        .filter { it.event.fullScreen && it.expiresAt > now }
        .sortedWith(compareBy<ActiveAlarm> { if (it.event.stage == "due") 0 else 1 }
            .thenBy { it.event.at }.thenBy { it.event.key })
}