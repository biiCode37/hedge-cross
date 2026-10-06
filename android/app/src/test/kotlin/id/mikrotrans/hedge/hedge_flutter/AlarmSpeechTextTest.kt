package id.mikrotrans.hedge.hedge_flutter

import org.junit.Assert.*
import org.junit.Test

class AlarmSpeechTextTest {
    private fun event(stage: String = "due", unit: String = "1865", key: String = stage) = AlarmSpec(
        key, "route", "revision", "departure", "JAK.115", unit, stage, 0, 10000, 1, 20,
        true, true, true, true, "dark")
    @Test fun approvedUnitExamples() {
        val expected = mapOf("1865" to "delapan belas enam lima", "2213" to "dua dua tiga belas",
            "1870" to "delapan belas tujuh puluh", "630" to "enam tiga puluh")
        expected.forEach { (unit, words) -> assertEquals(unit, words, AlarmSpeechText.unit(unit)) }
    }
    @Test fun approvedTailTakesPrecedenceOverAmbiguousPrefix() {
        assertEquals("satu sebelas", AlarmSpeechText.unit("111"))
        assertEquals("dua satu tiga belas", AlarmSpeechText.unit("2113"))
        assertEquals("sebelas tiga belas", AlarmSpeechText.unit("1113"))
    }
    @Test fun identifiersPreserveZerosAndLettersWithoutHundredsOrThousands() {
        assertEquals("nol nol satu", AlarmSpeechText.unit("001"))
        assertEquals("B delapan belas tujuh puluh SX", AlarmSpeechText.unit("B-1870-SX"))
        assertEquals("dua tiga empat lima", AlarmSpeechText.unit("2345"))
        assertEquals("nol", AlarmSpeechText.unit("0"))
    }
    @Test fun tailTensAndTeens() {
        assertEquals("sepuluh", AlarmSpeechText.unit("10"))
        assertEquals("sebelas", AlarmSpeechText.unit("11"))
        assertEquals("sembilan puluh", AlarmSpeechText.unit("90"))
        assertEquals("satu nol tujuh puluh", AlarmSpeechText.unit("1070"))
    }
    @Test fun exactApprovedWordingAndRemainingTimeAtSpeechStart() {
        assertEquals("Segera berangkat, Rute JAK 115, unit delapan belas enam lima, berangkat dalam 7 detik.",
            AlarmSpeechText.message(event("prep"), 3001))
        assertEquals("Rute JAK 115, unit delapan belas enam lima, saatnya berangkat.", AlarmSpeechText.message(event(), 10000))
    }
    @Test fun latePreparationIsNotSpokenAsDepartureOrZeroSeconds() {
        assertNull(AlarmSpeechText.message(event("prep"), 10000))
        assertTrue(AlarmSpeechText.message(event("prep"), 9999)!!.contains("1 detik"))
    }
    @Test fun queuePrioritizesDueAndNeverOverlapsOrRepeatsSpokenEvents() {
        val prep = ActiveAlarm(event("prep"), 0)
        val due = ActiveAlarm(event(), 0)
        assertEquals(due, AlarmSpeechText.next(listOf(prep, due), emptySet(), 1))
        assertEquals(prep, AlarmSpeechText.next(listOf(prep, due), setOf("due"), 1))
        assertNull(AlarmSpeechText.next(listOf(prep, due), setOf("prep", "due"), 1))
    }
    @Test fun silentExpiredRemovedAndSupersededEventsNeverSpeak() {
        val due = ActiveAlarm(event(), 0)
        assertNull(AlarmSpeechText.next(listOf(due), emptySet(), 20000))
        assertNull(AlarmSpeechText.next(listOf(due.copy(event = due.event.copy(sound = false))), emptySet(), 1))
        assertNull(AlarmSpeechText.next(emptyList(), emptySet(), 1))
        assertNull(AlarmSpeechText.next(listOf(ActiveAlarm(event("prep"), 0)), emptySet(), 10000))
    }
}
