# Verifikasi & Hasil Pengujian: Halaman 02 Armada

## 1. Perintah Pengujian
Pengujian otomatis dijalankan menggunakan command line Flutter:
```bash
flutter test test/fleet_unit_split_and_order_test.dart test/fleet_manifest_ui_test.dart
flutter analyze
```

## 2. Cakupan & Hasil Unit Test (`test/fleet_unit_split_and_order_test.dart`)
- **splitUnitNumber Parser Tests:**
  - `[PASS]` Memisahkan kode operator spasi angka nomor body (`KLM 540` $\rightarrow$ `KLM` & `540`)
  - `[PASS]` Memisahkan kode operator strip angka nomor body (`KWK-001` $\rightarrow$ `KWK` & `001`)
  - `[PASS]` Memisahkan kode operator titik angka nomor body (`TSU.102` $\rightarrow$ `TSU` & `102`)
  - `[PASS]` Memisahkan kode operator huruf bersambung spasi angka (`JAK 12` $\rightarrow$ `JAK` & `12`)
  - `[PASS]` Unit nomor murni angka tanpa prefix operator (`1865` $\rightarrow$ `""` & `1865`)
  - `[PASS]` Unit nomor pendek angka saja (`26` $\rightarrow$ `""` & `26`)
  - `[PASS]` Handling spasi berlebih pada input unit (`   KWK   448   ` $\rightarrow$ `KWK` & `448`)
- **WorkspaceController setUnitsActive Order Tests:**
  - `[PASS]` Mengaktifkan unit-unit dengan urutan seleksi [1, 2, 3] menempatkannya di paling depan `route.order`
  - `[PASS]` Menonaktifkan unit mengeluarkannya dari `route.order`

## 3. Cakupan & Hasil Widget Test (`test/fleet_manifest_ui_test.dart`)
- `[PASS]` Verifikasi penghapusan seluruh prefix `'Unit '` dari card title list.
- `[PASS]` Verifikasi rendering split kode operator di atas nomor body.
- `[PASS]` Verifikasi penandaan auto-increment seleksi: unit pertama yang di-tap mendapat badge `1`, unit kedua mendapat badge `2`.
- `[PASS]` Verifikasi tombol "Aktifkan" memproses aktivasi armada sesuai urutan nomor auto-increment.

## 4. Hasil Analisis Statis
- `flutter analyze`: **No issues found!**
