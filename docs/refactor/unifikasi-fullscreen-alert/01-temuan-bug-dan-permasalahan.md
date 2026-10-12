# 01. Temuan Bug & Permasalahan — Redundansi Komponen Dialog Alert Fullscreen Keberangkatan

Dokumen ini memuat analisis mendalam mengenai akar masalah (*root cause*), aliran data (*data flow*), dan kondisi pemicu dari adanya dua komponen dialog alert layar penuh (*fullscreen alert*) yang berbeda pada HEDGE (Headway Generator).

---

## 1. Ringkasan Eksekutif Temuan

Dalam arsitektur sebelumnya, HEDGE memiliki dua komponen alert layar penuh yang berbeda yang tampil saat peringatan keberangkatan armada (tahap persiapan *prep* beberapa detik sebelumnya dan tahap jatuh tempo *due* saatnya berangkat):

1. **Komponen 1 (Saat Aplikasi Aktif di Foreground):**
   - Komponen Flutter: [`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart).
   - Tampil di atas widget tree aplikasi Flutter (`Stack` di `lib/ui/app.dart`) dengan desain Cyberpunk Cockpit HUD (radar 220dp, font monospaced 72sp, status capsule, 3 kartu telemetri, dan 3 tingkat tombol aksi).

2. **Komponen 2 (Saat User Sedang Membuka Aplikasi Lain atau Layar Mati / Background):**
   - Komponen Native Android: [`AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt) yang di-host dalam [`AlarmActivity.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt) atau diinjeksi via [`AlarmOverlay.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt) menggunakan `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`.
   - Menggunakan kalkulasi manual Android 2D Canvas (`android.graphics.Canvas`, `Paint`, `drawArc`, `drawLines`) untuk meniru tampilan Flutter secara terpisah.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)

### A. Duplikasi Kode dan Fragmentasi Logika UI
- Menjaga dua basis kode UI untuk satu fungsi yang identik (Dart/Flutter vs. Kotlin/Canvas) menimbulkan overhead pemeliharaan tinggi (>400 baris kode Kotlin kustom).
- Setiap kali ada penyesuaian desain, token warna, proporsi, atau penambahan tombol di Flutter, pengembang harus mengulang pekerjaan yang sama pada Canvas native Android secara manual.

### B. Inkonsistensi Visual dan Ergonomi
- Walaupun `AlarmSurface.kt` mencoba meniru Cockpit HUD Flutter, kalkulasi font metric, anti-aliasing, radius kurvatur, dan penanganan densitas layar pada Canvas Android native tidak pernah 100% identik dengan Flutter Engine.
- Dispatcher yang menggunakan aplikasi di lapangan merasakan pengalaman visual yang terfragmentasi: saat sedang membuka HEDGE melihat antarmuka yang sangat halus, namun ketika sedang membuka WhatsApp atau layar terkunci melihat antarmuka native yang sedikit berbeda feel-nya.

### C. Aliran Data (Data Flow) yang Terbelah
- Pada komponen Flutter, aksi *"Sudah Berangkat"* langsung berinteraksi dengan `workspaceProvider.notifier.record()` dan state reaktif Riverpod.
- Pada komponen native Android, aksi *"Sudah Berangkat"* harus menulis aksi intent ke SharedPreferences SQLite buffer via JSON string (`AlarmEngine.complete()`), lalu menunggu siklus sync berikutnya (`_syncNativeAlarms()`) saat aplikasi Flutter aktif.
- Hal ini menimbulkan potensi race condition atau latensi sinkronisasi status keberangkatan armada.
