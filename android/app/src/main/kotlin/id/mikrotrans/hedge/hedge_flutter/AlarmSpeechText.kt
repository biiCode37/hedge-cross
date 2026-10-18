package id.mikrotrans.hedge.hedge_flutter

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AlarmSpeechText {
    private val digits = listOf("nol", "satu", "dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan", "sembilan")
    private fun teen(number: Int) = if (number == 11) "sebelas" else "${digits[number % 10]} belas"

    fun unit(value: String): String = Regex("[0-9]+").replace(value) { match ->
        val number = match.value
        if (number.length == 1) digits[number[0] - '0'] else {
            val words = mutableListOf<String>()
            val prefix = number.dropLast(2)
            var index = 0
            while (index < prefix.length) {
                if (prefix[index] == '1' && index + 1 < prefix.length && prefix[index + 1] in '1'..'9') {
                    words.add(teen(prefix.substring(index, index + 2).toInt())); index += 2
                } else { words.add(digits[prefix[index] - '0']); index++ }
            }
            val tail = number.takeLast(2).toInt()
            when {
                tail == 10 -> words.add("sepuluh")
                tail in 11..19 -> words.add(teen(tail))
                tail in 20..90 && tail % 10 == 0 -> words.add("${digits[tail / 10]} puluh")
                else -> number.takeLast(2).forEach { words.add(digits[it - '0']) }
            }
            words.joinToString(" ")
        }
    }.replace(Regex("[._/-]+"), " ").replace(Regex("\\s+"), " ").trim()

    fun unitLast4(value: String): String {
        val matches = Regex("[0-9]+").findAll(value).map { it.value }.toList()
        if (matches.isEmpty()) return value.replace(Regex("[._/-]+"), " ").trim()
        val allDigits = matches.joinToString("")
        val last4 = if (allDigits.length > 4) allDigits.takeLast(4) else allDigits
        return unit(last4)
    }

    fun route(value: String): String {
        val pattern = Regex("""(?i)\bJAK[.\s](\d{2})(?!\w)""")
        val replaced = pattern.replace(value) { match ->
            val numStr = match.groupValues[1]
            val num = numStr.toInt()
            val spoken = when {
                num == 10 -> "sepuluh"
                num in 11..19 -> teen(num)
                num in 20..90 && num % 10 == 0 -> "${digits[num / 10]} puluh"
                else -> "${digits[numStr[0] - '0']} ${digits[numStr[1] - '0']}"
            }
            "JAK $spoken"
        }
        return replaced.replace('.', ' ').replace(Regex("\\s+"), " ").trim()
    }

    fun routeCode(value: String): String {
        val segment = value.split(Regex("""\s*[—–/:]\s*|\s+-\s+""")).firstOrNull()?.trim() ?: value
        return route(segment)
    }

    fun format(template: String, event: AlarmSpec, now: Long): String {
        val defaultTmpl = if (event.stage == "prep") "{rute} unit {unit}, {pramudi}, {detik} detik lagi." else "{rute} unit {unit}, {pramudi}, saatnya berangkat."
        val chosenTmpl = if (template.isBlank()) defaultTmpl else template

        val routeSpoken = if (event.isMultiRoute) routeCode(event.routeName) else ""
        val unitSpoken = unitLast4(event.unitNumber)
        val driverSpoken = event.driverName.trim()
        val remainingSec = ((event.departureAt - now + 999) / 1000).coerceAtLeast(1)
        val secondsSpoken = "$remainingSec"

        val timeFormatter = SimpleDateFormat("HH:mm", Locale("id", "ID"))
        val timeFormatted = try { timeFormatter.format(Date(event.departureAt)) } catch (_: Throwable) { "" }
        val ritaseSpoken = "ritase ${if (event.round in 1..9) digits[event.round] else event.round.toString()}"

        var result = chosenTmpl
        if (!event.isMultiRoute) {
            result = result.replace(Regex("""(?i)\brute\s*\{rute\}"""), "")
                .replace("{rute}", "", ignoreCase = true)
        } else {
            result = result.replace("{rute}", routeSpoken, ignoreCase = true)
        }

        result = result
            .replace("{unit}", unitSpoken, ignoreCase = true)
            .replace("{pramudi}", driverSpoken, ignoreCase = true)
            .replace("{detik}", secondsSpoken, ignoreCase = true)
            .replace("{jam}", timeFormatted, ignoreCase = true)
            .replace("{ritase}", ritaseSpoken, ignoreCase = true)
            .replace(Regex("""\{[^{}]*\}"""), "")

        result = result
            .replace(Regex("""\s*,\s*"""), ", ")
            .replace(Regex("""\s*\.\s*"""), ". ")
            .replace(Regex("""^([,\s.-]+)"""), "")
            .replace(Regex(""",\s*(,\s*)+"""), ", ")
            .replace(Regex("""\s+"""), " ")
            .trim()

        if (result.isNotEmpty()) {
            result = result[0].uppercaseChar() + result.substring(1)
        }
        return result
    }

    fun message(event: AlarmSpec, now: Long): String? {
        if (event.stage == "prep" && now >= event.departureAt) return null
        val rawTemplate = if (event.stage == "prep") event.prepTemplate else event.dueTemplate
        return format(rawTemplate, event, now)
    }

    fun next(active: List<ActiveAlarm>, spoken: Set<String>, now: Long): ActiveAlarm? = active
        .filter { it.event.sound && it.expiresAt > now && it.event.key !in spoken && message(it.event, now) != null }
        .sortedWith(compareBy<ActiveAlarm> { if (it.event.stage == "due") 0 else 1 }.thenBy { it.event.at }.thenBy { it.event.key })
        .firstOrNull()
}
