# Temuan Masalah: Keterikatan Volume Suara TTS dengan Volume Musik / Perangkat

## 1. Konteks Masalah
Dalam operasional harian di terminal, pos pantau, dan pool pengendapan Mikrotrans, petugas dispatcher kerap memutar musik santai, radio streaming, atau video panduan operasional pada smartphone Android mereka sembari menunggu jeda waktu keberangkatan armada (headway). Volume musik biasanya disetel di tingkat sedang (30%–40%) agar suasana pos tetap nyaman dan tidak memekakkan telinga.

Namun, ketika alarm jadwal keberangkatan armada berbunyi (*due alarm*), suara panggilan Text-To-Speech (TTS) Bahasa Indonesia HEDGE (seperti *"Rute JAK 115, unit 1865, saatnya berangkat"*) terdengar lirih/pelan mengikuti tingkat volume musik yang sedang disetel. Hal ini menyebabkan pengumuman keberangkatan tidak terdengar oleh pramudi di lapangan, menimbulkan risiko keterlambatan ritase (*late departure*).

---

## 2. Analisis Akar Masalah (Root Cause)

Berdasarkan investigasi mendalam pada modul native Android HEDGE ([`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)) dan [`AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt), ditemukan tiga akar penyebab teknis:

### A. Pengalihan Output ke Saluran Media (`STREAM_MUSIC`)
Pada implementasi sebelumnya di `AlarmSpeechPlayer.kt`:
```kotlin
private val attributes = AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
```
Dan pada parameter ucapan TTS:
```kotlin
val params = Bundle().apply {
    putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1f)
    putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
    putString(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC.toString())
}
```
Serta pada pemutar nada lonceng peringatan (*chime*):
```kotlin
toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
```
Di sistem operasi Android, `STREAM_MUSIC` adalah saluran yang sama persis dengan yang dikendalikan oleh slider volume **Media** (saluran yang digunakan oleh Spotify, YouTube, Google Chrome, dan pemutar musik lokal).

### B. Karakteristik Multiplier `KEY_PARAM_VOLUME`
Nilai parameter `TextToSpeech.Engine.KEY_PARAM_VOLUME = 1.0f` bukanlah penentu volume absolut hardware, melainkan hanya faktor pengali persentase (skala `0.0f` sampai `1.0f`) terhadap volume master dari *stream* yang digunakan saat itu:
$$\text{Volume Output} = \text{Volume Master Stream} \times \text{KEY\_PARAM\_VOLUME}$$
Ketika volume Media Android diatur oleh dispatcher pada level 35%, maka:
$$35\% \times 1.0 = 35\%$$
Akibatnya suara ucapan TTS teredam dan tidak dapat mencapai tingkat desibel maksimal hardware perangkat.

### C. Tidak Ada Pemulihan & Penyesuaian Saluran Audio
Sebelumnya sistem HEDGE tidak mengontrol atau memisahkan slider audio hardware secara dinamis, sehingga alarm bergantung 100% pada posisi slider Media ponsel yang sedang aktif saat itu.
