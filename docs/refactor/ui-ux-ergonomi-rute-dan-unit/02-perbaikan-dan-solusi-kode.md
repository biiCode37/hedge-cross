# Perbaikan & Solusi Kode: Ergonomi Tampilan Rute, Truncation, dan Seleksi Unit

## 1. Arsitektur Solusi & Pemisahan Tanggung Jawab

Perbaikan diimplementasikan dengan mematuhi prinsip *clean architecture*, modularitas, dan konsistensi token desain HEDGE:

1. **Domain Layer (`lib/domain/models.dart`):**
   - Menambahkan parser murni `splitRouteName` dengan tipe hasil terstruktur `ParsedRouteName = ({String code, String trajectory})`.
   - Parser memisahkan kode rute (seperti `JAK.01`, `JAK.115`, `JAK.110A`) dari nama lintasan/trayek secara aman dengan regex deterministik.
   - Menyediakan getter helper pada `HedgeRoute`: `route.code` dan `route.trajectory`.

2. **Top Bar Route Pills (`lib/ui/app.dart`):**
   - Memfilter rute yang ditampilkan pada `ListView.separated` di header atas hanya untuk rute yang aktif (`r.participates == true`).
   - Merender label pill menggunakan `r.code` saja (tanpa lintasan), menghemat lebih dari 65% ruang horizontal layar per pill.

3. **Halaman "04 Rute" (`lib/ui/app.dart`):**
   - **Sorting Prioritas:** Mengurutkan daftar rute agar rute aktif (`r.participates == true`) selalu berada di posisi paling atas, disusul oleh rute non-aktif di bawahnya.
   - **Tata Letak Kartu Rute:**
     - **Baris 1 (Title Row):** Menampilkan `r.code` tebal (16sp) bersanding dengan badge status `[AKTIF / NONAKTIF]` dan menu opsi `⋮`.
     - **Baris 2 (Trajectory):** Jika memiliki lintasan (`r.trajectory.isNotEmpty`), ditampilkan di bawah kode rute dengan warna kontras silver muted (12.5sp) dan line-break yang rapi.
     - **Baris 3 (Subtitle):** Info armada dan jam operasional (`${r.activeUnits.length} unit · ${r.config.start}–${r.config.end}`).

4. **Halaman Selain "04 Rute" (Header & Tampilan Konteks):**
   - Pada `driver_master_sheet.dart` dan komponen tampilan lainnya, nama rute diganti menggunakan `r.code`.
   - Mencegah tabrakan visual teks dengan tombol aksi header.

5. **Komponen Reusable Searchable Unit Dropdown (`lib/ui/components/searchable_unit_picker.dart`):**
   - Membuat komponen pemilih unit dengan dialog/modal bottom sheet bertema cyberpunk HEDGE (Obsidian `#070B12`, Cyan `#00E5FF`, Amber `#FF9800`).
   - Menyediakan kotak pencarian instan (*real-time filter*) untuk nomor body / kode operator armada.
   - Menggantikan `TextField` manual pada dialog Tambah/Edit Pramudi di `driver_master_sheet.dart` dan form penugasan armada lainnya.

6. **Perbaikan Responsive Filter Bar di Master Pramudi (`lib/ui/driver_master_sheet.dart`):**
   - Menata ulang layout baris filter pencarian agar tidak terhimpit oleh segmented button, memastikan search bar dan segmen filter tetap proporsional di semua ukuran layar smartphone.

---

## 2. Rencana Implementasi & Modifikasi File

1. `lib/domain/models.dart`: Tambah fungsi `splitRouteName` dan helper getter pada model `HedgeRoute`.
2. `lib/ui/components/searchable_unit_picker.dart`: Pembuatan widget dropdown searchable terstandar.
3. `lib/ui/app.dart`:
   - Filter pill rute aktif & label hanya kode rute.
   - Sort rute aktif ke posisi teratas pada tab "04 Rute".
   - Tata letak multi-line untuk nama rute di bawah kode rute pada kartu rute tab "04 Rute".
4. `lib/ui/driver_master_sheet.dart`:
   - Ganti tampilan rute header menjadi kode rute saja.
   - Pasang `SearchableUnitDropdown` pada dialog Tambah Pramudi.
   - Rapikan layout pencarian dan segmented button.
