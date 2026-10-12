# Spesifikasi Desain: Unifikasi Fullscreen Alarm Overlay Menjadi Komponen Tunggal Flutter

**Tanggal:** 2026-10-12  
**Status:** Disetujui (Approved)  
**Tujuan:** Menghilangkan redundansi komponen alert layar penuh (*fullscreen alert*) dengan menetapkan [`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) (Flutter) sebagai satu-satunya komponen yang digunakan, serta menghapus total komponen native Android (`AlarmSurface.kt`, `AlarmOverlay.kt`, dan `AlarmActivity.kt`).

---

## 1. Latar Belakang & Masalah

Sebelum perubahan ini, HEDGE memiliki dua komponen alert layar penuh yang berbeda untuk menangani dua kondisi berbeda:
1. **Saat Aplikasi Aktif (Foreground):**
   - Menggunakan komponen Flutter [`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) yang telah didesain dengan gaya Cyberpunk Cockpit HUD (radar chrono-dial 220dp, monolit unit 72sp, telemetry cards, neon glow, dual theme light/dark).
2. **Saat User Membuka Aplikasi Lain / Layar Terkunci (Background):**
   - Menggunakan komponen native Android [`AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt) yang diinjeksi via [`AlarmOverlay.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt) (`WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`) atau [`AlarmActivity.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt).

Hal ini menimbulkan redundansi besar:
- Duplikasi ratusan baris kode kalkulasi canvas & layout di native Android Kotlin (`AlarmSurface.kt` > 400 baris).
- Perbedaan perilaku mikro-interaksi, handling font scale, dan animasi antara Flutter dan Android Native Canvas.
- Kebingungan visual dispatcher saat berpindah konteks penggunaan aplikasi.

---

## 2. Arsitektur Solusi & Perubahan

### A. Eliminasi Komponen Native Redundan
Hapus seluruh berkas visual native Android yang menduplikasi Flutter:
1. `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt` — DIHAPUS.
2. `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt` — DIHAPUS.
3. `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt` — DIHAPUS.

### B. Konfigurasi `MainActivity` untuk Lock Screen & Bring-to-Front
Agar `MainActivity` (lapisan Flutter) dapat menyala dan tampil langsung di atas lock screen maupun aplikasi lain:
1. **`AndroidManifest.xml`:**
   - Hapus deklarasi `<activity android:name=".AlarmActivity" ... />`.
   - Tambahkan atribut pada `<activity android:name=".MainActivity" ...>`:
     - `android:showWhenLocked="true"`
     - `android:turnScreenOn="true"`
2. **`MainActivity.kt`:**
   - Pada metode `onCreate()`:
     ```kotlin
     if (Build.VERSION.SDK_INT >= 27) {
         setShowWhenLocked(true)
         setTurnScreenOn(true)
     } else {
         @Suppress("DEPRECATION")
         window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
     }
     window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
     ```
   - Tambahkan metode `onNewIntent(intent: Intent)` untuk meneruskan intent pembukaan alarm ke Flutter secara mulus.

### C. Penyesuaian `AlarmEngine.kt` & `AlarmDeliveryService.kt`
1. **`AlarmEngine.kt`:**
   - Modifikasi `activityIntent()` agar selalu mengarah ke `MainActivity::class.java`:
     ```kotlin
     private fun activityIntent(c: Context, key: String, fullScreen: Boolean = true): PendingIntent {
         val i = Intent(c, MainActivity::class.java).setAction("hedge.alarm.OPEN.$key")
             .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
         val options = if (Build.VERSION.SDK_INT >= 35) ActivityOptions.makeBasic().apply {
             setPendingIntentCreatorBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
         }.toBundle() else null
         return PendingIntent.getActivity(c, 0, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE, options)
     }
     ```
   - Tambahkan fungsi pembantu `launchApp(context: Context, key: String? = null)` yang memanfaatkan izin `SYSTEM_ALERT_WINDOW` untuk membawa `MainActivity` ke depan saat alarm aktif jika aplikasi sedang di background.
2. **`AlarmDeliveryService.kt`:**
   - Hapus properti `overlay: AlarmOverlay` dan lifecycle pemanggilannya.
   - Pada `refresh()`, jika alarm memiliki flag `fullScreen` dan `MainActivity.foreground?.get() == null`, panggil `AlarmEngine.launchApp(this, key)`.
   - Pertahankan Foreground Service untuk pemutaran audio/TTS (`AlarmSpeechPlayer`) dan penahanan `WakeLock`.

### D. Single Source of Truth: `ForegroundAlarmOverlay` (Flutter)
- [`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) menjadi satu-satunya komponen visual alert.
- Menjamin tampilan 100% konsisten di semua situasi: countdown radar 220dp, info jadwal/rute/ritase, tombol *"Sudah Berangkat"*, *"Tutup Alert"*, dan *"Matikan alarm rute"*.

---

## 3. Rencana Pengujian & Kriteria Keberhasilan

1. **Flutter Widget Test:** Seluruh test suite di `test/alarm_test.dart` tetap lulus (10/10).
2. **Kompilasi Kotlin/Android:** Proyek Android berhasil dikompilasi tanpa dependensi pada `AlarmSurface`, `AlarmOverlay`, atau `AlarmActivity`.
3. **Audit Redundansi:** Tidak ada lagi komponen UI alert sekunder di native Android.
4. **Verifikasi Fungsional:**
   - Alarm saat HEDGE aktif: `ForegroundAlarmOverlay` tampil mulus.
   - Alarm saat user di aplikasi lain: HEDGE (`MainActivity`) langsung tampil ke depan dan merender `ForegroundAlarmOverlay`.
   - Tindakan *"Sudah Berangkat"* atau *"Tutup Alert"* menutup overlay dan memperbarui status secara atomik.
