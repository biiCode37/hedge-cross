# Design Specification — Cyberpunk Telemetry Cockpit Fullscreen Alert

- **Status:** Approved
- **Tanggal:** 2026-10-10
- **Penulis:** AntiGravity Pair Programming Agent
- **Target Branch:** `devmode`
- **Tujuan:** Mengeliminasi seluruh sisa ruang kosong (*blank space*) pada alert fullscreen keberangkatan armada dengan mentransformasi layout menjadi Cyberpunk Telemetry Cockpit / Flight HUD yang mengisi vertikal layar secara proporsional, padat informasi, futuristik, dan terpadu antara lapisan Flutter dan Native Android.

---

## 1. Latar Belakang & Masalah

Pada build sebelumnya (`v2.0.8`):
1. Kartu telemetri dan dial countdown hanya berukuran ~350dp, sementara tombol tindakan menempel di tepi bawah layar perangkat.
2. Pada layar smartphone Android modern (rasio 20:9 atau 21:9 dengan tinggi ~850–900dp), menyisakan ruang kosong hitam masif (~250–300dp) di antara kartu dan tombol.
3. Keterbacaan dari jarak jauh di shelter terminal belum optimal karena proporsi elemen inti (nomor unit dan dial waktu) masih relatif kecil dibandingkan ruang layar yang tersedia.

---

## 2. Arsitektur Solusi: Cyberpunk Telemetry Cockpit

Layar alert fullscreen dirombak menjadi satu kesatuan konsol instrumen telemetri kokpit penerbangan/transit masa depan:

### A. Distribusi Vertikal Layar (Edge-to-Edge)
1. **Top Cockpit Status Header (~60dp):**
   - Indikator LED pulsasi Amber/Cyan (`● HEDGE // LIVE DISPATCH`).
   - Identitas operator: `Headway Generator · By Mikrotrans Utara`.
   - Chip aktif multi-alarm (jika > 1 armada due/prep).
   - Bilah neon pemisah horizontal.

2. **Monolith Fleet Identifier (~110dp):**
   - Status badge kapsul: `[ ● WAKTU BERANGKAT ]` (Amber) / `[ ● BERSIAP BERANGKAT ]` (Cyan).
   - Tipografi nomor unit armada raksasa (**70sp–72sp**) tebal futuristik beraksen pendaran neon.

3. **Giant Chrono-Dial Radar (~220dp):**
   - Diameter dial diperbesar menjadi **210–220dp**.
   - Cincin luar bertindak sebagai *Circular Timeout Energy Arc Gauge* yang menyusut melingkar sesuai detik timeout.
   - Angka countdown digital besar (**38sp–42sp** bold) menampilkan `+00:04` (overdue/due) atau `00:04` (prep).

4. **Live Mission Telemetry Grid (~80dp — Pengisi Blank Space):**
   - Baris 3 kartu telemetri berdampingan bergaya cyber-capsule:
     - 🕒 **JADWAL:** `19:57 WIB`
     - 🚍 **RUTE:** `JAK.115`
     - 🔄 **PUTARAN:** `RITASE 1`

5. **Timeout Status & Tactical Action Console (~220dp):**
   - Pill sisa waktu: `Menutup otomatis dalam X detik`.
   - Keterangan instruksi: `Sudah Berangkat mencatat aktual. Timeout hanya menutup alert.`
   - Tombol Utama (56dp): *"✓ SUDAH BERANGKAT"* (Gradien Amber `#FF9800` ke `#FF6D00`, bayangan neon glow tebal, teks hitam bold).
   - Tombol Sekunder (48dp): *"✕ Tutup Alert"* (Dark surface, border slate).
   - Tombol Tersier (40dp): *"Matikan alarm rute"* (Outline HUD).

---

## 3. Komponen Teknis yang Terdampak

1. [`lib/ui/alarm_overlay.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart):
   - Restrukturisasi `ForegroundAlarmOverlay` dengan proporsi Cockpit HUD.
   - Peningkatan skala `DepartureFocusPanel` atau penggantian layout langsung ke Telemetry Cockpit.
   - Penambahan grid telemetri 3-kolom (Jadwal WIB, Rute, Ritase).
   - Penyesuaian `CustomPainter` untuk dial radar berdiameter 220dp dan arc timeout.

2. [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt):
   - Pembesaran `CyberDialGaugeView` ke diameter 220dp.
   - Penambahan busur timeout melingkar (*timeout arc*) pada Canvas 2D.
   - Penambahan baris horizontal 3 kotak telemetri native (Jadwal, Rute, Ritase).
   - Penghilangan sisa margin berlebih sehingga layout memenuhi vertikal layar secara proporsional.

3. [`pubspec.yaml`](file:///d:/MINE/HEDGE-FLUTTER/pubspec.yaml):
   - Kenaikan versi ke `2.0.9+12`.

4. Output Release APK:
   - Target direktori: `apks/v2.0.9/hedge-v2.0.9.apk` (tepat 1 file di dalam folder versi).

---

## 4. Kriteria Keberhasilan & Pengujian

- [x] Zero Blank Space: Tidak ada lagi kekosongan hitam vertikal yang janggal di antara informasi dan tombol.
- [x] Konsistensi Dual-Platform: Tampilan saat aplikasi dibuka (Flutter) dan saat layar terkunci (Native) 100% identik.
- [x] Keterbacaan Ekstrem: Nomor unit 70sp dan dial 220dp terbaca sekilas dari jarak jauh.
- [x] Verifikasi Statis & Test Suite: `dart analyze` 0 issues, `flutter test` 100% lulus.
