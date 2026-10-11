# 02. Perbaikan & Solusi Kode — Cyberpunk Telemetry Cockpit Fullscreen Alert

Dokumen ini memuat arsitektur solusi, cetak biru desain (*design blueprint*), dan pemetaan perubahan kode untuk merevolusi dialog alert layar penuh (*fullscreen alert*) menjadi **Cyberpunk Telemetry Cockpit / Flight HUD** yang futuristik, padat informasi, bebas blank space, dan 100% konsisten dengan ekosistem HEDGE.

---

## 1. Arsitektur Solusi: Cyberpunk Telemetry Cockpit / Flight HUD

Berdasarkan eksplorasi desain Opsi 1 (Cyberpunk Telemetry Cockpit), layar alert didesain ulang menyerupai panel instrumen penerbangan/kokpit pesawat antariksa:

1. **Monolith Fleet Unit Identifier (72sp):**
   - Nomor armada ditampilkan masif dan berwibawa di bagian atas panel telemetri dengan ukuran 72sp, font bold monospaced, aksen glow cyberpunk, serta dibungkus `FittedBox` agar tidak pernah terpotong pada berbagai resolusi layar.

2. **Giant Chrono-Dial Radar (220dp):**
   - Lingkaran radar tengah diperbesar hingga diameter 220dp, dilengkapi cincin konsentris, 12 tick radar radial pada sudut jam, serta busur sirkular dinamis (*circular timeout arc*) yang menyusut seiring berjalannya batas waktu alert.
   - Di tengah radar, countdown digital berukuran 40sp (`+00:04` / `00:04`) dengan label dinamis (*WAKTU BERANGKAT* / *BERSIAP BERANGKAT*).

3. **Live Mission Telemetry Grid (3 Cards):**
   - Bagian bawah panel dilengkapi 3 kartu instrumen horizontal:
     - **JADWAL:** Waktu rencana keberangkatan (misal `07:15 WIB`) dengan ikon jam cyan/amber.
     - **RUTE:** Nama rute aktif (misal `JAK.118`).
     - **PUTARAN:** Nomor ritase aktif (misal `RITASE 2`).
   - Kartu dirancang modular dengan border neon glow dan `FittedBox` responsif.

4. **Action Console 3-Tingkat (Thumb-First Ergonomics):**
   - **Level 1 (Utama):** Tombol *"Sudah Berangkat"* (Tinggi 48px, gradien Amber `#FF9800` ke `#FF6D00`, teks hitam tebal monospaced, bayangan neon glow 14px).
   - **Level 2 (Sekunder):** Tombol *"Tutup Alert"* dengan border Obsidian/Cyan, menutup pop-up tanpa mencatat keberangkatan dan tanpa mematikan rute.
   - **Level 3 (Tersier):** Tombol *"Matikan alarm rute"* dengan gaya minimalis berpagar halus.

5. **Penyelarasan Total Native Android ([`AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt)):**
   - `CyberDialGaugeView` diimplementasikan menggunakan Android 2D Canvas kustom berdiameter 200dp, memuat 12 garis tick radial, cincin konsentris, busur circular timeout `drawArc()`, dan 3 kotak telemetri native (Jadwal, Rute, Putaran).

6. **Pencegahan Konflik Dual Alert ([`AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt)):**
   - Memastikan `AlarmActivity` native hanya diluncurkan saat perangkat terkunci atau aplikasi di background, sehingga saat dispatcher sedang aktif di dalam app, hanya `ForegroundAlarmOverlay` Flutter yang tampil mulus tanpa interupsi.

---

## 2. Pemetaan Berkas Terdampak

- [`lib/ui/alarm_overlay.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) — Implementasi Cockpit HUD, `CockpitDialPainter`, `_TelemetryCard`, dan action console.
- [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt) — Rekonstruksi tampilan native Android dengan gauge 200dp, timeout arc, dan 3 kartu telemetri horizontal.
- [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt) — Resolusi konflik peluncuran dual alert di foreground.
- [`pubspec.yaml`](file:///d:/MINE/HEDGE-FLUTTER/pubspec.yaml) — Pembaruan versi aplikasi ke `2.0.9+12`.
- [`test/alarm_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/alarm_test.dart) — Verifikasi pengujian widget overlay pada layar kecil 320x640 dan font scale 1.6x.
