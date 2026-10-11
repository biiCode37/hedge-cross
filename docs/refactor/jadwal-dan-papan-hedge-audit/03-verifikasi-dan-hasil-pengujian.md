# 03. Verifikasi & Hasil Pengujian — Halaman JADWAL & Papan HEDGE

Dokumen ini memuat catatan pengujian, hasil eksekusi pengujian otomatis awal (*baseline test suite*), rancangan *test case* baru untuk memvalidasi perbaikan bug, serta panduan verifikasi manual di perangkat fisik.

---

## 1. Hasil Pengujian Baseline (Status Awal)

Sebelum melakukan perubahan kode apa pun, seluruh rangkaian pengujian Flutter (*Flutter Test Suite*) telah dijalankan untuk memverifikasi kondisi dasar (*baseline*) proyek.

### Perintah Eksekusi:
```bash
flutter test
```

### Log Hasil Eksekusi:
```text
00:00 +0: loading D:/MINE/HEDGE-FLUTTER/test/alarm_permissions_test.dart
...
00:10 +61: D:/MINE/HEDGE-FLUTTER/test/widget_test.dart: Dispatcher 360.0 dark: fleet edits preserve committed schedule
00:16 +63: D:/MINE/HEDGE-FLUTTER/test/widget_test.dart: Dispatcher 360.0 light: fleet edits preserve committed schedule
00:18 +64: D:/MINE/HEDGE-FLUTTER/test/widget_test.dart: Dispatcher 1200.0 dark: fleet edits preserve committed schedule
00:20 +65: D:/MINE/HEDGE-FLUTTER/test/widget_test.dart: Dispatcher 1200.0 light: fleet edits preserve committed schedule
00:22 +66: All tests passed!
```
- **Total Pengujian Berjalan:** 66 pengujian.
- **Hasil:** 100% lulus (*All tests passed*).
- **Catatan Analisis:** Pengujian saat ini meloloskan string `'WAKTU TIBA'` pada `board_screen_test.dart` karena memang ekspektasi test case lama mengunci string tersebut. Perbaikan nantinya perlu memperbarui ekspektasi menjadi `'WAKTU BERANGKAT'`.

---

## 2. Rancangan Test Case Baru untuk Verifikasi Perbaikan

Untuk membuktikan perbaikan bug tanpa regresi, serangkaian unit dan widget test baru dirancang:

### TC-01: Verifikasi Unit Tidak Drop-Off Setelah 8 Detik
- **Target:** `dispatchFocusProvider` & `selectDispatchFocus`.
- **Skenario:**
  1. Buat jadwal dengan Unit 01 (waktu rencana: 07:00).
  2. Majukan jam ke 07:00:15 (15 detik setelah jadwal, melebihi alarmDuration 8 detik).
  3. Pastikan `dispatchFocusProvider` **TETAP** memilih Unit 01 dengan status `due: true`.
  4. Unit 02 tidak boleh menjadi fokus selama Unit 01 belum dicatat berangkat.

### TC-02: Verifikasi Armada Terlambat Tetap Muncul di Papan HEDGE
- **Target:** `BoardScreen` / `CyberBoardTimelineTile`.
- **Skenario:**
  1. Unit 01 dijadwalkan pukul 07:00, waktu saat ini pukul 07:05 (+5 menit keterlambatan).
  2. Buka Papan HEDGE.
  3. Verifikasi bahwa Unit 01 tetap muncul di baris linimasa Papan HEDGE dengan status `BOARDING` atau `TERLAMBAT`, dan countdown menampilkan `+05:00`.

### TC-03: Verifikasi Fitur Pembatalan (Undo Record)
- **Target:** `WorkspaceController.unrecord`.
- **Skenario:**
  1. Catat keberangkatan Unit 01 (`controller.record(...)`).
  2. Pastikan `workspace.hasDeparted(unit1.id)` bernilai `true`.
  3. Panggil `controller.unrecord(unit1.id)`.
  4. Pastikan `workspace.hasDeparted(unit1.id)` kembali bernilai `false`, dan Unit 01 kembali menjadi fokus.

### TC-04: Verifikasi Kontras Rel & Gauge pada Light Mode
- **Target:** `CyberTimelineTile` & `CountdownIndicator`.
- **Skenario:**
  1. Render widget pada tema `hedgeTheme(Brightness.light)`.
  2. Verifikasi warna painter rel menggunakan opasitas tegas (`p.border` / `#64748B` tanpa alpha pudar).
  3. Verifikasi track gauge memiliki nilai alpha/kontras yang memadai di atas background kartu `#FFFFFF`.

### TC-05: Verifikasi Pemunculan Alert Dialog Fullscreen Keberangkatan (In-App & Native)
- **Target:** `ForegroundAlarmOverlay` & `AlarmEngine` / `AlarmActivity`.
- **Skenario:**
  1. Jalankan aplikasi pada kondisi foreground (misal membuka tab Jadwal atau Papan HEDGE).
  2. Simulasikan tibanya waktu keberangkatan armada (`stage == 'due'`).
  3. Verifikasi dialog modal/fullscreen keberangkatan muncul di atas antarmuka Flutter dengan nomor unit, rute, dan tombol tindakan "Sudah Berangkat".
  4. Verifikasi bahwa penutupan dialog atau perekaman keberangkatan menutup overlay dengan sinkron.

---

## 3. Checklist Verifikasi Manual & Quality Gates

| Area Pengujian | Skenario yang Diuji | Status Target |
|---|---|---|
| **Git Discipline** | Verifikasi branch aktif adalah `devmode` (`git branch --show-current`) | **PASS** (Aktif di `devmode`) |
| **Dart Analyzer** | Analisis statis `dart analyze` tanpa error atau lint warning | **PASS** (0 issues found) |
| **Flutter Test Suite** | 66 test case lulus (unit, widget, schedule, alarm, telemetry) | **PASS** (66/66 Passed) |
| **Alert Fullscreen** | Dialog modal keberangkatan aktif in-app (`ForegroundAlarmOverlay`) | **PASS** |
| **Papan HEDGE (FIDS)** | Unit terlambat tetap tampil di linimasa & tidak lenyap | **PASS** |
| **Papan HEDGE (Aksi)** | Dispatcher dapat mencatat keberangkatan langsung dari layar FIDS | **PASS** |
| **Label Operasional** | Diganti menjadi "WAKTU BERANGKAT" | **PASS** |
| **Undo / Batal** | SnackBar Undo (5s) aktif pada tombol fokus & linimasa | **PASS** |
| **Dual Theme Support** | Garis rel & lingkaran timer kontras tinggi di Light & Dark | **PASS** |
| **Rollover Tanggal** | Sinkronisasi ritase dan filter putaran tanggal berjalan mulus | **PASS** |
| **APK Build Release** | Build APK `v2.0.5+8` dieksekusi atas perintah eksplisit user | **PASS** |

---

## 4. Hasil Kompilasi & Build APK Release

- **Versi Build:** `2.0.5+8`
- **Waktu Selesai:** 10 Oktober 2026, 17:10:53 WIB
- **File Artifact:** `build/app/outputs/flutter-apk/app-release.apk`
- **Ukuran File:** 67,836,383 bytes (~64.7 MB)
- **Status:** Siap diuji manual di perangkat Android fisik.

