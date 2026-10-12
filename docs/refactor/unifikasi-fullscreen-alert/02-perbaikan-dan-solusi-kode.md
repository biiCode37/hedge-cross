# 02. Perbaikan & Solusi Kode — Unifikasi Single-Component Fullscreen Alert

Dokumen ini memuat penjelasan arsitektur solusi, detail kode yang diperbaiki, dan file-file yang dimodifikasi serta dihapus untuk merealisasikan unifikasi satu komponen dialog alert fullscreen pada HEDGE.

---

## 1. Arsitektur Solusi: Single Source of Truth Flutter

Dengan memanfaatkan izin `SYSTEM_ALERT_WINDOW` (*Tampil di Atas Aplikasi Lain*) yang sudah menjadi izin wajib di HEDGE (diperiksa oleh `PermissionGate`), serta flag `showWhenLocked` dan `turnScreenOn` pada Android, aplikasi HEDGE dapat langsung membawa dirinya sendiri ([`MainActivity`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt)) ke layar depan (*bring-to-front*) saat alarm berdering.

Hasilnya:
1. Komponen Flutter [`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) menjadi **satu-satunya komponen dialog alert** di seluruh skenario operasional.
2. Seluruh kode canvas native Android yang menduplikasi Flutter dihapus tuntas.

---

## 2. Rincian Berkas yang Dihapus & Dimodifikasi

### A. Berkas yang Dihapus Total (3 Berkas)
- [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt) — Dihapus (326+ baris kode Canvas Android kustom).
- [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt) — Dihapus (pengelola injeksi `WindowManager.addView`).
- [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt) — Dihapus (Activity native pembungkus `AlarmSurface`).

### B. [`android/app/src/main/AndroidManifest.xml`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/AndroidManifest.xml)
- Menghapus deklarasi `.AlarmActivity`.
- Menambahkan atribut lockscreen dan display wakeup pada `.MainActivity`:
  ```xml
  <activity
      android:name=".MainActivity"
      android:exported="true"
      android:launchMode="singleTop"
      android:taskAffinity=""
      android:theme="@style/LaunchTheme"
      android:showWhenLocked="true"
      android:turnScreenOn="true"
      ... >
  ```

### C. [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt)
- Menambahkan penanganan window flags pada `onCreate()` agar layar menyala dan tampil di atas keyguard:
  ```kotlin
  override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      if (Build.VERSION.SDK_INT >= 27) {
          setShowWhenLocked(true)
          setTurnScreenOn(true)
      } else {
          @Suppress("DEPRECATION")
          window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
      }
      window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
  }
  ```
- Menambahkan `onNewIntent()` agar intent alarm yang masuk langsung diterima oleh instance Flutter yang sedang aktif.

### D. [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt)
- Memperbarui `activityIntent()` agar selalu mengarah ke `MainActivity::class.java` dengan flags:
  `Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP`
- Menambahkan fungsi pembantu `launchApp(context: Context, key: String? = null)` untuk meluncurkan `MainActivity` saat alarm jatuh tempo.
- Pada `tick()`, jika ada alarm layar penuh yang aktif dan aplikasi tidak sedang di foreground:
  ```kotlin
  if (toShow.any { it.event.fullScreen } && MainActivity.foreground?.get() == null) {
      launchApp(c, toShow.firstOrNull { it.event.fullScreen }?.event?.key)
  }
  ```

### E. [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt)
- Menghapus ketergantungan pada `AlarmOverlay`.
- Saat siklus `refresh()`, jika alarm fullscreen aktif dan `MainActivity` belum di foreground, panggil `AlarmEngine.launchApp(this, ...)`.
- Tetap mempertahankan peran vitalnya sebagai Foreground Service untuk memutar suara pengumuman TTS dan menahan WakeLock.
