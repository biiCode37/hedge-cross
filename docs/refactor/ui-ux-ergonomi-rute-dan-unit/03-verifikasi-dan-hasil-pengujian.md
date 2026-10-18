# Verifikasi & Hasil Pengujian: Ergonomi Tampilan Rute dan Unit

## 1. Rencana Pengujian Otomatis & Manual

Pengujian difokuskan pada integritas logika domain (pemecahan kode dan lintasan rute), stabilitas UI presentation, responsivitas layout, dan verifikasi aturan Git/APK:

### A. Unit Testing Parser Rute
- Membuat file pengujian unit baru pada `test/domain/route_name_parser_test.dart` untuk menguji:
  - String rute standar dengan tanda hubung minus: `JAK.01 - TANJUNG PRIOK - PLUMPANG` -> code: `JAK.01`, trajectory: `TANJUNG PRIOK - PLUMPANG`.
  - String rute dengan tanda en-dash / em-dash: `JAK.115 – TERM.TANJUNG PRIOK` -> code: `JAK.115`, trajectory: `TERM.TANJUNG PRIOK`.
  - String rute dengan suffix huruf: `JAK.110A - RUSUN MARUNDA` -> code: `JAK.110A`, trajectory: `RUSUN MARUNDA`.
  - String rute tanpa lintasan: `JAK.88` -> code: `JAK.88`, trajectory: `''`.
  - **Hasil Test:** **6/6 Passed** (`All tests passed!`).

### B. Widget & UI Testing
- `test/ui/top_bar_route_pills_test.dart`:
  - Memastikan top bar rute hanya menampilkan rute yang berstatus aktif (`participates == true`).
  - Memastikan label pill hanya menampilkan kode rute (`route.code`) dengan indikator dirty (`•`).
  - **Hasil Test:** **2/2 Passed** (`All tests passed!`).
- `test/ui/route_sorting_test.dart`:
  - Memastikan tab "04 Rute" menampilkan rute aktif di urutan teratas secara stabil.
  - Memastikan nama trayek rute terpisah deterministik dari kode rute.
  - **Hasil Test:** **2/2 Passed** (`All tests passed!`).
- `test/ui/searchable_unit_picker_test.dart`:
  - Memastikan komponen `SearchableUnitPicker` merender opsi unit dengan benar, mampu menyaring daftar saat kata kunci diketik, mendukung tombol clear selection, dan mengembalikan nomor unit terpilih ke state form.
  - **Hasil Test:** **3/3 Passed** (`All tests passed!`).
- `test/widget_test.dart`:
  - Memastikan seluruh flow aplikasi berjalan mulus pada breakpoint 360dp (smartphone mobile) dan 1200dp (tablet/desktop) pada Dark Mode maupun Light Mode.
  - **Hasil Test:** **4/4 Passed** (`All tests passed!`).

---

## 2. Checklist Verifikasi Akhir

- [x] Branch Git terverifikasi adalah `devmode`.
- [x] Tidak menjalankan perintah build APK otomatis (mematuhi **Rule 5**).
- [x] Top bar pill hanya memuat kode rute dan hanya menampilkan rute yang aktif (`participates == true`).
- [x] Halaman "04 Rute" menampilkan nama lintasan di bawah kode rute (bebas dari pemotongan teks / truncation).
- [x] Halaman "04 Rute" mengurutkan rute aktif di bagian paling atas.
- [x] Halaman selain "04 Rute" (termasuk Master Pramudi, Avionics Header, TV Board, Telemetry Card) hanya menampilkan kode rute.
- [x] Form Tambah Pramudi memiliki searchable dropdown untuk pemilihan nomor unit (`SearchableUnitPicker`).
- [x] Layout filter bar pada Master Pramudi responsif dan tidak terpotong (Search box full-width dan segmented filter rapi).
- [x] Lolos verifikasi tema Dark Mode (Obsidian `#070B12`) dan Light Mode (Silver `#F8FAFC`).
