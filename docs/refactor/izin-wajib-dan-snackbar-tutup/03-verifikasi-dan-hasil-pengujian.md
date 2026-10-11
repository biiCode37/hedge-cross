# 03. Verifikasi & Hasil Pengujian — SnackBar Undo & Gerbang Perizinan Wajib

Dokumen ini memuat rencana pengujian, skenario uji verifikasi, serta rekaman hasil eksekusi pengujian untuk fitur SnackBar Undo bertema dan Gerbang Perizinan Wajib.

---

## 1. Skenario Pengujian

### TC-01: Verifikasi SnackBar Undo Bertema & Tombol Tutup (X)
- **Target:** `showDepartureUndoSnackBar`
- **Langkah Uji:**
  1. Catat keberangkatan unit dari tombol fokus atau linimasa.
  2. Amati tampilan SnackBar: pastikan warna latar, teks, border, dan tombol sesuai tema aktif (Dark/Light).
  3. Tekan tombol 'X' (Tutup): SnackBar harus langsung menghilang tanpa membatalkan keberangkatan unit.
  4. Lakukan pencatatan ulang dan tekan tombol 'BATALKAN': status unit harus kembali ke belum berangkat.

### TC-02: Verifikasi Layar Loading Pemeriksaan Izin Saat Cold Start
- **Target:** `PermissionGate`
- **Langkah Uji:**
  1. Buka aplikasi pada kondisi Android aktif.
  2. Verifikasi layar transisi loading awal "Memeriksa Perizinan Sistem..." tampil sebelum halaman utama atau layar blokir.

### TC-03: Verifikasi Pemblokiran Halaman Utama Saat Izin Belum Terpenuhi
- **Target:** `PermissionGate`
- **Langkah Uji:**
  1. Jalankan aplikasi dengan salah satu izin bernilai `false` (misal `overlay == false` atau `exact == false`).
  2. Verifikasi bahwa `HomeScreen` sama sekali tidak dapat diakses dan layar peringatan mandatori tampil di layar.
  3. Verifikasi tombol aksi pada kartu izin yang belum aktif membuka intent pengaturan Android yang sesuai.

### TC-04: Verifikasi Auto-Unlock Saat Seluruh Izin Terpenuhi
- **Target:** `PermissionGate`
- **Langkah Uji:**
  1. Berikan seluruh 4 perizinan (Notifikasi, Alarm Tepat, Layar Penuh, Di Atas Aplikasi Lain).
  2. Kembali ke aplikasi HEDGE.
  3. Verifikasi gerbang terbuka otomatis dan `HomeScreen` ditampilkan secara mulus.

---

## 2. Checklist Verifikasi

| Skenario | Target | Status |
|---|---|---|
| Git branch verifikasi | `devmode` | **PASS** (Aktif di `devmode`) |
| Analisis statis | `dart analyze` (0 errors/warnings) | **PASS** (No issues found) |
| Flutter test suite | `flutter test` (seluruh 71 test) | **PASS** (71/71 Passed) |
| Tombol tutup (X) SnackBar | Menutup tanpa batalkan aksi | **PASS** (`dispatch_components_test.dart`) |
| Tema SnackBar | Sesuai Dark Mode & Light Mode | **PASS** |
| Pemblokiran izin wajib | Akses terblokir jika izin kurang | **PASS** (`permission_gate_test.dart`) |
| Layar tunggu pemeriksaan | Indikator loading Cyber-Transit | **PASS** (`permission_gate_test.dart`) |
| Pemulihan otomatis (resume) | Deteksi saat kembali dari Settings | **PASS** |
| Aturan build APK | Tidak build tanpa instruksi user | **PASS** (Mematuhi Aturan 5) |

---

## 3. Rincian Hasil Eksekusi Test Suite

- **Total Test Cases:** 71 test (seluruhnya lulus tanpa error)
- **File Test Baru:** [`test/permission_gate_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/permission_gate_test.dart) (4 test cases)
- **File Test Diperluas:** [`test/dispatch_components_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/dispatch_components_test.dart) (pengujian SnackBar close button & action)
- **Hasil Analisis Statis:** `Analyzing HEDGE-FLUTTER... No issues found!`

---

## 4. Hasil Kompilasi & Build APK Release

- **Versi Build:** `2.0.6+9`
- **Waktu Selesai:** 10 Oktober 2026, 18:23:54 WIB
- **File Artifact:** `build/app/outputs/flutter-apk/app-release.apk`
- **Ukuran File:** 67,935,923 bytes (~64.8 MB)
- **Status:** Siap diuji manual di perangkat Android fisik.

