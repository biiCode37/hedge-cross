package id.mikrotrans.hedge.hedge_flutter

import org.junit.Assert.*
import org.junit.Test

class AlarmTimelineTest {
    private fun event(stage: String = "due", at: Long = 10000, dep: String = "dep", route: String = "route") =
        AlarmSpec("$dep:$stage", route, "revision", dep, "JAK.115", "1001", stage,
            at, 10000, 2, 15, true, true, true, true, "dark")
    @Test fun exactBoundaryAndNoDuplicateDelivery() {
        val e = event()
        assertTrue(AlarmTimeline.due(listOf(e), emptySet(), emptySet(), emptySet(), 9999).isEmpty())
        assertEquals(listOf(e), AlarmTimeline.due(listOf(e), emptySet(), emptySet(), emptySet(), 10000))
        assertTrue(AlarmTimeline.due(listOf(e), setOf(e.key), emptySet(), emptySet(), 10001).isEmpty())
    }
    @Test fun actualAndOffSuppressBothStages() {
        val plan = listOf(event("prep", 0), event())
        assertTrue(AlarmTimeline.due(plan, emptySet(), setOf("dep"), emptySet(), 10000).isEmpty())
        assertTrue(AlarmTimeline.due(plan, emptySet(), emptySet(), setOf("route"), 10000).isEmpty())
        assertNull(AlarmTimeline.next(plan, emptyList(), emptySet(), setOf("dep"), emptySet(), 0))
    }
    @Test fun schedulesPastRollingHorizonWithoutFlutter() {
        val plan = (0..100).map { event(at = 10000L + it * 60000, dep = "d$it") }
        val delivered = plan.take(90).map { it.key }.toSet()
        assertEquals(plan[90].at, AlarmTimeline.next(plan, emptyList(), delivered, emptySet(), emptySet(), 1))
    }
    @Test fun expiryCompetesWithNextDepartureAndDoesNotImplyActual() {
        val e = event("prep", 0)
        val active = listOf(ActiveAlarm(e, 0))
        assertEquals(15000L, active.first().expiresAt)
        assertEquals(10000L, AlarmTimeline.next(listOf(event()), active, emptySet(), emptySet(), emptySet(), 1))
        assertEquals(15000L, AlarmTimeline.next(emptyList(), active, emptySet(), emptySet(), emptySet(), 1))
        assertTrue(AlarmTimeline.visible(active, 15000).isEmpty())
        assertEquals(listOf(event()), AlarmTimeline.due(listOf(event()), emptySet(), emptySet(), emptySet(), 15000))
    }
    @Test fun duePriorityAndSimultaneousRoutes() {
        val prep = ActiveAlarm(event("prep", 0), 0)
        val due = ActiveAlarm(event(dep = "other", route = "other-route"), 10000)
        assertEquals(due, AlarmTimeline.visible(listOf(prep, due), 10001).first())
        assertEquals(2, AlarmTimeline.due(listOf(event(), event(dep = "other", route = "other-route")),
            emptySet(), emptySet(), emptySet(), 10000).size)
    }
    @Test fun staleSnapshotCannotUndoOffAndUserCanEnableAfterPersistence() {
        val stale = AlarmTimeline.reconcileOff(setOf("route"), emptySet(), emptySet(), mapOf("route" to true))
        assertEquals(setOf("route"), stale.disabled)
        val saved = AlarmTimeline.reconcileOff(stale.disabled, stale.confirmed, emptySet(), mapOf("route" to false))
        assertEquals(setOf("route"), saved.confirmed)
        val enabled = AlarmTimeline.reconcileOff(saved.disabled, saved.confirmed, emptySet(), mapOf("route" to true))
        assertTrue(enabled.disabled.isEmpty())
        val pending = AlarmTimeline.reconcileOff(saved.disabled, saved.confirmed, setOf("route"), mapOf("route" to true))
        assertEquals(setOf("route"), pending.disabled)
    }
    @Test fun actualSuppressionIsRetainedUntilSQLiteConfirmsTheAction() {
        assertEquals(setOf("dep"), AlarmTimeline.retainCompleted(setOf("dep"), emptySet(), emptySet()))
        assertEquals(setOf("dep"), AlarmTimeline.retainCompleted(setOf("dep"), setOf("dep"), setOf("dep")))
        assertTrue(AlarmTimeline.retainCompleted(setOf("dep"), emptySet(), setOf("dep")).isEmpty())
    }
    @Test fun shortDisplayDurationDoesNotDropSlightlyLateDelivery() {
        val e = event().copy(durationSeconds = 1)
        assertTrue(AlarmTimeline.canSurface(e, 12000))
        assertFalse(AlarmTimeline.canSurface(e, 70000))
        assertFalse(AlarmTimeline.canSurface(event("prep", 0), 10000))
        assertTrue(AlarmTimeline.canSurface(event("prep", 0), 9999))
    }
}