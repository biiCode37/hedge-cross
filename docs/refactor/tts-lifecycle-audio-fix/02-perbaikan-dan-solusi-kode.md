# Solusi Teknis & Perbaikan Kode: Pemulihan Siklus Hidup Audio TTS HEDGE

Dokumen ini menjelaskan implementasi perbaikan kode secara menyeluruh untuk mengatasi masalah hilangnya suara TTS saat dimatikan lalu diaktifkan kembali, kebocoran status siklus hidup service Android, dan pemulihan fokus audio.

---

## 1. Arsitektur Perbaikan

Perbaikan berfokus pada ketahanan siklus hidup (*lifecycle resiliency*), pemulihan otomatis (*self-healing / retry*), dan konsistensi status antara layer Flutter dan Kotlin native:

1. **State Machine Siklus Hidup Service:** Mencegah *early return* palsu saat service sedang dalam proses berhenti (`stopping`), serta membersihkan referensi lama seketika.
2. **Reset Tipe Foreground:** Memastikan status `foregroundTypes` direset ke `-1` saat `stopForeground()` dipanggil agar izin pemutaran audio di Android 14+ selalu valid.
3. **Mekanisme Retry Inisialisasi Engine TTS:** Mengisolasi inisialisasi TTS ke fungsi mandiri dengan jeda tunda 1.000 ms jika inisialisasi pertama gagal karena proses teardown IPC sebelumnya.
4. **Isolasi Audio Ducking:** Membedakan kehilangan fokus audio penuh (`AUDIOFOCUS_LOSS`) dengan reduksi transien (`AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK`) agar bunyi notifikasi lain tidak menghentikan TTS.
5. **Pembersihan Cache `attempted` & `spoken` saat Re-aktivasi:** Membuka kembali kunci ucapan untuk alarm aktif yang suaranya baru saja diaktifkan kembali oleh pengguna.
6. **Sinkronisasi Proaktif di UI Flutter:** Memastikan `_syncNativeAlarms()` dieksekusi sebelum dialog konfigurasi dibuka dan setiap menit berjalan, sehingga status native OFF tidak terkunci.

---

## 2. Rincian Perubahan Kode

### 2.1 [`AlarmDeliveryService.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt)
- **Menambahkan Flag `stopping`:**
  ```kotlin
  private var stopping = false
  ```
- **Memperbaiki `refreshIfRunning()`:**
  Jika service ditandai `stopping`, fungsi mengembalikan `false` sehingga `sync()` tidak membatalkan pembuatan service baru:
  ```kotlin
  fun refreshIfRunning(): Boolean {
      val service = running?.get() ?: return false
      if (service.stopping) return false
      service.handler.post { service.refresh() }
      return true
  }
  ```
- **Reset Saat Service Berhenti (`refresh()` & `onDestroy()`):**
  Menandai `stopping = true`, mengosongkan `running = null`, dan mereset `foregroundTypes = -1`:
  ```kotlin
  if (events.none { it.event.sound || (it.event.fullScreen && Settings.canDrawOverlays(this)) }) {
      stopping = true
      if (running?.get() === this) running = null
      overlay.close(); speech?.close(); speech = null
      foregroundTypes = -1
      stopForeground(STOP_FOREGROUND_REMOVE); stopSelf(); return
  }
  ```
- **Reset Saat Service Dimulai Kembali (`onCreate()` & `onStartCommand()`):**
  Mengembalikan `stopping = false` dan memperbarui `running = WeakReference(this)` agar siap menerima perintah baru.

---

### 2.2 [`AlarmSpeechPlayer.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt)
- **Penyempurnaan Listener Audio Focus:**
  Mengganti perbandingan negatif umum (`change < 0`) dengan seleksi eksplisit:
  ```kotlin
  private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
      handler.post {
          when (change) {
              AudioManager.AUDIOFOCUS_LOSS -> {
                  stopCurrent()
                  retryAfter = System.currentTimeMillis() + 1500
              }
              AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                  stopCurrent()
                  retryAfter = System.currentTimeMillis() + 1000
              }
              AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                  // Jangan hentikan ucapan saat ducking transien (misal nada ketik / notif chat)
              }
          }
      }
  }
  ```
- **Inisialisasi Ulang TTS Otomatis (`initEngine` & retry):**
  Jika `TextToSpeech` mengembalikan kode gagal pada percobaan pertama, sistem tidak lagi menyerah:
  ```kotlin
  private fun initialized(result: Int) {
      if (closed) return
      val tts = engine ?: return
      if (result != TextToSpeech.SUCCESS) {
          AlarmEngine.speechStatus(context, "Mesin TTS belum siap (mencoba ulang)", "")
          ready = false
          engine = null
          try { tts.shutdown() } catch (_: Throwable) {}
          handler.postDelayed({
              if (!closed && engine == null) {
                  initEngine()
              }
          }, 1000)
          return
      }
      ...
  ```
- **Penghapusan Kunci `attempted` Saat Gagal Berucap:**
  Pada fungsi `finished()`, jika pemutaran gagal (`failed == true`), kunci alarm dihapus dari `attempted` agar dapat dicoba ulang pada siklus berikutnya:
  ```kotlin
  private fun finished(id: String, failed: Boolean) {
      if (closed || current?.event?.key != id) return
      current = null; abandonFocus()
      if (failed) {
          attempted.remove(id)
          AlarmEngine.deliveryIssue(context, "Ucapan TTS gagal diputar. Gunakan Uji suara untuk memeriksa mesin TTS.")
      }
      update(latest)
  }
  ```

---

### 2.3 [`AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt)
- **Membuka Kunci `spoken` untuk Alarm Aktif yang Suaranya Diaktifkan Kembali:**
  Saat konfigurasi disimpan via `replace()`, sistem mendeteksi apakah ada alarm aktif yang sebelumnya tanpa suara lalu diubah menjadi bersuara (`sound == true`):
  ```kotlin
  val prevActiveUnvoiced = active(s).filter { !it.event.sound }.map { it.event.key }.toSet()
  val reenabledKeys = kept.filter { it.event.sound && it.event.key in prevActiveUnvoiced }.map { it.event.key }.toSet()
  val keepKeys = plan(s).map { it.key }.toSet() + kept.map { it.event.key }
  s.put("delivered", JSONArray(strings(s.optJSONArray("delivered")).filter { it in keepKeys }))
  val spokenFiltered = strings(s.optJSONArray("spoken")).filter { it in keepKeys && it !in reenabledKeys }
  s.put("spoken", JSONArray(spokenFiltered))
  ```

---

### 2.4 [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- **Sinkronisasi Native Proaktif Sebelum Buka Konfigurasi:**
  ```dart
  Future<void> _config(HedgeRoute route) async {
    await _syncNativeAlarms();
    if (!mounted) return;
    final currentRoute = ref
        .read(workspaceProvider)
        .workspace
        .routes
        .firstWhere((r) => r.id == route.id, orElse: () => route);
    final result = await showModalBottomSheet<HedgeRoute>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ConfigurationSheet(route: currentRoute),
    );
    if (result != null) await controller.updateRoute(result);
  }
  ```
- **Sinkronisasi Periodik di `clockProvider` Listener:**
  Setiap pergantian menit jadwal, aplikasi menjalankan `_syncNativeAlarms()` secara otomatis untuk mengakui status tindakan alarm native yang tertunda.

---

### 2.5 [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)
- **Pembaruan Teks Subtitle Suara Alarm:**
  Mengubah teks menjadi:
  `TTS Bahasa Indonesia mengikuti volume Media/Speaker Android.`
  Menghilangkan kerancuan pengguna antara volume Alarm sistem vs volume Media tempat TTS dialirkan.
