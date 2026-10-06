package id.mikrotrans.hedge.hedge_flutter

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

/** On-device speech at full player gain, following the user's Alarm stream volume. */
class AlarmSpeechPlayer(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private val audio = context.getSystemService(AudioManager::class.java)
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var engine: TextToSpeech? = null
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
    private val focusRequest = if (Build.VERSION.SDK_INT >= 26) AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        .setAudioAttributes(attributes).setWillPauseWhenDucked(true).setOnAudioFocusChangeListener(focusListener).build() else null
    init {
        AlarmEngine.speechStatus(context, "Memuat suara Bahasa Indonesia", "")
        engine = TextToSpeech(context.applicationContext) { result -> handler.post { initialized(result) } }
    }
    private fun initialized(result: Int) {
        if (closed) return
        val tts = engine ?: return
        if (result != TextToSpeech.SUCCESS) { AlarmEngine.speechStatus(context, "Mesin TTS belum tersedia", ""); return }
        val language = tts.setLanguage(Locale("id", "ID"))
        if (language < TextToSpeech.LANG_AVAILABLE) { AlarmEngine.speechStatus(context, "Pasang suara Bahasa Indonesia di pengaturan TTS Android", ""); return }
        val voice = tts.voices.orEmpty().filter { it.locale.language == "id" && !it.isNetworkConnectionRequired }
            .sortedWith(compareByDescending<android.speech.tts.Voice> { it.quality }.thenBy { it.name }).firstOrNull()
        if (voice == null || tts.setVoice(voice) != TextToSpeech.SUCCESS) {
            AlarmEngine.speechStatus(context, "Suara Bahasa Indonesia offline belum tersedia", ""); return
        }
        if (tts.setAudioAttributes(attributes) != TextToSpeech.SUCCESS) {
            AlarmEngine.speechStatus(context, "Mesin TTS gagal memakai audio Alarm", voice.name); return
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
        AlarmEngine.speechStatus(context, "Suara offline siap", voice.name)
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
            else audio.requestAudioFocus(focusListener, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            retryAfter = now + 1000
            AlarmEngine.deliveryIssue(context, "Audio Alarm belum mendapat prioritas; periksa panggilan atau audio aplikasi lain.")
            return
        }
        val message = AlarmSpeechText.message(candidate.event, System.currentTimeMillis())
        if (message == null) { abandonFocus(); return }
        current = candidate; attempted.add(candidate.event.key)
        val params = Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1f) }
        if (engine?.speak(message, TextToSpeech.QUEUE_FLUSH, params, candidate.event.key) != TextToSpeech.SUCCESS) finished(candidate.event.key, true)
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
        stopCurrent(); engine?.shutdown(); engine = null; handler.removeCallbacksAndMessages(null)
    }
}
