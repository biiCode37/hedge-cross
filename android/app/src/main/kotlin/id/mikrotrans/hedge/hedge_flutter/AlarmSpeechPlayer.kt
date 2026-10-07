package id.mikrotrans.hedge.hedge_flutter

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

/** On-device speech and prompt chime routed to active media/Bluetooth output, avoiding dual-speaker echo. */
class AlarmSpeechPlayer(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private val audio = context.getSystemService(AudioManager::class.java)
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var engine: TextToSpeech? = null
    private var toneGen: ToneGenerator? = null
    private var ready = false
    private var closed = false
    private var current: ActiveAlarm? = null
    private var latest = emptyList<ActiveAlarm>()
    private val attempted = mutableSetOf<String>()
    private var retryAfter = 0L
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        handler.post {
            if (change < 0) { stopCurrent(); retryAfter = System.currentTimeMillis() + 1000 }
        }
    }
    private val focusRequest = if (Build.VERSION.SDK_INT >= 26) AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(attributes).setWillPauseWhenDucked(false).setOnAudioFocusChangeListener(focusListener).build() else null

    init {
        AlarmEngine.speechStatus(context, "Memuat suara Bahasa Indonesia", "")
        engine = TextToSpeech(context.applicationContext) { result -> handler.post { initialized(result) } }
    }

    private fun playChime() {
        try {
            if (toneGen == null) {
                toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            }
            toneGen?.startTone(ToneGenerator.TONE_PROP_BEEP, 200)
        } catch (_: Throwable) {
            // ToneGenerator unavailable; continue without blocking speech
        }
    }

    private fun initialized(result: Int) {
        if (closed) return
        val tts = engine ?: return
        if (result != TextToSpeech.SUCCESS) {
            AlarmEngine.speechStatus(context, "Mesin TTS belum tersedia", "")
            ready = true
            update(latest)
            return
        }

        var langResult = tts.setLanguage(Locale("id", "ID"))
        if (langResult < TextToSpeech.LANG_AVAILABLE) {
            langResult = tts.setLanguage(Locale("in", "ID"))
        }
        if (langResult < TextToSpeech.LANG_AVAILABLE) {
            langResult = tts.setLanguage(Locale("id"))
        }
        if (langResult < TextToSpeech.LANG_AVAILABLE) {
            langResult = tts.setLanguage(Locale.forLanguageTag("id-ID"))
        }

        var voiceName = ""
        var isOffline = false
        try {
            val allVoices = tts.voices.orEmpty()
            if (allVoices.isNotEmpty()) {
                val idVoices = allVoices.filter {
                    val lang = it.locale.language.lowercase()
                    lang == "id" || lang == "in"
                }
                val offlineVoice = idVoices.filter { !it.isNetworkConnectionRequired }
                    .sortedWith(compareByDescending<android.speech.tts.Voice> { it.quality }.thenBy { it.name })
                    .firstOrNull()
                val chosenVoice = offlineVoice ?: idVoices.sortedWith(compareByDescending<android.speech.tts.Voice> { it.quality }.thenBy { it.name }).firstOrNull()
                if (chosenVoice != null && tts.setVoice(chosenVoice) == TextToSpeech.SUCCESS) {
                    voiceName = chosenVoice.name
                    isOffline = !chosenVoice.isNetworkConnectionRequired
                }
            }
        } catch (_: Throwable) {
            // Engine default voice will be used
        }

        try {
            tts.setAudioAttributes(attributes)
        } catch (_: Throwable) {
            // Fallback to STREAM_ALARM bundle params
        }

        tts.setSpeechRate(1f)
        tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String) { handler.post {
                if (!closed && current?.event?.key == id && !id.startsWith("preview:")) AlarmEngine.markSpoken(context, id)
            } }
            override fun onDone(id: String) { handler.post { finished(id, false) } }
            @Deprecated("Legacy engine callback")
            override fun onError(id: String) { handler.post { finished(id, true) } }
            override fun onError(id: String, code: Int) { handler.post { finished(id, true) } }
        })

        ready = true
        val statusText = when {
            langResult < TextToSpeech.LANG_AVAILABLE -> "Bahasa Indonesia tidak didukung mesin TTS (memakai nada peringatan)"
            isOffline -> "Suara offline siap"
            voiceName.isNotEmpty() -> "Suara siap ($voiceName)"
            else -> "Suara sistem siap"
        }
        AlarmEngine.speechStatus(context, statusText, voiceName)
        update(latest)
    }

    fun update(events: List<ActiveAlarm>) {
        latest = events
        if (closed || !ready) return
        val now = System.currentTimeMillis()
        val playing = current
        if (playing != null) {
            val stillActive = events.any { it.event.key == playing.event.key && it.event.sound && it.expiresAt > now }
            val dueWaiting = playing.event.stage == "prep" && events.any { it.event.stage == "due" && it.event.sound && it.event.key !in attempted }
            if (!stillActive || dueWaiting || AlarmSpeechText.message(playing.event, now) == null) stopCurrent() else return
        }
        if (now < retryAfter) return
        val candidate = AlarmSpeechText.next(events, attempted + AlarmEngine.spoken(context), now) ?: return
        val granted = if (Build.VERSION.SDK_INT >= 26) audio.requestAudioFocus(focusRequest!!)
            else audio.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            AlarmEngine.deliveryIssue(context, "Audio belum mendapat prioritas; volume mungkin terpengaruh audio lain.")
        }
        val message = AlarmSpeechText.message(candidate.event, System.currentTimeMillis())
        if (message == null) { abandonFocus(); return }
        current = candidate; attempted.add(candidate.event.key)

        // Immediate audible prompt chime so dispatcher always hears alert
        playChime()

        val params = Bundle().apply {
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1f)
            putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
            putString(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC.toString())
        }
        // Small delay to let prompt chime sound clearly before speech
        handler.postDelayed({
            if (!closed && current?.event?.key == candidate.event.key) {
                if (engine?.speak(message, TextToSpeech.QUEUE_FLUSH, params, candidate.event.key) != TextToSpeech.SUCCESS) {
                    finished(candidate.event.key, true)
                }
            }
        }, 150)
    }

    private fun finished(id: String, failed: Boolean) {
        if (closed || current?.event?.key != id) return
        current = null; abandonFocus()
        if (failed) AlarmEngine.deliveryIssue(context, "Ucapan TTS gagal diputar. Gunakan Uji suara untuk memeriksa mesin TTS.")
        update(latest)
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= 26) audio.abandonAudioFocusRequest(focusRequest!!) else audio.abandonAudioFocus(focusListener)
    }

    private fun stopCurrent() { current = null; engine?.stop(); abandonFocus() }

    fun close() {
        closed = true; ready = false; latest = emptyList()
        stopCurrent(); engine?.shutdown(); engine = null
        try { toneGen?.release() } catch (_: Throwable) {}
        toneGen = null
        handler.removeCallbacksAndMessages(null)
    }
}
