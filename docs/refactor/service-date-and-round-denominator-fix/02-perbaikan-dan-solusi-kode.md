# 02. Perbaikan & Solusi Kode — Sinkronisasi Tanggal Operasional & Perhitungan Denominator Ritase

Dokumen ini menjelaskan arsitektur solusi teknis dan detail perbaikan kode untuk mengatasi bug countdown akibat tanggal lampau dan kekeliruan nomor putaran target pada pill telemetri armada.

---

## 1. Arsitektur Solusi Teknis

### A. Siklus Tanggal Operasional Otomatis (Automatic Service Date Lifecycle)
1. **Inisialisasi Tanggal Hari Ini saat Startup (`LocalWorkspaceRepository.load()`)**:
   - Menghapus pemuatan tanggal statis usang dari tabel SQLite `settings['date']`.
   - Menginisialisasi `date` workspace selalu mengikuti tanggal operasional Jakarta saat ini via `serviceDate(DateTime.now())`.
2. **Pembuatan Jadwal Berdasarkan Tanggal Operasional Hari Ini (`WorkspaceController.generate` & `generateAll`)**:
   - Scheduler generation tidak lagi menggunakan `state.workspace.date` yang berisiko kedaluwarsa, melainkan mengevaluasi `final today = serviceDate(DateTime.now())`.
   - Jadwal baru yang dicatat selalu bertanggal hari ini, dan `workspace.date` diperbarui ke `today`.
3. **Perlindungan Jadwal Kedaluwarsa pada Dispatch Focus & TV Board (`selectDispatchFocus` & `BoardScreen`)**:
   - Jika rute memiliki revisi jadwal tersimpan dari hari kemarin (`revision.date != workspace.date`), jadwal tersebut tidak akan dipilih ke HUD countdown langsung.
   - Papan TV Board (`BoardScreen`) menyaring revisi lampau agar tidak menampilkan antrean keberangkatan kemarin.
   - Tampilan jadwal menampilkan pesan informatif:
     `"Jadwal tersimpan bertanggal YYYY-MM-DD (hari sebelumnya). Silakan buat jadwal baru untuk hari ini (YYYY-MM-DD)."`
4. **Deteksi Rollover Pergantian Hari (`WorkspaceController.syncDateIfNeeded`)**:
   - Clock stream listener mendeteksi pergantian menit. Jika tanggal kalender berganti (misal lewat tengah malam), controller otomatis menyinkronkan tanggal workspace ke hari baru.

### B. Denominator Ritase Berbasis Putaran Akhir (`FleetTelemetryPillBar`)
1. **Refactoring Semantik Denominator (`maxRound`)**:
   - Mengganti parameter `totalRounds` pada `FleetTelemetryPillBar` menjadi `maxRound`.
   - Menghitung nilai putaran akhir dari jadwal aktual:
     ```dart
     maxRound: revision.departures.isNotEmpty
         ? revision.departures
             .map((d) => d.round)
             .reduce((a, b) => a > b ? a : b)
         : (route.config.startRound + route.config.rounds - 1)
     ```
2. **Format Tampilan yang Benar**:
   - Jika rute disetel 3 ritase mulai dari Rit 2:
     - Ritase keberangkatan: Rit 2, Rit 3, Rit 4.
     - `maxRound` bernilai **4**.
     - Pill menampilkan format presisi: `'Ritase 2/4'`, `'Ritase 3/4'`, dan `'Ritase 4/4'`.

---

## 2. File-File yang Dimodifikasi

1. [`lib/ui/telemetry_bar.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/telemetry_bar.dart):
   - Mengubah parameter `totalRounds` menjadi `maxRound`.
   - Menampilkan `'Ritase $currentRound/$maxRound'`.

2. [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart):
   - Mengirimkan `maxRound` yang dihitung dari putaran tertinggi pada jadwal (`departures.map((d) => d.round).reduce(max)`).
   - Memanggil `controller.syncDateIfNeeded(instant)` setiap pergantian menit.
   - Memperbarui teks warning banner agar tidak membingungkan pengguna dengan label "Tanggal pilihan".

3. [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart):
   - Menambahkan metode `syncDateIfNeeded(DateTime instant)`.
   - Pada `generate()` dan `generateAll()`, selalu gunakan `serviceDate(now)` dan simpan tanggal workspace yang sinkron.

4. [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart):
   - Menyaring revisi yang tanggalnya tidak cocok dengan `workspace.date`.

5. [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart):
   - Menyaring revisi yang tidak sesuai dengan `workspace.date` pada papan TV Board.

6. [`lib/data/workspace_repository.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/data/workspace_repository.dart):
   - Menginisialisasi `date: serviceDate(DateTime.now())` saat pembacaan database.

7. [`test/telemetry_bar_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/telemetry_bar_test.dart):
   - Menyesuaikan pengetesan dengan `maxRound` dan menambahkan unit test skenario `startRound: 2`, `rounds: 3` -> `Ritase 2/4`.

8. [`test/scheduler_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/scheduler_test.dart):
   - Menambahkan test case kalkulasi ritase mulai dari 2 sebanyak 3 putaran.

9. [`test/design_system_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/design_system_test.dart):
   - Menambahkan verifikasi bahwa `selectDispatchFocus` menolak jadwal yang tanggalnya tidak cocok.
