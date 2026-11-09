# Perbaikan dan Solusi Kode: Independensi Volume TTS Berbasis 3 Pilar Audio Harmonis

## 1. Arsitektur Solusi

Untuk membebaskan volume suara TTS dari volume musik perangkat dan menjamin suara peringatan selalu terdengar maksimal, diterapkan arsitektur **3 Pilar Audio Harmonis**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ANDROID AUDIO SYSTEM                            │
├──────────────────────────────────┬─────────────────────────────────────┤
│   STREAM_MUSIC (Media Slider)    │     STREAM_ALARM (Alarm Slider)     │
│   [ Spotify / Lagu Sedang: 40% ] │     [ HEDGE TTS Engine: 100% ]      │
└──────────────────────────────────┴─────────────────────────────────────┘
                 │                                      │
                 ▼                                      ▼
      [ Audio Focus Ducking ] ◄────────────── [ Sinyal Alarm Bunyi ]
   (Musik otomatis mengecil ke 10%)          (TTS menggelegar di 100%)
                 │                                      │
                 ▼                                      ▼
      [ Selesai Bicara TTS ]  ──────────────► [ Auto-Restore Volume ]
   (Musik kembali ke volume 40%)             (Kembali ke setelan awal)
```

### Pilar 1: Pemisahan Saluran ke Saluran Alarm Mandiri (`STREAM_ALARM` & `AudioAttributes.USAGE_ALARM`)
- Seluruh output suara TTS dan nada lonceng (*chime*) dialihkan ke saluran **`AudioManager.STREAM_ALARM`** dengan `AudioAttributes.USAGE_ALARM`.
- Saluran ini memiliki slider volume independen dari pemutar musik, memiliki prioritas tinggi, dan mampu menembus mode *Do Not Disturb* (DND).

### Pilar 2: Mekanisme Auto-Boost & Auto-Restore Volume Cerdas
- Tepat sebelum *chime* dan TTS bersuara, sistem mencatat volume saluran alarm saat ini (`previousAlarmVolume`).
- HEDGE menaikkan level volume `STREAM_ALARM` ke nilai maksimal hardware (`audio.getStreamMaxVolume(STREAM_ALARM)`).
- Begitu kalimat selesai diucapkan (`finished`), dibatalkan (`stopCurrent`), atau layanan dihentikan (`close`), HEDGE mengembalikan volume saluran alarm ke level semula secara presisi.

### Pilar 3: Peredaman Musik Otomatis (*Audio Ducking*)
- Sistem meminta fokus audio dengan `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`.
- Saat TTS berbicara, lagu yang sedang diputar di aplikasi lain (Spotify, YouTube, dll.) otomatis mengecil (*ducked*), sehingga ucapan TTS terdengar sangat jernih tanpa tabrakan audio.
- Begitu selesai, fokus dilepas (`abandonAudioFocus`) dan lagu kembali ke volume normal dengan mulus.

---

## 2. Rincian Modifikasi Kode

### A. Modul Kotlin Native: [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)
1. **Pengalihan AudioAttributes ke USAGE_ALARM:**
   ```kotlin
   private val attributes = AudioAttributes.Builder()
       .setUsage(AudioAttributes.USAGE_ALARM)
       .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
   ```
2. **Penerapan Fungsi Boost & Restore Volume:**
   ```kotlin
   private var previousAlarmVolume: Int? = null

   private fun boostVolume() {
       try {
           val currentVol = audio.getStreamVolume(AudioManager.STREAM_ALARM)
           val maxVol = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM)
           if (currentVol < maxVol) {
               previousAlarmVolume = currentVol
               audio.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)
           }
       } catch (_: Throwable) {}
   }

   private fun restoreVolume() {
       try {
           previousAlarmVolume?.let { prev ->
               audio.setStreamVolume(AudioManager.STREAM_ALARM, prev, 0)
               previousAlarmVolume = null
           }
       } catch (_: Throwable) {}
   }
   ```
3. **Pemberian Nada Lonceng dan Parameter TTS ke STREAM_ALARM:**
   ```kotlin
   toneGen = ToneGenerator(AudioManager.STREAM_ALARM, 100)
   ...
   val params = Bundle().apply {
       putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1f)
       putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_ALARM)
       putString(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_ALARM.toString())
   }
   ```

### B. Modul Kotlin Engine: [`AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt)
Membaca level volume `STREAM_ALARM` dan `STREAM_MUSIC` secara terpisah untuk dikirim ke UI Flutter:
```kotlin
val audioManager = c.getSystemService(AudioManager::class.java)
val alarmVol = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
val alarmVolMax = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
val musicVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
val musicVolMax = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
return mapOf(
    ...
    "alarmVolume" to alarmVol, "alarmVolumeMax" to alarmVolMax,
    "musicVolume" to musicVol, "musicVolumeMax" to musicVolMax,
    ...
)
```

### C. Service Layer Flutter: [`lib/application/notification_service.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/notification_service.dart)
Menambahkan field `musicVolume` dan `musicVolumeMax` ke dalam data model `AlarmDeviceStatus`.

### D. UI Panel Diagnostik: [`lib/ui/alarm_permissions.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_permissions.dart)
Menampilkan indikator volume saluran alarm dan media secara terpisah dan transparan:
- `Volume Alarm TTS: X/Y (Saluran Alarm Mandiri, Terpisah dari Musik).`
- `Volume Media Musik: A/B.`

### E. UI Konfigurasi Jadwal: [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)
Memperbarui keterangan sakelar suara TTS menjadi:
*"Saluran Alarm mandiri dengan auto-boost maksimal (bebas setel musik tanpa mempengaruhi suara TTS)."*
