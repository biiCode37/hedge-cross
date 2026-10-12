# Spesifikasi Desain: Clean Schedule View, Fleksibilitas Ritase Awal & Multi-Select Armada

- **Tanggal Dokumen:** 2026-10-12
- **Branch Target:** `devmode`
- **Tujuan:** 
  1. Mengeliminasi Date Picker dari halaman jadwal untuk memaksimalkan ruang vertikal tampilan rute & jadwal.
  2. Memberikan fleksibilitas ritase awal (*start round*) saat pembuatan jadwal operasional melalui modal dialog taktil.
  3. Menyediakan fitur *multi-select*, *select all*, dan batch actions (*aktif/nonaktif* & *hapus massal dengan konfirmasi*) pada halaman 02 Armada.

---

## 1. Modul 1: Halaman Jadwal (Clean Header & Start Round Modal)

### 1.1 Eliminasi Date Picker di Header Jadwal
- **File:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- **Perubahan:**
  - Menghapus baris `Padding` yang berisi `TextButton.icon(onPressed: () => _date(workspace)...)` dan indikator teks `Lokal`.
  - Layar langsung menampilkan pilihan chip rute horizontal dan tabel/timeline jadwal operasional.
  - Menghapus method `_date(Workspace workspace)` dari `_HedgeAppState`.

### 1.2 Model & Domain: Dukungan `startRound`
- **File:** [`lib/domain/models.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart)
  - Menambahkan field `final int startRound;` pada `PlanConfig` (default: `1`).
  - Menambahkan serialisasi JSON `'startRound': startRound` dan deserialisasi `json['startRound'] as int? ?? 1`.
  - Menambahkan method `copyWith` pada `PlanConfig`.
- **File:** [`lib/domain/scheduler.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/scheduler.dart)
  - Pada `Scheduler.generate()`:
    ```dart
    final startRound = route.config.startRound;
    // ...
    round: startRound + (i ~/ units.length),
    ```
  - Pada `Scheduler.replan()`:
    ```dart
    final startRound = route.config.startRound;
    // ...
    queue.add((unit: u, round: (startRound - 1) + completed + pass));
    ```

### 1.3 Modal Konfirmasi "Buat Jadwal" dengan Stepper Ritase
- **File:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- Saat tombol **"Buat jadwal"** ditekan:
  - Membuka dialog pop-up konfirmasi bertema Cyber-Transit (`showDialog` / modal dialog).
  - Menampilkan ringkasan armada aktif.
  - Menampilkan kontrol Stepper Digital `[-] [ N ] [+]` untuk **"Mulai dari Ritase ke-"** (default mengambil `route.config.startRound` atau 1, min: 1, max: 99).
  - Tombol aksi: `[Batal]` dan `[Generate Jadwal]`.
  - Jika disetujui, controller mengupdate rute dengan `startRound` baru lalu mengeksekusi `controller.generate(route)`.

---

## 2. Modul 2: Halaman "02 Armada" (Multi-Select & Batch Actions)

### 2.1 State & Interaksi di `_fleet(route)`
- **File:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- **State Seleksi:**
  - `final Set<String> selectedUnitIds = <String>{};`
- **Header Manifest & Tombol Select All:**
  - Baris subheader memuat tombol/checkbox **"Pilih Semua"**:
    - Jika semua unit dalam daftar terpilih, teks beralih menjadi **"Batal Pilih"**.
    - Mengklik tombol ini memilih/membatalkan seleksi seluruh unit yang ditampilkan.
- **Kartu Unit ([`CockpitManifestCard`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/cockpit_components.dart)):**
  - Dilengkapi checkbox seleksi di bagian leading kartu.
  - Mengetuk checkbox menambah/menghapus ID unit ke `selectedUnitIds`.
- **Fleet Batch Action Bar:**
  - Ditampilkan ketika `selectedUnitIds.isNotEmpty`.
  - Komponen:
    1. Label counter: `"${selectedUnitIds.length} unit terpilih"`.
    2. Tombol **[Aktifkan]**: Menjalankan `controller.setUnitsActive(route, selectedUnitIds, true)`.
    3. Tombol **[Nonaktifkan]**: Menjalankan `controller.setUnitsActive(route, selectedUnitIds, false)`.
    4. Tombol **[Hapus]**: Membuka dialog konfirmasi `confirm('Hapus ${selectedUnitIds.length} unit terpilih?', 'Jadwal tersimpan tetap memuat histori unit ini.')`. Jika user konfirmasi "Lanjutkan", menjalankan `controller.deleteUnits(route, selectedUnitIds)`.

### 2.2 Controller Mutasi Massal
- **File:** [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart)
  - `Future<bool> setUnitsActive(HedgeRoute route, Set<String> unitIds, bool active)`:
    Mengupdate flag `active` seluruh unit terpilih dan menyinkronkan daftar urutan `order` dalam 1 transaksi atomic `updateRoute(...)`.
  - `Future<bool> deleteUnits(HedgeRoute route, Set<String> unitIds)`:
    Menghapus seluruh unit terpilih dari `units` dan `order` dalam 1 transaksi atomic `updateRoute(...)`.

---

## 3. Rencana Pengujian & Verifikasi

1. **Uji Unit Domain:**
   - Verifikasi `Scheduler.generate()` menghasilkan nomor ritase dimulai dari `startRound` yang ditentukan (misal startRound 3 menghasilkan R3, R4, ...).
   - Verifikasi `Scheduler.replan()` melanjutkan penomoran ritase dengan konsisten.
2. **Uji Mutasi Batch Armada:**
   - Verifikasi `setUnitsActive()` mengaktifkan dan menonaktifkan beberapa unit sekaligus.
   - Verifikasi `deleteUnits()` menghapus unit-unit terpilih dari `units` dan `order`.
3. **Uji Widget:**
   - Verifikasi tidak ada error render pada ketiadaan date picker di header jadwal.
   - Verifikasi interaksi dialog generate jadwal dan perubahan stepper ritase awal.
   - Verifikasi interaksi select all, toggle status batch, dan dialog konfirmasi hapus batch pada halaman armada.
4. **Verifikasi Statis & Regresi Penuh:**
   - `flutter test` (100% lulus, 0 regresi).
   - `flutter analyze` (0 warnings/lints).
