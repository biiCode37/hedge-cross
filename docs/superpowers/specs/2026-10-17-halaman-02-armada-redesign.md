# Spesifikasi Desain: Redesain Halaman 02 Armada HEDGE

- **Tanggal:** 2026-10-17
- **Topik:** Pembaruan UI/UX Daftar Unit & Mekanisme Pengurutan Aktivasi Seleksi Unit
- **Status:** Approved by User

---

## 1. Latar Belakang & Kebutuhan Pengguna

Pada Halaman **"02 Armada"** (tampilan `_fleet` di `lib/ui/app.dart`), terdapat beberapa kebutuhan operasional dari dispatcher di lapangan:
1. **Pembersihan Teks Prefix "Unit":** Kata "Unit" di setiap baris daftar armada dinilai redundan dan mempersempit ruang baca nomor armada pada layar smartphone.
2. **Pemisahan Kode Operator & Nomor Body:** Nomor armada Mikrotrans umumnya terdiri dari kode operator/kombinasi huruf (seperti `KLM`, `KWK`, `TSU`, `JAK`) dan nomor seri body (angka seperti `540`, `001`, `1168`). Dispatcher membutuhkan pemisahan vertikal: kode operator diletakkan di bagian atas dengan font micro/tactical, dan nomor body diletakkan di bawahnya dengan ukuran besar dan tegas.
3. **Penandaan Auto-Increment `[1, 2, 3...]` Menggantikan Centang Checklist:**
   Saat dispatcher memilih armada untuk diaktifkan, kotak penanda (leading) tidak lagi menggunakan ikon checklist centang biasa, melainkan ikon/badge angka auto-increment (`1`, `2`, `3`, dst.) sesuai urutan pengetukan/pemilihan armada.
4. **Mempengaruhi Urutan Rotasi Jadwal Saat Diaktifkan:**
   Ketika tombol **"Aktifkan"** ditekan, unit-unit terpilih tersebut disusun di posisi paling depan pada urutan rotasi jadwal rute (`route.order`) sesuai urutan penandaan `[1, 2, 3...]`, disusul sisa unit aktif lainnya yang tidak dipilih.

---

## 2. Arsitektur Komponen & Solusi Teknis

### A. Parser Helper Nomor Unit (`splitUnitNumber`)
Dibuat helper murni di `lib/domain/models.dart` (atau utilitas UI pendukung):
```dart
typedef ParsedUnitNumber = ({String operator, String number});

ParsedUnitNumber splitUnitNumber(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(r'^([^\d]+)[\s\-_./]*(.*)$').firstMatch(trimmed);
  if (match != null && match.group(2)!.isNotEmpty) {
    return (
      operator: match.group(1)!.replaceAll(RegExp(r'[\s\-_./]+$'), '').toUpperCase(),
      number: match.group(2)!.trim(),
    );
  }
  return (operator: '', number: trimmed);
}
```
**Contoh Kasus Uji Parser:**
- `"KLM 540"` $\rightarrow$ `operator: "KLM"`, `number: "540"`
- `"KWK-001"` $\rightarrow$ `operator: "KWK"`, `number: "001"`
- `"TSU.102"` $\rightarrow$ `operator: "TSU"`, `number: "102"`
- `"JAK 12"` $\rightarrow$ `operator: "JAK"`, `number: "12"`
- `"1865"` $\rightarrow$ `operator: ""`, `number: "1865"`
- `"26"` $\rightarrow$ `operator: ""`, `number: "26"`

### B. Tampilan Kartu Armada (`CockpitManifestCard` di `_fleet`)
1. **Kotak Indikator Kiri (`leading`):**
   - **Belum Dipilih:** Kotak rounded berukuran 38x38 berisi ikon bus `Icons.directions_bus` (warna cyan jika aktif, amber jika nonaktif).
   - **Dipilih (Selected):** Kotak rounded neon cyan glowing berisi angka urutan seleksi:
     `final selectionIndex = selectedFleetIds.indexOf(unit.id);`
     `Text('${selectionIndex + 1}')` dengan `HedgeTokens.cyberFont`, ukuran 16sp, tebal `w900`, warna cyan.
2. **Judul Kartu (`title`):**
   - Prefix "Unit" dihapus sepenuhnya.
   - Menggunakan `Column` (crossAxis: start):
     - Jika `parsed.operator.isNotEmpty`: Baris atas menampilkan teks operator (misal `KLM`) dengan font ukuran 10.5sp, `letterSpacing: 1.0`, warna muted / secondary silver.
     - Baris bawah menampilkan `parsed.number` dengan font ukuran 18sp, `fontWeight: FontWeight.w800`, cyberFont.
     - Jika `parsed.operator.isEmpty`: Menampilkan `parsed.number` ukuran 18sp secara proporsional.
3. **Subtitle Status:**
   - Tetap menampilkan status operasional ("Aktif untuk jadwal baru" / "Tidak aktif") di bawah nomor body.

### C. State Management Seleksi & Pengurutan
1. **Struktur Data Seleksi di `_HomeState`:**
   - Mengubah `final Set<String> selectedFleetIds = <String>{};` menjadi `final List<String> selectedFleetIds = <String>[];`.
   - Ketuk kartu unit (`onTap`):
     - Jika `selectedFleetIds.contains(unit.id)`: dihapus dari list. Nomor urut armada terpilih lainnya otomatis merapat (`auto-compact 1..N`).
     - Jika belum ada: `selectedFleetIds.add(unit.id)`. Nomor urut unit tersebut adalah `selectedFleetIds.length`.
   - Tombol "Pilih Semua":
     - Jika semua unit sudah terpilih: kosongkan list `selectedFleetIds.clear()`.
     - Jika belum semua: masukkan seluruh `unit.id` yang belum ada ke `selectedFleetIds` sesuai urutan kemunculan di daftar.
2. **Penerapan Urutan saat "Aktifkan" Ditekan:**
   - Memanggil `controller.setUnitsActive(route, selectedFleetIds, true)`.
   - Di `WorkspaceController.setUnitsActive`:
     Menerima `Iterable<String> unitIds` (berupa `List<String>`).
     Ketika `active == true`:
     ```dart
     final orderedSelection = unitIds.toList();
     final remainingOrder = route.order.where((id) => !unitIds.toSet().contains(id));
     final order = [
       ...orderedSelection,
       ...remainingOrder,
     ];
     ```
     Dengan ini, unit-unit yang baru saja diaktifkan langsung berada di antrean rotasi nomor 1, 2, 3... sesuai nomor centang seleksinya.
     Ketika `active == false`:
     Unit dinonaktifkan dan dihapus dari `route.order` seperti biasa.

---

## 3. Rencana Pengujian (Quality Gates)
1. **Unit Test Parser:**
   - Pengujian `splitUnitNumber` dengan berbagai variasi input kode operator dan nomor body.
2. **Widget Test Halaman 02 Armada:**
   - Verifikasi hilangnya kata "Unit" pada title card.
   - Verifikasi rendering kode operator di atas nomor body.
   - Verifikasi penandaan auto increment `[1]`, `[2]`, `[3]` saat unit dipilih bertahap.
   - Verifikasi bahwa nomor auto increment bergeser (*compact*) jika salah satu unit dilepas centangnya.
   - Verifikasi urutan `route.order` setelah tombol "Aktifkan" ditekan memprioritaskan urutan seleksi.
3. **Verifikasi UI Light & Dark Mode:**
   - Memastikan kontras angka auto-increment dan teks operator jelas terbaca di kedua mode tema.

---

## 4. Rencana Dokumentasi
Sesuai aturan AGENTS.md, seluruh perbaikan dan hasil verifikasi akan didokumentasikan dalam `docs/refactor/revamp-halaman-02-armada/` yang memuat 4 file inti:
- `01-temuan-bug-dan-permasalahan.md`
- `02-perbaikan-dan-solusi-kode.md`
- `03-verifikasi-dan-hasil-pengujian.md`
- `04-analogi-dan-dampak-non-teknis.md`
