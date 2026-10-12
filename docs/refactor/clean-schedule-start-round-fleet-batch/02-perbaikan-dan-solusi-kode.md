# 02. Perbaikan & Solusi Kode — Clean Schedule View, Start Round & Batch Fleet

Dokumen ini memuat penjelasan arsitektur solusi, detail kode yang diperbaiki, dan file-file yang dimodifikasi pada HEDGE (Headway Generator).

---

## 1. Arsitektur Solusi & Rancang Bangun

Penyelesaian masalah dibagi ke dalam dua modul kerja yang saling melengkapi:

```
+-------------------------------------------------------------------+
| MODUL 1: HALAMAN JADWAL                                           |
| 1. Eliminasi Baris Date Picker di Header (Ruang Vertikal Maksimal)|
| 2. Modal Cepat 'Buat Jadwal' dengan Stepper Ritase Mulai:         |
|    [-]  [ RIT 3 ]  [+]  ==> Generate dari R3 s.d. R10             |
+-------------------------------------------------------------------+
| MODUL 2: HALAMAN 02 ARMADA                                        |
| 1. Baris Seleksi: [x] Pilih Semua / Batal Pilih                   |
| 2. Indikator Kotak Seleksi Taktil 38x38 (Zero-Overflow Layout)    |
| 3. Fleet Batch Action Bar:                                        |
|    [ 5 DIPILIH ]  [Aktifkan]  [Nonaktifkan]  [Hapus Massal (x)]   |
| 4. Atomic Mutation di WorkspaceController (1 Transaksi SQLite)    |
+-------------------------------------------------------------------+
```

---

## 2. Rincian Modifikasi Kode

### A. [`lib/domain/models.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart)
- Menambahkan properti `final int startRound;` (default `1`) pada `PlanConfig`.
- Menambahkan method `copyWith()` pada `PlanConfig`.
- Menambahkan serialisasi dan deserialisasi JSON:
  ```dart
  startRound: json['startRound'] as int? ?? 1,
  ```

### B. [`lib/domain/scheduler.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/scheduler.dart)
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

### C. [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart)
- Menambahkan method batch atomic:
  ```dart
  Future<bool> setUnitsActive(HedgeRoute route, Set<String> unitIds, bool active) {
    final order = [
      ...route.order.where((id) => !unitIds.contains(id)),
      if (active) ...route.units.where((u) => unitIds.contains(u.id)).map((u) => u.id),
    ];
    return updateRoute(
      route.copyWith(
        units: route.units
            .map((u) => unitIds.contains(u.id) ? u.copyWith(active: active) : u)
            .toList(),
        order: order,
      ),
    );
  }

  Future<bool> deleteUnits(HedgeRoute route, Set<String> unitIds) => updateRoute(
    route.copyWith(
      units: route.units.where((u) => !unitIds.contains(u.id)).toList(),
      order: route.order.where((id) => !unitIds.contains(id)).toList(),
    ),
  );
  ```

### D. [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
1. **Pembersihan Header Jadwal:**
   - Menghapus baris `Padding` berisi `TextButton.icon(onPressed: () => _date(workspace)...)` dan indikator teks `Lokal`.
   - Menghapus method `_date()`.
2. **Modal Konfirmasi & Stepper Ritase (`_promptGenerate`):**
   - Dialog bertema Cyber-Transit menampilkan ringkasan rute, armada aktif, dan stepper digital `[-] [ RIT N ] [+]`.
   - Mengupdate rute dengan `startRound` terpilih sebelum menjalankan `controller.generate()`.
3. **Multi-Select & Batch Fleet Actions (`_fleet`):**
   - State `selectedFleetIds` untuk menyimpan ID armada yang dipilih.
   - Baris kontrol **"Pilih Semua"** / **"Batal Pilih"** dan counter terpilih.
   - **Batch Action Bar** dengan tombol `[Aktifkan]`, `[Nonaktifkan]`, dan `[Hapus]` (dengan dialog konfirmasi `confirm()`).
   - Kotak ubin leading berukuran tetap 38x38dp yang beralih menjadi checkbox aktif saat dipilih (menjamin zero-overflow di layar 360dp dan font scale 1.6x).
