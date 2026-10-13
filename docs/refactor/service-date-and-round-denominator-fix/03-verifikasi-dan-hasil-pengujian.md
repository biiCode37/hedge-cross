# 03. Verifikasi & Hasil Pengujian — Tanggal Operasional & Denominator Ritase

Dokumen ini mencatat langkah pengujian, perintah verifikasi, cakupan test case baru, dan hasil pengujian otomatis untuk perbaikan tanggal operasional dan kalkulasi denominator ritase.

---

## 1. Perintah Pengujian

Semua pengujian dijalankan pada terminal **Git Bash / zsh** pada branch `devmode`:

```bash
# Verifikasi cabang git aktif
git branch --show-current

# Eksekusi seluruh rangkaian unit dan widget test
flutter test
```

---

## 2. Test Case Baru & Pengujian yang Diperbarui

### A. Pengujian Denominator Ritase (`test/telemetry_bar_test.dart`)
1. **Pembaruan Parameter `maxRound`**:
   - Memastikan `FleetTelemetryPillBar` merender metrik armada, ritase, dan headway dalam mode Dark maupun Light.
2. **Skenario Khusus Ritase Lanjutan (Start Round 2, 3 Putaran)**:
   - Diberikan konfigurasi: `activeUnits: 5`, `currentRound: 2`, `maxRound: 4` (`startRound: 2 + rounds: 3 - 1 = 4`), `headwayMinutes: 5`.
   - Hasil: Teks `'Ritase 2/4'` berhasil ditemukan dan tampil presisi tanpa error overflow.

### B. Pengujian Rentang Ritase Scheduler (`test/scheduler_test.dart`)
1. **Verifikasi Generasi Rit 2 s.d. Rit 4**:
   - Diberikan rute dengan `units: 2`, `rounds: 3`, `startRound: 2`.
   - Memverifikasi keberangkatan awal bernilai `round: 2`, keberangkatan akhir bernilai `round: 4`, dan himpunan nomor putaran adalah `{2, 3, 4}`.

### C. Pengujian Isolasi Jadwal Kedaluwarsa (`test/design_system_test.dart`)
1. **Penolakan Jadwal Beda Tanggal pada Dispatch Focus**:
   - Memverifikasi bahwa `selectDispatchFocus` mengembalikan `null` jika tanggal jadwal tersimpan tidak cocok dengan tanggal workspace (misal jadwal kemarin saat hari ini sudah berganti).

---

## 3. Hasil Pengujian Keseluruhan

```
00:28 +79: All tests passed!
```

- **Total Test**: 79 unit dan widget test
- **Status**: 100% Passed (0 Failures, 0 Errors)
- **Kompatibilitas Tema**: Teruji penuh pada Dark Mode dan Light Mode (`hedgeTheme`).
- **Kompatibilitas Layar Sempit**: Bebas overflow pada layar dispatcher 320x640 dan 360x800.
