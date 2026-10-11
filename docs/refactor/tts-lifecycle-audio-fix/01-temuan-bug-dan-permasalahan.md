# Laporan Investigasi: Temuan Bug & Permasalahan Suara TTS HEDGE

Dokumen ini mencatat investigasi teknis mendalam terhadap permasalahan hilangnya suara Text-to-Speech (TTS) pada aplikasi HEDGE setelah fitur suara/alarm dimatikan lalu diaktifkan kembali, serta kondisi-kondisi lain yang menyebabkan suara TTS mati di lingkungan operasional dispatcher Android.

---

## 1. Akar Masalah Utama (Root Cause): TTS Tidak Muncul Setelah Dimatikan Lalu Diaktifkan Kembali

Berdasarkan penelusuran alur data (*data flow tracing*) dan siklus hidup service di Android native, ditemukan 4 titik kegagalan utama yang saling terkait:

### 1.1 Race Condition Siklus Hidup `stopSelf()` vs `refreshIfRunning()`
- **Lokasi File:** [`AlarmDeliveryService.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt)
- **Mekanisme Kegagalan:**
  1. Ketika pengguna mematikan suara alarm (atau menghentikan uji suara), `AlarmDeliveryService.refresh()` mendeteksi tidak ada lagi alert suara aktif, lalu memanggil `stopForeground(STOP_FOREGROUND_REMOVE)` dan `stopSelf()`.
  2. Di sistem operasi Android, pemanggilan `stopSelf()` **tidak langsung menghancurkan objek Service secara sinkron**, melainkan menunggu antrean Looper thread utama.
  3. Objek `AlarmDeliveryService` lama masih berada di memori dan referensinya tersimpan di `running: WeakReference<AlarmDeliveryService>`.
  4. Ketika pengguna mengaktifkan kembali suara atau alarm sesaat kemudian, fungsi `AlarmDeliveryService.sync(context)` dipanggil.
  5. Baris evaluasi awal:
     ```kotlin
     if (!preview && refreshIfRunning()) return
     ```
  6. Fungsi `refreshIfRunning()` memeriksa `running?.get()`. Karena objek service lama belum di-garbage-collect dan `onDestroy()` belum tuntas, fungsi mengembalikan `true`.
  7. Akibatnya, `sync()` langsung keluar (*early return*) tanpa memanggil `startForegroundService(intent)`.
  8. Beberapa milidetik kemudian, siklus Looper mengeksekusi `onDestroy()` pada service lama: semua callback dihapus (`removeCallbacksAndMessages(null)`), dan engine TTS ditutup (`speech?.close()`).
  9. **Dampak:** Tidak ada service baru yang berjalan. TTS dan pemutar suara mati total tanpa memicu alarm baru.

---

### 1.2 Status `foregroundTypes` Tidak Direset Pasca `stopForeground()`
- **Lokasi File:** [`AlarmDeliveryService.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt)
- **Mekanisme Kegagalan:**
  1. Service menyimpan cache tipe foreground di variabel `foregroundTypes` (misal: `FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`).
  2. Saat pemutaran selesai atau dihentikan, `stopForeground(STOP_FOREGROUND_REMOVE)` dipanggil, mencabut status foreground dari sistem Android.
  3. Namun, variabel `foregroundTypes` tidak direset ke `-1`.
  4. Ketika alarm berikutnya atau aktivasi ulang meminta audio foreground:
     ```kotlin
     if (foregroundTypes == types) return true
     ```
  5. Kondisi di atas bernilai `true`, sehingga sistem melewati pemanggilan `startForeground(...)`.
  6. **Dampak:** Pada Android 14+ (SDK 34), layanan background yang tidak memiliki status foreground aktif dilarang memutar audio media/TTS di background, sehingga suara tidak pernah terdengar.

---

### 1.3 Kunci Cache `spoken` Menolak Pengulangan Alarm Aktif
- **Lokasi File:** [`AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt) & [`AlarmSpeechText.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt)
- **Mekanisme Kegagalan:**
  1. Begitu TTS mulai berucap (`UtteranceProgressListener.onStart`), ID departure (misal `20261010_JAK115_01:due`) langsung disimpan ke daftar `spoken` di SharedPreferences.
  2. Jika pengguna mematikan suara saat alarm sedang berdering, suara TTS berhenti.
  3. Ketika pengguna menyalakan kembali suara alarm di layar konfigurasi untuk jadwal yang sama, data dikirim ulang via `replace`.
  4. Fungsi `AlarmSpeechText.next` menyaring antrean dengan syarat:
     ```kotlin
     it.event.sound && it.expiresAt > now && it.event.key !in spoken
     ```
  5. Karena ID tersebut masih tersimpan di `spoken`, alarm aktif tersebut diabaikan.
  6. **Dampak:** Pengguna merasa suara tidak berfungsi padahal alarm masih tampil di layar.

---

### 1.4 Kegagalan Rekoneksi Engine TTS Pasca `shutdown()`
- **Lokasi File:** [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)
- **Mekanisme Kegagalan:**
  1. Saat suara ditutup, `engine?.shutdown()` melepaskan koneksi IPC dengan layanan Text-to-Speech sistem Android (Google Speech Services / Samsung TTS).
  2. Jika instansiasi baru `TextToSpeech(context.applicationContext)` dilakukan sebelum proses unbind IPC selesai, inisialisasi menghasilkan `TextToSpeech.ERROR` (-1).
  3. Kode lama hanya mencatat status "Mesin TTS belum tersedia", menyetel `ready = true`, dan **tidak pernah mencoba menghubungkan ulang (no retry)**.
  4. **Dampak:** TTS macet dalam kondisi gagal selamanya sampai aplikasi ditutup paksa (*Force Stop*).

---

## 2. Bagian / Kondisi Lain yang Menyebabkan Suara TTS Mati

Selain akar masalah di atas, investigasi menemukan 4 celah lain di lingkungan produksi:

### 2.1 Kebocoran Set `attempted` saat Pemutaran Gagal
- **Lokasi File:** [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)
- **Pemicu:** ID alarm ditambahkan ke set `attempted` sebelum ucapan selesai. Jika pemutaran gagal (`finished(id, failed = true)`), ID tersebut tidak dihapus dari `attempted`.
- **Dampak:** Sistem menganggap alarm tersebut sudah pernah dicoba, sehingga tidak ada *retry* sama sekali.

---

### 2.2 Kehilangan Fokus Audio Transien (*Audio Ducking*) Mematikan TTS Permanen
- **Lokasi File:** [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)
- **Pemicu:** Listener fokus audio mendeteksi `if (change < 0) stopCurrent()`. Nilai negatif mencakup `AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK` (-3).
- **Dampak:** Bunyi notifikasi WhatsApp singkat atau nada ketik keyboard HP langsung menghentikan ucapan TTS HEDGE secara permanen di tengah kalimat.

---

### 2.3 Rute Tertahan di Status `disabled` Setelah Menekan Tombol "OFF"
- **Lokasi File:** [`AlarmTimeline.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt) & [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- **Pemicu:**
  1. Tombol "OFF" pada overlay menambahkan rute ke set `disabled` native dan merekam aksi `disableAlarm`.
  2. Flutter hanya menyinkronkan aksi native saat `AppLifecycleState.resumed`. Jika pengguna tetap berada di dalam aplikasi, aksi tersebut belum di-`acceptActions`.
  3. Ketika pengguna masuk ke pengaturan rute dan mengaktifkan kembali "Alarm rute", kondisi rekonsiliasi native gagal mengeluarkan rute dari set `disabled` karena aksi masih berstatus *pending*.
- **Dampak:** Rute terkunci dalam status `disabled` native. Seluruh jadwal rute tersebut tidak membunyikan alarm maupun TTS.

---

### 2.4 Inkonsistensi Saluran Audio: Volume Media vs Label Alarm
- **Lokasi File:** [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt) & [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)
- **Pemicu:** Audio TTS dialirkan ke `STREAM_MUSIC` (agar kompatibel dengan headset Bluetooth dispatcher), namun label subtitle konfigurasi tertulis *"TTS Bahasa Indonesia mengikuti volume Alarm Android"*.
- **Dampak:** Pengguna yang mengecilkan volume media HP ke 0 (karena mengira hanya volume alarm yang berpengaruh) mendapati TTS tidak bersuara sama sekali.
