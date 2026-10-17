package id.mikrotrans.hedge.hedge_flutter

import org.junit.Assert.*
import org.junit.Test

class AlarmSpeechTextTest {
    private fun event(stage: String = "due", unit: String = "1865", key: String = stage) = AlarmSpec(
        key, "route", "revision", "departure", "JAK.115", unit, stage, 0, 10000, 1, 20,
        true, true, true, true, "dark",
        prepTemplate = "Segera berangkat, Rute {rute}, unit {unit}, berangkat dalam {detik} detik.",
        dueTemplate = "Rute {rute}, unit {unit}, saatnya berangkat.",
        isMultiRoute = true
    )

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
    @Test fun routeApprovedTwoDigitsRules() {
        // Belasan tetap disebut belasan
        assertEquals("JAK lima belas", AlarmSpeechText.route("JAK.15"))
        assertEquals("JAK sebelas", AlarmSpeechText.route("JAK.11"))
        assertEquals("JAK sembilan belas", AlarmSpeechText.route("JAK.19"))
        // Puluhan dibaca puluhan
        assertEquals("JAK sembilan puluh", AlarmSpeechText.route("JAK.90"))
        assertEquals("JAK sepuluh", AlarmSpeechText.route("JAK.10"))
        assertEquals("JAK dua puluh", AlarmSpeechText.route("JAK.20"))
        assertEquals("JAK delapan puluh", AlarmSpeechText.route("JAK.80"))
        // Selain belasan/puluhan dibaca satuan
        assertEquals("JAK tujuh enam", AlarmSpeechText.route("JAK.76"))
        assertEquals("JAK delapan delapan", AlarmSpeechText.route("JAK.88"))
        assertEquals("JAK dua satu", AlarmSpeechText.route("JAK.21"))
        assertEquals("JAK nol satu", AlarmSpeechText.route("JAK.01"))
        // Selain 2 digit tetap dibaca sesuai
        assertEquals("JAK 115", AlarmSpeechText.route("JAK.115"))
        assertEquals("JAK 5", AlarmSpeechText.route("JAK.5"))
        assertEquals("JAK 10A", AlarmSpeechText.route("JAK.10A"))
    }
    @Test fun exactApprovedWordingAndRemainingTimeAtSpeechStart() {
        assertEquals("Segera berangkat, Rute JAK 115, unit delapan belas enam lima, berangkat dalam 7 detik.",
            AlarmSpeechText.message(event("prep"), 3001))
        assertEquals("Rute JAK 115, unit delapan belas enam lima, saatnya berangkat.", AlarmSpeechText.message(event(), 10000))
        val eventJak76 = event().copy(routeName = "JAK.76")
        assertEquals("Rute JAK tujuh enam, unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventJak76, 10000))
        val eventJak15 = event().copy(routeName = "JAK.15")
        assertEquals("Rute JAK lima belas, unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventJak15, 10000))
        val eventJak90 = event().copy(routeName = "JAK.90")
        assertEquals("Rute JAK sembilan puluh, unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventJak90, 10000))
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

    @Test fun customTemplateParsingAndPlaceholders() {
        val eventMulti = AlarmSpec("k", "r", "rev", "d", "JAK.115 — Tanjung Priok", "MJU-01865",
            "due", 0, 10000, 2, 20, true, true, true, true, "dark",
            prepTemplate = "{rute} unit {unit}, {detik} detik lagi.",
            dueTemplate = "{rute} unit {unit}, saatnya berangkat.",
            isMultiRoute = true)
        
        // Multi-route: includes route code
        assertEquals("JAK 115 unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventMulti, 10000))

        // Single-route: omits route cleanly without leading comma/spaces
        val eventSingle = eventMulti.copy(
            isMultiRoute = false,
            dueTemplate = "{rute}, unit {unit}, jalan!"
        )
        assertEquals("Unit delapan belas enam lima, jalan!",
            AlarmSpeechText.message(eventSingle, 10000))
    }

    @Test fun unitLast4DigitExtraction() {
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("1865"))
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("01865"))
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("MJU-01865"))
        assertEquals("dua dua tiga belas", AlarmSpeechText.unitLast4("TS-002213"))
        assertEquals("tujuh enam", AlarmSpeechText.unitLast4("76"))
        assertEquals("CAD", AlarmSpeechText.unitLast4("CAD"))
    }

    @Test fun routeCodeCleaning() {
        assertEquals("JAK 115", AlarmSpeechText.routeCode("JAK.115 — Tanjung Priok - Pegangsaan"))
        assertEquals("JAK tujuh enam", AlarmSpeechText.routeCode("JAK.76 — ASMI - Semper"))
        assertEquals("JAK lima belas", AlarmSpeechText.routeCode("JAK.15"))
    }

    @Test fun prepRemainingSecondsCalculation() {
        val eventPrep = AlarmSpec("k", "r", "rev", "d", "JAK.115", "1865",
            "prep", 0, 10000, 1, 20, true, true, true, true, "dark",
            prepTemplate = "{rute} unit {unit}, {detik} detik lagi.",
            isMultiRoute = true)
        assertEquals("JAK 115 unit delapan belas enam lima, 7 detik lagi.",
            AlarmSpeechText.message(eventPrep, 3001))
    }

    @Test fun emptyTemplateFallback() {
        val eventBlank = AlarmSpec("k", "r", "rev", "d", "JAK.115", "1865",
            "due", 0, 10000, 1, 20, true, true, true, true, "dark",
            dueTemplate = "   ", isMultiRoute = false)
        // Must fallback to default ringkas without crashing
        assertEquals("Unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventBlank, 10000))
    }
}
