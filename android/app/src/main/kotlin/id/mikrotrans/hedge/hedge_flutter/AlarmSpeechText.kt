package id.mikrotrans.hedge.hedge_flutter

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
    fun message(event: AlarmSpec, now: Long): String? {
        val route = route(event.routeName)
        val number = unit(event.unitNumber)
        if (event.stage == "prep") {
            if (now >= event.departureAt) return null
            val seconds = (event.departureAt - now + 999) / 1000
            return "Segera berangkat, Rute $route, unit $number, berangkat dalam $seconds detik."
        }
        return "Rute $route, unit $number, saatnya berangkat."
    }
    fun next(active: List<ActiveAlarm>, spoken: Set<String>, now: Long): ActiveAlarm? = active
        .filter { it.event.sound && it.expiresAt > now && it.event.key !in spoken && message(it.event, now) != null }
        .sortedWith(compareBy<ActiveAlarm> { if (it.event.stage == "due") 0 else 1 }.thenBy { it.event.at }.thenBy { it.event.key })
        .firstOrNull()
}
