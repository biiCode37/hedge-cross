# 03. Verifikasi & Hasil Pengujian — Clean Schedule, Start Round & Batch Fleet

Dokumen ini memuat catatan command verifikasi, hasil eksekusi uji unit dan widget test Flutter, serta verifikasi analisis statis kode.

---

## 1. Lingkungan & State Pengujian

- **Branch Git Aktif:** `devmode`
- **Flutter SDK:** Flutter 3.x (Dart 3.x)
- **Komponen yang Diverifikasi:**
  - [`lib/domain/models.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart)
  - [`lib/domain/scheduler.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/scheduler.dart)
  - [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart)
  - [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
  - Seluruh suite pengujian di folder `test/`

---

## 2. Perintah Verifikasi & Hasil Eksekusi

### A. Uji Scheduler & Penomoran Ritase Awal
Perintah:
```bash
flutter test test/scheduler_test.dart
```
**Hasil:**
- `Flexible startRound generates and replans with custom starting round` — **PASS**
- Seluruh 26 test cases di `test/scheduler_test.dart` lulus (100% PASS).

### B. Uji Batch Operation Controller
Perintah:
```bash
flutter test test/repository_test.dart
```
**Hasil:**
- `Batch fleet operations setUnitsActive and deleteUnits update atomically` — **PASS**
- Seluruh 5 test cases di `test/repository_test.dart` lulus (100% PASS).

### C. Uji Responsivitas UI Layar Sempit & Skala Teks 1.6x
Perintah:
```bash
flutter test test/design_system_test.dart test/widget_test.dart
```
**Hasil:**
- `Dispatcher 360.0 dark: fleet edits preserve committed schedule` — **PASS**
- `Dispatcher 360.0 light: fleet edits preserve committed schedule` — **PASS**
- `Small screen and enlarged text dark remain navigable` — **PASS**
- `Small screen and enlarged text light remain navigable` — **PASS**
- Zero overflow error (0 RenderFlex errors).

### D. Uji Regresi Penuh Seluruh Proyek
Perintah:
```bash
flutter test
```
**Hasil:**
```
00:29 +77: All tests passed!
```
*Status:* **77 / 77 Tests PASS (0 Gagal, 0 Regresi)**

### E. Analisis Statis Kode (Linting & Typing)
Perintah:
```bash
flutter analyze
```
**Hasil:**
```
Analyzing HEDGE-FLUTTER...
No issues found! (ran in 6.6s)
```
*Status:* **Clean (0 errors, 0 warnings, 0 lints)**

---

## 3. Matriks Pengujian Fungsional

| Skenario Uji | Ekspektasi | Hasil |
|---|---|---|
| **Eliminasi Date Picker** | Header jadwal langsung menampilkan rute dan timeline tanpa tombol tanggal | **Lolos** |
| **Modal Start Round** | Stepper `[-] [ RIT N ] [+]` dapat menaikkan/menurunkan ritase awal | **Lolos** |
| **Penomoran Jadwal Baru** | Jika startRound diatur ke 3, keberangkatan berurutan R3, R4, R5, dst. | **Lolos** |
| **Pilih Semua (Select All)** | Memilih seluruh unit armada yang ada dalam rute/pencarian | **Lolos** |
| **Batal Pilih (Deselect All)** | Membersihkan seluruh unit yang sedang dipilih | **Lolos** |
| **Aktifkan Massal** | Semua unit terpilih diubah menjadi `active: true` | **Lolos** |
| **Nonaktifkan Massal** | Semua unit terpilih diubah menjadi `active: false` | **Lolos** |
| **Hapus Massal** | Menampilkan dialog konfirmasi lalu menghapus semua unit terpilih jika disetujui | **Lolos** |
| **Responsivitas 360dp** | Tidak terjadi overflow di layar sempit Android maupun skala teks membesar | **Lolos** |
